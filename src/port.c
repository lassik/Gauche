/*
 * port.c - port implementation
 *
 *  Copyright(C) 2000-2001 by Shiro Kawai (shiro@acm.org)
 *
 *  Permission to use, copy, modify, distribute this software and
 *  accompanying documentation for any purpose is hereby granted,
 *  provided that existing copyright notices are retained in all
 *  copies and that this notice is included verbatim in all
 *  distributions.
 *  This software is provided as is, without express or implied
 *  warranty.  In no circumstances the author(s) shall be liable
 *  for any damages arising out of the use of this software.
 *
 *  $Id: port.c,v 1.9 2001-03-10 05:34:46 shiro Exp $
 */

#include "gauche.h"

/*
 * Common
 */

static int port_print(ScmObj obj, ScmPort *port, int mode);
SCM_DEFCLASS(Scm_PortClass, "<port>", port_print, SCM_CLASS_DEFAULT_CPL);

#define PORTINIT(port, dir_, type_)             \
    do {                                        \
        SCM_SET_CLASS(port, SCM_CLASS_PORT);    \
        port->direction = dir_;                 \
        port->type = type_;                     \
        port->bufcnt = 0;                       \
        port->ungotten = SCM_CHAR_INVALID;      \
    } while (0)

/*
 * Close
 */
ScmObj Scm_ClosePort(ScmPort *port)
{
    int result = 0;

    switch (SCM_PORT_TYPE(port)) {
    case SCM_PORT_FILE:
        result = fclose(port->src.file.fp);
        break;
    case SCM_PORT_PROC:
        if (port->src.proc.vtable->Close) {
            result = port->src.proc.vtable->Close(SCM_PORT(port));
        }
        break;
    }
    port->type = SCM_PORT_CLOSED;
    return result? SCM_FALSE : SCM_TRUE;
}

/*
 * Getting informations
 */
ScmObj Scm_PortName(ScmPort *port)
{
    ScmObj z;
    
    switch (SCM_PORT_TYPE(port)) {
    case SCM_PORT_FILE:
        if (SCM_STRINGP(port->src.file.name)) z = port->src.file.name;
        else z = SCM_MAKE_STR("(unknown file)");
        break;
    case SCM_PORT_ISTR:
        z = SCM_MAKE_STR("(input string)");
        break;
    case SCM_PORT_OSTR:
        z = SCM_MAKE_STR("(output string)");
        break;
    case SCM_PORT_CLOSED:
        z = SCM_MAKE_STR("(closed port)");
        break;
    case SCM_PORT_PROC:
        {
            ScmProcPortInfo *info = port->src.proc.vtable->Info(port);
            z = info ? info->name : SCM_MAKE_STR("(proc port)");
        }
        break;
    default:
        Scm_Panic("Scm_PortName: something screwed up");
    }
    return z;
}

int Scm_PortLine(ScmPort *port)
{
    int l;
    
    switch (SCM_PORT_TYPE(port)) {
    case SCM_PORT_FILE:
        l = port->src.file.line;
        break;
    case SCM_PORT_ISTR:;
    case SCM_PORT_OSTR:;
    case SCM_PORT_CLOSED:
        l = -1;
        break;
    case SCM_PORT_PROC:
        {
            ScmProcPortInfo *info = port->src.proc.vtable->Info(port);
            l = info ? info->line : -1;
        }
        break;
    default:
        Scm_Panic("Scm_PortLine: something screwed up");
    }
    return l;
}

int Scm_PortPosition(ScmPort *port)
{
    int pos;
    
    switch (SCM_PORT_TYPE(port)) {
    case SCM_PORT_FILE:
        pos = port->src.file.column;
        break;
    case SCM_PORT_ISTR:;
        pos = port->src.istr.current - port->src.istr.start;
    case SCM_PORT_OSTR:
        pos = SCM_DSTRING_SIZE(&port->src.ostr);
        break;
    case SCM_PORT_CLOSED:;
        pos = -1;
        break;
    case SCM_PORT_PROC:
        {
            ScmProcPortInfo *info = port->src.proc.vtable->Info(port);
            pos = info ? info->position : -1;
        }
        break;
    default:
        Scm_Panic("Scm_PortLine: something screwed up");
    }
    return pos;
}

static int port_print(ScmObj obj, ScmPort *port, int mode)
{
    return Scm_Printf(port, "#<%s%sport %A %p>",
                      (SCM_PORT_DIR(obj)&SCM_PORT_INPUT)? "i" : "",
                      (SCM_PORT_DIR(obj)&SCM_PORT_OUTPUT)? "o" : "",
                      Scm_PortName(SCM_PORT(obj)),
                      obj);
}

/* Returns port's associated file descriptor number, if any.
   Returns -1 otherwise. */
