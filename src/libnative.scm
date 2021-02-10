;;;
;;; libnative.scm - Playing with native code
;;;
;;;   Copyright (c) 2021  Shiro Kawai  <shiro@acm.org>
;;;
;;;   Redistribution and use in source and binary forms, with or without
;;;   modification, are permitted provided that the following conditions
;;;   are met:
;;;
;;;   1. Redistributions of source code must retain the above copyright
;;;      notice, this list of conditions and the following disclaimer.
;;;
;;;   2. Redistributions in binary form must reproduce the above copyright
;;;      notice, this list of conditions and the following disclaimer in the
;;;      documentation and/or other materials provided with the distribution.
;;;
;;;   3. Neither the name of the authors nor the names of its contributors
;;;      may be used to endorse or promote products derived from this
;;;      software without specific prior written permission.
;;;
;;;   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;;;   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;;;   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
;;;   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
;;;   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
;;;   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
;;;   TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
;;;   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
;;;   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
;;;   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
;;;   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;;;

;; This is EXPERIMENTAL and UNDER DEVELOPMENT.

;; Nasty stuff.
;; These bindings are available only during the bootstrap process,
;; for we don't want ordinary code to call those internal routines.
;; For now, it is just a stub for more experiment.  Eventually ffi and jit
;; will use those routines.

(select-module gauche.bootstrap)

(inline-stub 
 (.include "gauche/priv/nativeP.h")
 (define-cproc %%call-native (tstart::<fixnum>
                              code::<uvector> 
                              start::<fixnum>
                              end::<fixnum>
                              entry::<fixnum>
                              patcher rettype)
   (return (Scm__VMCallNative (Scm_VM) tstart code start end entry
                              patcher rettype)))
 )

(select-module gauche.internal)

;; This part of code is generated by gen-native.scm

;; label    offset
;; func:         0
;; arg0:         8
;; arg1:        16
;; arg2:        24
;; arg3:        32
;; arg4:        40
;; arg5:        48
;; entry6:      56
;; entry5:      63
;; entry4:      70
;; entry3:      77
;; entry2:      84
;; entry1:      91
;; entry0:      98
;; end:        104
(define
 *amd64-call-code*
 '#u8(#x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0
      #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0
      #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0
      #x0 #x0 #x0 #x0 #x0 #x4c #x8b #xd #xf1 #xff #xff #xff #x4c #x8b #x5
      #xe2 #xff #xff #xff #x48 #x8b #xd #xd3 #xff #xff #xff #x48 #x8b #x15
      #xc4 #xff #xff #xff #x48 #x8b #x35 #xb5 #xff #xff #xff #x48 #x8b
      #x3d #xa6 #xff #xff #xff #xff #x25 #x98 #xff #xff #xff))
(define
 call-amd64
 (let
  ((%%call-native
    (global-variable-ref (find-module 'gauche.bootstrap) '%%call-native))
   (entry-offsets '(98 91 84 77 70 63 56))
   (arg-offsets '(8 16 24 32 40 48)))
  (^
   (ptr args rettype)
   (let*
    ((nargs (length args))
     (entry (~ entry-offsets nargs))
     (patcher
      (cons `(0 p ,ptr) (map (^ (offs arg) (cons offs arg)) arg-offsets args))))
    (%%call-native entry *amd64-call-code* entry 104 entry patcher rettype)))))
