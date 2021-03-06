;;;
;;; C Parser
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

(define-module lang.c.parser
  (use util.match)
  (use parser.peg)
  (use gauche.process)
  (use gauche.config)
  (use gauche.lazy)
  (use lang.c.lexer)
  (export-all)                          ;for now
  )
(select-module lang.c.parser)

;;;
;;; Parser
;;;

;; Token recognition
(define %identifier ($match1 ('ident _)))
(define %constant   ($match1 ('const . _)))
(define %string-literal ($match1 ((or 'string 'wstring) . _)))
(define ($punct x)  ($satisfy (cut eq? x <>) x))

;; 6.5.1 Primary expressions

(define %primary-expression
  ($lazy ($or %identifier
              %constnat
              %string-literal
              ($between ($punct '|\(|) %expression ($punct '|\)|)))))

;; To be written...


;;;
;;; Preprocessor
;;;

;; NB: We may eventually implement our own preprocessor, for we can do
;; more things (such as caching), but for the time being, we call cpp.
;;
;; gcc exits with non-zero status if output isn't fully read, which happens
;; when PROC throws an error.  We don't want to lose that error, so we set
;; :on-abnormal-exit to :ignore.

(define (call-with-cpp file proc)
  (call-with-input-process `(,(gauche-config "--cc") "-E" ,file) proc
                           :on-abnormal-exit :ignore))

;;;
;;; Driver
;;;

;; For testing
(define (c-tokenize-file file)
  (call-with-cpp file
     (^p ($ lseq->list $ c-tokenize
            $ port->char-lseq/position p
            :source-name file :line-adjusters `((#\# . ,cc1-line-adjuster))))))
