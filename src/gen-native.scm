;;;
;;; Generate native code vector for FFI
;;;

;; Currently, the generated code should be manually copy&pasted into
;; libnative.scm.  Eventually we'll streamline the build process to automate it.

(use scheme.list)
(use gauche.uvector)
(use lang.asm.x86_64)

(define (gen-stub-amd64 port)
  ;; Support up to 6 args, integer register passing only for now.
  (receive (code labels)
      (asm '(entry6:
             (movq (arg5:) %r9)
             entry5:
             (movq (arg4:) %r8)
             entry4:
             (movq (arg3:) %rcx)
             entry3:
             (movq (arg2:) %rdx)
             entry2:
             (movq (arg1:) %rsi)
             entry1:
             (movq (arg0:) %rdi)
             entry0:
             (call (func:))
             (ret)
             (.align 8)
             func: (.dataq 0)
             arg0: (.dataq 0)
             arg1: (.dataq 0)
             arg2: (.dataq 0)
             arg3: (.dataq 0)
             arg4: (.dataq 0)
             arg5: (.dataq 0)
             (.align 8)
             end:))
    (define entry-offsets   ;; numargs -> code vector offset
      (map (cut assq-ref labels <>) 
           '(entry0: entry1: entry2: entry3: entry4: entry5: entry6:)))
    (define arg-offsets     ;; numargs -> (fill-offset ...)
      (cons
       '()
       (pair-fold (^[base-offsets entry-offsets r]
                    (cons 
                     (reverse (map (cute - <> (car entry-offsets)) base-offsets))
                     r))
                  '()
                  (map (cut assq-ref labels <>)
                       '(arg5: arg4: arg3: arg2: arg1: arg0:))
                  (reverse (cdr entry-offsets)))))
    (define func-offsets    ;; numargs -> func addr offset
      (map (cute - (assq-ref labels 'func:) <>) entry-offsets))
    
    (display ";; This part of code is generated by gen-native.scm\n" port)
    (display "\n" port)
    (display ";; label    offset\n")
    (dolist [p labels]
      (format port ";; ~10a  ~3d\n" (car p) (cdr p)))
    (pprint `(define *amd64-call-code*
               ',(list->u8vector code))
            :port port
            :controls (make-write-controls :pretty #t :width 75 
                                           :base 16 :radix #t))

    ;; (call-amd64 <dlptr> args rettype)
    ;;  args : ((type value) ...)
    ;; NB: In the final form, we won't expose this function to the user; it's
    ;; too error-prone.  You can wreck havoc just by passing a wrong type.
    ;; Instead, we'll require the user to parse the C function declaration
    ;; and we automatically extract the type info.
    (pprint 
     `(define call-amd64
        (let ((%%call-native (global-variable-ref (find-module 'gauche.bootstrap)
                              '%%call-native))
              (entry-offsets ',entry-offsets)
              (arg-offsets ',arg-offsets)
              (func-offsets ',func-offsets))
          (^[ptr args rettype]
            (let* ((nargs (length args))
                   (filler (cons
                           `(,(~ func-offsets nargs) p ,ptr)
                           (map (^[offs arg] (cons offs arg))
                                (~ arg-offsets nargs)
                                args))))
              (%%call-native *amd64-call-code* 
                             (- ,(length code) (~ entry-offsets nargs))
                             (~ entry-offsets nargs)
                             filler
                             rettype)))))
     :port port)
    ))


(define (main args)
  (gen-stub-amd64 (current-output-port)))

    