int Scm_PortFileNo(ScmPort *port)
{
    if (SCM_PORT_TYPE(port) == SCM_PORT_FILE) {
        return fileno(port->src.file.fp);
    } else if (SCM_PORT_TYPE(port) == SCM_PORT_PROC) {
        ScmProcPortInfo *info = port->src.proc.vtable->Info(port);
        if (info) {
            if (info->fd >= 0) return info->fd;
            if (info->fp) return fileno(info->fp);
        }
        return -1;
    } else {
        return -1;
    }
}

/*
 * File Port
 */

ScmObj Scm_MakeFilePort(FILE *fp, ScmObj name, const char *mode)
{
    int dir;
    ScmPort *p;

    if (*mode == 'r') dir = SCM_PORT_INPUT;
    else              dir = SCM_PORT_OUTPUT;

    p = SCM_NEW(ScmPort);
    PORTINIT(p, dir, SCM_PORT_FILE);
    p->src.file.fp = fp;
    p->src.file.line = 1;
    p->src.file.column = 1;
    p->src.file.name = name;
    return SCM_OBJ(p);
}

ScmObj Scm_OpenFilePort(const char *path, const char *mode)
{
    int dir;
    FILE *fp;
    
    fp = fopen(path, mode);
    if (fp == NULL) return SCM_FALSE;

    return Scm_MakeFilePort(fp, Scm_MakeString(path, -1, -1), mode);
}

/* Auxiliary function for macros */

/* Called from SCM_FILE_GETC, when it finds the char is multibyte. 
   Assuming ungotten and incomplete buffer is empty.
   If EOF is found in the middle of the character, keep the read bytes
   in the incomplete buffer and return EOF. */

int Scm__PortFileGetc(int prefetch, ScmPort *port)
{
    unsigned char b;
    char *p;
    int next, nfollows, i, ch;

    port->bufcnt = 0;
    port->buf[0] = prefetch;
    nfollows = SCM_CHAR_NFOLLOWS(prefetch);
    for (i=1; i<= nfollows; i++) {
        next = getc(port->src.file.fp);
        if (next == EOF) return EOF;
        if (next == '\n') port->src.file.line++;
        port->buf[i] = next;
        port->bufcnt++;
    }
    p = port->buf;
    SCM_STR_GETC(p, ch);
    port->bufcnt = 0;
    return ch;
}

/* Called from SCM_GETB, when there's an ungotten char or buffered
   incomplete char. */
int Scm__PortGetbInternal(ScmPort *port)
{
    int ch;
    
    if ((ch = port->ungotten) != SCM_CHAR_INVALID) {
        char *p = port->buf;
        port->bufcnt = SCM_CHAR_NBYTES(ch);
        SCM_STR_PUTC(p, ch);
        port->ungotten = SCM_CHAR_INVALID;
    }
    if (!port->bufcnt) {
        /* This shouldn't happen, but just in case ... */
        SCM_GETB(ch, port);
    } else {
        int i;
        ch = port->buf[0];
        for (i=1; i<port->bufcnt; i++) {
            port->buf[i-1] = port->buf[i];
        }
        port->bufcnt--;
    }
    return ch;
}

/* Called from SCM_GETC, when there's a buffered incomplete char. */
int Scm__PortGetcInternal(ScmPort *port)
{
    int ch, i, nfollows;
    char *p;
    
    if (!port->bufcnt) {
        /* this shouldn't happen, but just in case ... */
        SCM_GETC(ch, port);
    } else {
        /* fill the buffer */
        nfollows = SCM_CHAR_NFOLLOWS(port->buf[0]);
        for (; port->bufcnt <= nfollows; port->bufcnt++) {
            int b;
            switch (SCM_PORT_TYPE(port)) {
              case SCM_PORT_FILE: SCM__FILE_GETB(b, port); break;
              case SCM_PORT_ISTR: SCM__ISTR_GETB(b, port); break;
              case SCM_PORT_PROC: SCM__PROC_GETB(b, port); break;
              default: Scm_Panic("getc: something screwed up");
            }
            if (b == EOF) return EOF;
            port->buf[port->bufcnt] = b;
        }
        p = port->buf;
        SCM_STR_GETC(p, ch);
    }
    return ch;
}

/*
 * Input string port
 */

ScmObj Scm_MakeInputStringPort(ScmString *str)
{
    ScmPort *z = SCM_NEW(ScmPort);
    PORTINIT(z, SCM_PORT_INPUT, SCM_PORT_ISTR);
    z->src.istr.start = SCM_STRING_START(str);
    z->src.istr.rest  = SCM_STRING_SIZE(str);
    z->src.istr.current = z->src.istr.start;
    return SCM_OBJ(z);
}

/*
 * Output string port
 */

ScmObj Scm_MakeOutputStringPort(void)
{
    ScmPort *z = SCM_NEW(ScmPort);
    PORTINIT(z, SCM_PORT_OUTPUT, SCM_PORT_OSTR);
    Scm_DStringInit(&z->src.ostr);
    return SCM_OBJ(z);
}

