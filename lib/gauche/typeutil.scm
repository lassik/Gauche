;;;
;;; typeutil.scm - type utilities.
;;;
;;;   Copyright (c) 2020  Shiro Kawai  <shiro@acm.org>
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

;; *EXPERIMENTAL*

;; The classes useful for type validation and other type-related operations.
;; They're abstract types---they won't create an instance---but can be
;; used for of-type? to check if an object satisfies the type constraints.

(define-module gauche.typeutil
  (use util.match)
  (export define-type-operator of-type?
          <type-operator-meta> <type-inscance-meta>
          <or> <tuple>)
  )
(select-module gauche.typeutil)

;; Metaclass: <type-operator-meta>
;;   Instance classes of this metaclass are used to create an abstract types.
;;   They have object-apply method, and each intance class can be used
;;   as a procedure that takes classes and returns a class.
(define-class <type-operator-meta> (<class>)
  ())

(define-syntax define-type-operator
  (er-macro-transformer
   (^[f r c]
     (match f
       [(_ name supers slots . opts)
        (let ([meta-name (rxmatch-if (#/^<(.*)>$/ (symbol->string name))
                             [_ trimmed]
                           (string->symbol #"<~|trimmed|-meta>")
                           (string->symbol #"~|name|-meta"))]
              [supers (if (null? supers)
                        (list (r'<type-instance-meta>))
                        supers)])
          (quasirename r
            `(begin
               (define-class ,meta-name (<type-operator-meta>) ())
               (define-class ,name ,supers ,slots
                 :metaclass ,meta-name
                 ,@opts))))]))))

;; Metaclass: <type-instance-meta>
;;   An abstract type instance, which is a class but won't create instances.
;;   It can be used for of-type? method.
(define-class <type-instance-meta> (<class>)
  ())

(define-method allocate-instance ((z <type-instance-meta>) initargs)
  (error "Abstract type intance cannot instantiate a concrete object:" z))

;; Utility to create reasonable name
(define (make-compound-type-name op-name classes)
  ($ string->symbol 
     $ string-append "<"
     (x->string op-name) " "
     (string-join (map ($ symbol->string $ class-name $) classes) " ")
     ">"))

;;; Class: <or>
;;;   Creates a union type.

(define-type-operator <or> ()
  ((members :init-keyword :members)))

(define-method object-apply ((k <or-meta>) . args)
  (assume (every (cut is-a? <> <class>) args))
  (make <or> 
    :name (make-compound-type-name 'or args)
    :members args))

(define-method of-type? (obj (type <or>))
  (any (cut of-type? obj <>) (~ type'members)))

;;; Class: <tuple>
;;;   Fixed-lenght list, each element having its own type constraints.

(define-type-operator <tuple> ()
  ((elements :init-keyword :elements)))

(define-method object-apply ((k <tuple-meta>) . args)
  (assume (every (cut is-a? <> <class>) args))
  (make <tuple>
    :name (make-compound-type-name 'tuple args)
    :elements args))

(define-method of-type? (obj (type <tuple>))
  (let loop ((obj obj) (elts (~ type'elements)))
    (if (null? obj)
      (null? elts)
      (and (pair? obj)
           (pair? elts)
           (of-type? (car obj) (car elts))
           (loop (cdr obj) (cdr elts))))))

