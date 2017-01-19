#|
Copyright (c) 2016 Thomas W. Lynch and Reasoning Technology Inc.
Released under the MIT License (MIT)
See LICENSE.txt

|#

(in-package #:tm)

;;--------------------------------------------------------------------------------
;; cell allocation
;;
  (defun-typed a◧
    (
      (tm list-solo-tm)
      instance
      &optional
      (cont-ok (be t))
      (cont-no-alloc #'alloc-fail)
      &rest ⋯
      )
    (declare (ignore cont-no-alloc ⋯))
    (setf (tape tm) (cons instance (tape tm)))
    [cont-ok]
    )

;;--------------------------------------------------------------------------------
;; cell deallocation
;;
  (defun-typed d 
    (
      (tm list-solo-tm)
      &optional
      spill 
      (cont-ok #'echo)
      (cont-rightmost (λ()(error 'dealloc-on-rightmost)))
      (cont-no-alloc #'alloc-fail)
      (cont-collision #'cant-happen)
      &rest ⋯
      )
    (declare (ignore cont-collision ⋯))
    (if
      (cdr (head tm))
      (let*(
             (dealloc-cell (cdr (head tm)))
             (spill-instance (car dealloc-cell))
             )
        (if spill
          (as spill spill-instance
            (λ()
              (rplacd (head tm) (cdr dealloc-cell))
              [cont-ok spill-instance]
              )
            cont-no-alloc
            )
          (progn
            (rplacd (head tm) (cdr dealloc-cell))
            [cont-ok spill-instance]
            )))

      [cont-rightmost]
      ))

  ;; We depend on the fact that the head must be on some cell.
  ;; It follows that if there is only one cell, it is leftmost, and the head is on it.
  ;; As we refuse to delete the cell with the head on it, the last cell can not be deleted.
  ;; Consequently we can never have a cont-rightmost.
  (defun-typed d◧
    (
      (tm list-solo-tm)
      &optional
      spill 
      (cont-ok #'echo)
      (cont-no-alloc #'alloc-fail)
      (cont-collision (λ()(error 'dealloc-collision)))
      &rest ⋯
      )
    (declare (ignore ⋯))
    (if
      (eq (head tm) (tape tm))
      [cont-collision]
      (let*(
             (dealloc-cell (tape tm))
             (spill-instance (car dealloc-cell))
             )
        (when spill
          (as spill spill-instance
            (λ()
              (setf (tape tm) (cdr dealloc-cell))
              [cont-ok spill-instance]
              )
            cont-no-alloc
            )))))
