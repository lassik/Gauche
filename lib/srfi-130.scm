;;
;; srfi-130 - Cursor-based string library
;;

(define-module srfi-130
  (use srfi-13)
  (use gauche.stringutil)
  (export string-contains
          string-fold
          string-fold-right
          string-for-each-cursor
          string-index
          string-index-right
          string-skip
          string-skip-right

          ;; These are from SRFI-13
          reverse-list->string
          string-any
          string-concatenate
          string-concatenate-reverse
          string-count
          string-drop
          string-drop-right
          string-every
          string-join
          string-null?
          string-pad
          string-pad-right
          string-prefix-length
          string-prefix?
          string-replace
          string-reverse
          string-suffix-length
          string-suffix?
          string-tabulate
          string-take
          string-take-right
          string-trim
          string-trim-both
          string-trim-right
          string-unfold
          string-unfold-right
          string-filter

          ;; These are from gauche.stringutil
          string-split

          ;; Aliases
          string->list/cursors
          string->vector/cursors
          string-copy/cursors
          string-ref/cursor
          string-remove
          substring/cursors

          ;; Gauche supports the following functions natively, but
          ;; we re-export them so that they will be available by
          ;; importing srfi-130 into vanilla environment.
          string-cursor->index
          string-cursor-back
          string-cursor-diff
          string-cursor-end
          string-cursor-forward
          string-cursor-next
          string-cursor-prev
          string-cursor-start
          string-cursor<=?
          string-cursor<?
          string-cursor=?
          string-cursor>=?
          string-cursor>?
          string-cursor?
          string-index->cursor
          ))
(select-module srfi-130)

(define %maybe-substring (with-module gauche.internal %maybe-substring))

(define string->list/cursors string->list)
(define string->vector/cursors string->vector)
(define string-copy/cursors string-copy)
(define string-ref/cursor string-ref)
(define string-remove string-delete)
(define substring/cursors substring)

(define (string-index . args)
  (car (apply (with-module srfi-13 %string-index) args)))

(define (string-index-right . args)
  (car (apply (with-module srfi-13 %string-index-right) args)))

(define (string-skip . args)
  (car (apply (with-module srfi-13 %string-skip) args)))

(define (string-skip-right . args)
  (car (apply (with-module srfi-13 %string-skip-right) args)))

(define (string-for-each-cursor proc s :optional
                                (start (string-cursor-start s))
                                (end (string-cursor-end s)))
  (assume-type s <string>)
  (let ([end (string-index->cursor s end)])
    (let loop ([cur (string-index->cursor s start)])
      (unless (string-cursor=? cur end)
        (proc cur)
        (loop (string-cursor-next s cur))))))

(define (string-contains s1 s2 :optional (start1 0) end1 start2 end2)
  (assume-type s1 <string>)
  (assume-type s2 <string>)
  (let* ((str1 (%maybe-substring s1 start1 end1))
         (str2 (%maybe-substring s2 start2 end2))
         (res  (string-scan str1 str2 'cursor)))
    ;; This only works because substring 'str1' shares the same space
    ;; as the original string 's1', and <string-cursor> just holds a C
    ;; pointer. If any of that changes, we'll need to convert 'res'
    ;; (of 'str1') to the cursor of 's1'.
    res))