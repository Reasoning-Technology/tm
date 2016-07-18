#|
Copyright (c) 2016 Thomas W. Lynch and Reasoning Technology Inc.
Released under the MIT License (MIT)
See LICENSE.txt


|#
(in-package #:tm)

;;--------------------------------------------------------------------------------
;; copying
;;  

  ;; more specialized than one found in nd-tm-derived.lisp
  (defmethod with-mk-entangled
    (
      (tm multi-tape-machine)
      continuation
      )
    (let(
          (tm1 (mk-entangled tm))
          )
      (unwind-protect
        (funcall continuation tm1)
        (disentangle tm1)
        )))

  ;; more specialized than one found in nd-tm-primitives.lisp
  (defmethod init-entangled ((tm1 multi-tape-machine) tm-orig)
    (setf (entanglements tm1) (entanglements tm-orig))
    (entangle tm1)
    (call-next-method tm1 tm-orig)
    )


;;--------------------------------------------------------------------------------
;; cell allocation
;;
  ;; add a new leftmost
  (defmethod a◧
    (
      (tm multi-tape-machine)
      object
      &optional
      (cont-ok  (be t))
      (cont-no-alloc (λ()(error 'alloc-fail)))
      )
    (call-next-method tm object cont-ok cont-no-alloc)
    (∀-entanglements-update-tape tm)
    )

;;--------------------------------------------------------------------------------
;; cell deallocation
;;
  (defmethod d (
                  (tm multi-tape-machine)
                  &optional 
                  spill 
                  (cont-ok #'echo)
                  (cont-rightmost (λ()(error 'dealloc-on-rightmost)))
                  (cont-no-alloc (λ()(error 'alloc-fail)))
                  &rest ⋯
                  )
    (destructuring-bind
      (
        &optional
        (cont-collision (λ()(error 'dealloc-collision)))
        )
       ⋯
      (∃-collision-right-neighbor tm
        cont-collision
        (call-next-method tm spill cont-ok cont-rightmost cont-no-alloc)
        )))
      
  (defmethod d◧ (
                   (tm multi-tape-machine)
                   &optional 
                   spill 
                   (cont-ok #'echo)
                   (cont-collision (λ()(error 'dealloc-collision)))
                   (cont-no-alloc (λ()(error 'alloc-fail)))
                   )
    (∃-collision◧ tm
      cont-collision
      (progn
        (call-next-method tm spill cont-ok cont-collision cont-no-alloc)
        (∀-entanglements-update-tape tm)
        )))
