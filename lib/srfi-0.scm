;;;
;;; SRFI-0   feature based conditional expansion construct
;;;
;;; $Id: srfi-0.scm,v 1.20 2004-02-04 03:53:53 shirok Exp $
;;;

(define-module srfi-0
  (export cond-expand))
(select-module srfi-0)

;;; The following features are supported in all Gauche versions.
;;;
;;;   srfi-0, srfi-1, srfi-2, srfi-4, srfi-5, 
;;;   srfi-6, srfi-7, srfi-8, srfi-9, srfi-10,
;;;   srfi-11, srfi-13, srfi-14, 
;;;   srfi-16, srfi-17, srfi-18, srfi-19,
;;;   srfi-22, srfi-23, srfi-25, 
;;;   srfi-26, srfi-27, srfi-28, srfi-29, srfi-30,
;;;   srfi-31,
;;;   srfi-37, srfi-39
;;;   gauche
;;;

(define-syntax cond-expand
  (syntax-rules (and or not else gauche
                 srfi-0  srfi-1  srfi-2  srfi-3  srfi-4
                 srfi-5  srfi-6  srfi-7  srfi-8  srfi-9
                 srfi-10 srfi-11 srfi-12 srfi-13 srfi-14
                 srfi-15 srfi-16 srfi-17 srfi-18 srfi-19
                 srfi-20 srfi-21 srfi-22 srfi-23 srfi-24
                 srfi-25 srfi-26 srfi-27 srfi-28 srfi-29
                 srfi-30 srfi-31 srfi-32 srfi-33 srfi-34
                 srfi-35 srfi-36 srfi-37 srfi-38 srfi-39
                 srfi-40 srfi-41 srfi-42 srfi-43 srfi-44
                 srfi-45 srfi-46 srfi-47 srfi-48 srfi-49
                 srfi-50 srfi-51 srfi-52 srfi-53 srfi-54
                 srfi-55 srfi-56 srfi-57 srfi-58 srfi-59
                 )
    ((cond-expand) (error "Unfulfilled cond-expand"))

    ((cond-expand (else body ...))
     (begin body ...))
    ((cond-expand ((and) body ...) more-clauses ...)
     (begin body ...))
    ((cond-expand ((and req1 req2 ...) body ...) more-clauses ...)
     (cond-expand
      (req1
       (cond-expand
        ((and req2 ...) body ...)
        more-clauses ...))
      more-clauses ...))
    ((cond-expand ((or) body ...) more-clauses ...)
     (cond-expand more-clauses ...))
    ((cond-expand ((or req1 req2 ...) body ...) more-clauses ...)
     (cond-expand
      (req1
       (begin body ...))
      (else
       (cond-expand
        ((or req2 ...) body ...)
        more-clauses ...))))
    ((cond-expand ((not req) body ...) more-clauses ...)
     (cond-expand
      (req
       (cond-expand more-clauses ...))
      (else body ...)))
    ((cond-expand (gauche body ...) more-clauses ...)
     (begin body ...))
    ((cond-expand (srfi-0 body ...) more-clauses ...)
     (begin body ...))
    ((cond-expand (srfi-1 body ...) more-clauses ...)
     (begin (use srfi-1) body ...))
    ((cond-expand (srfi-2 body ...) more-clauses ...)
     (begin (use srfi-2) body ...))
    ((cond-expand (srfi-4 body ...) more-clauses ...)
     (begin (use srfi-4) body ...))
    ((cond-expand (srfi-5 body ...) more-clauses ...)
     (begin (use srfi-5) body ...))
    ((cond-expand (srfi-6 body ...) more-clauses ...)
     (begin body ...))
    ((cond-expand (srfi-7 body ...) more-clauses ...)
     (begin body ...))
    ((cond-expand (srfi-8 body ...) more-clauses ...)
     (begin body ...))
    ((cond-expand (srfi-9 body ...) more-clauses ...)
     (begin (use srfi-9) body ...))
    ((cond-expand (srfi-10 body ...) more-clauses ...)
     (begin body ...))
    ((cond-expand (srfi-11 body ...) more-clauses ...)
     (begin (use srfi-11) body ...))
    ((cond-expand (srfi-13 body ...) more-clauses ...)
     (begin (use srfi-13) body ...))
    ((cond-expand (srfi-14 body ...) more-clauses ...)
     (begin (use srfi-14) body ...))
    ((cond-expand (srfi-16 body ...) more-clauses ...)
     (begin body ...))
    ((cond-expand (srfi-17 body ...) more-clauses ...)
     (begin body ...))
    ((cond-expand (srfi-18 body ...) more-clauses ...)
     (begin (use gauche.threads) body ...))
    ((cond-expand (srfi-19 body ...) more-clauses ...)
     (begin (use srfi-19) body ...))
    ((cond-expand (srfi-22 body ...) more-clauses ...)
     (begin body ...))
    ((cond-expand (srfi-23 body ...) more-clauses ...)
     (begin body ...))
    ((cond-expand (srfi-25 body ...) more-clauses ...)
     (begin (use gauche.array) body ...))
    ((cond-expand (srfi-26 body ...) more-clauses ...)
     (begin body ...))
    ((cond-expand (srfi-27 body ...) more-clauses ...)
     (begin (use srfi-27) body ...))
    ((cond-expand (srfi-28 body ...) more-clauses ...)
     (begin body ...))
    ((cond-expand (srfi-29 body ...) more-clauses ...)
     (begin (use srfi-29) body ...))
    ((cond-expand (srfi-30 body ...) more-clauses ...)
     (begin body ...))
    ((cond-expand (srfi-31 body ...) more-clauses ...)
     (begin body ...))
    ((cond-expand (srfi-37 body ...) more-clauses ...)
     (begin (use srfi-37) body ...))
    ((cond-expand (srfi-38 body ...) more-clauses ...)
     (begin body ...))
    ((cond-expand (srfi-39 body ...) more-clauses ...)
     (begin (use gauche.parameter) body ...))
    ((cond-expand (feature-id body ...) more-clauses ...)
     (cond-expand more-clauses ...))))

(provide "srfi-0")