ScmObj Scm_GetOutputString(ScmPort *port)
{
    SCM_ASSERT(SCM_PORT_TYPE(port) == SCM_PORT_OSTR);
    return Scm_DStringGet(&SCM_PORT(port)->src.ostr);
}

/*
 * Generic procedures
 */

void Scm_Putb(ScmByte b, ScmPort *port)
{
    SCM_PUTB(b, port);
}

void Scm_Putc(ScmChar c, ScmPort *port)
{
    SCM_PUTC(c, port);
}

void Scm_Puts(ScmString *s, ScmPort *port)
{
    SCM_PUTS(s, port);
}

void Scm_PutCStr(const char *s, ScmPort *port)
{
    SCM_PUTCSTR(s, port);
}

void Scm_Putnl(ScmPort *port)
{
    SCM_PUTNL(port);
}

void Scm_Flush(ScmPort *port)
{
    SCM_FLUSH(port);
}

void Scm_Ungetc(ScmChar ch, ScmPort *port)
{
    SCM_UNGETC(ch, port);
}

int Scm_Getb(ScmPort *port)
{
    int b;
    SCM_GETB(b, port);
    return b;
}

int Scm_Getc(ScmPort *port)
{
    int c;
    SCM_GETC(c, port);
    return c;
}

/*
 * Procedural port protocol
 */

/* default dummy procedures */
static int null_getb(ScmPort *dummy)
    /*ARGSUSED*/
{
    return EOF;
}

static int null_getc(ScmPort *dummy)
    /*ARGSUSED*/
{
    return EOF;
}

static ScmObj null_getline(ScmPort *port)
{
    ScmPortVTable *vt = port->src.proc.vtable;
    int ch = vt->Getc(port);
    ScmDString ds;

    if (ch == SCM_CHAR_INVALID) return SCM_EOF;

    Scm_DStringInit(&ds);
    for (;;) {
        SCM_DSTRING_PUTC(&ds, ch);
        ch = vt->Getc(port);
        if (ch == '\n' || ch == SCM_CHAR_INVALID)
            return Scm_DStringGet(&ds);
    }
    /*NOTREACHED*/
}

static int null_ready(ScmPort *dummy)
    /*ARGSUSED*/
{
    return TRUE;
}

static int null_putb(ScmPort *dummy, ScmByte b)
    /*ARGSUSED*/
{
    return 0;
}

static int null_putc(ScmPort *dummy, ScmChar c)
    /*ARGSUSED*/
{
    return 0;
}

static int null_putcstr(ScmPort *dummy, const char *str)
    /*ARGSUSED*/
{
    return 0;
}

static int null_puts(ScmPort *dummy, ScmString *str)
    /*ARGSUSED*/
{
    return 0;
}

static int null_close(ScmPort *dummy)
    /*ARGSUSED*/
{
    return 0;
}

static ScmProcPortInfo *null_info(ScmPort *dummy)
    /*ARGSUSED*/
{
    return NULL;
}

ScmObj Scm_MakeVirtualPort(int direction, ScmPortVTable *vtable, void *data)
{
    ScmPortVTable *vt;
    ScmPort *port;
    
    /* Copy vtable, and ensure all entries contain some ptr */
    *vt = *vtable;
    if (!vt->Getb) vt->Getb = null_getb;
    if (!vt->Getc) vt->Getc = null_getc;
    if (!vt->Getline) vt->Getline = null_getline;
    if (!vt->Ready) vt->Ready = null_ready;
    if (!vt->Putb) vt->Putb = null_putb;
    if (!vt->Putc) vt->Putc = null_putc;
    if (!vt->Putcstr) vt->Putcstr = null_putcstr;
    if (!vt->Puts) vt->Puts = null_puts;
    if (!vt->Close) vt->Close = null_close;
    if (!vt->Info) vt->Info = null_info;

    PORTINIT(port, direction, SCM_PORT_PROC);
    port->src.proc.vtable = vt;
    port->src.proc.clientData = data;
    return SCM_OBJ(port);
}

/*
 * predefined ports and initialization
 */

static ScmObj scm_stdin;
static ScmObj scm_stdout;
static ScmObj scm_stderr;

ScmObj Scm_Stdin(void)
{
    return scm_stdin;
}

ScmObj Scm_Stdout(void)
{
    return scm_stdout;
}

ScmObj Scm_Stderr(void)
{
    return scm_stderr;
}

void Scm__InitPort(void)
{
    scm_stdin  = Scm_MakeFilePort(stdin, SCM_MAKE_STR("(stdin)"), "r");
    scm_stdout = Scm_MakeFilePort(stdout, SCM_MAKE_STR("(stdout)"), "w");
    scm_stderr = Scm_MakeFilePort(stderr, SCM_MAKE_STR("(stderr)"), "w");
}
