#|
Copyright (c) 2016 Thomas W. Lynch and Reasoning Technology Inc.
Released under the MIT License (MIT)
See LICENSE.txt

  Tape is implemented with a singly linked list.

  When a machine is first created it will be of type empty projective, Upon 
  the allocation of a new cell, it then becomes a tm-list.

  Deallocation, #'d◧  of the last cell will cause tm-list to collapse back
  into projective machine.

|#

(in-package #:tm)

;;--------------------------------------------------------------------------------
;; accessing data
;;
  (defmethod r ((tm tm-list)) (car (HA tm)))
  (defmethod w ((tm tm-list) object) (setf (car (HA tm)) object) t)

;;--------------------------------------------------------------------------------
;; absolute head placement
;;
  ;; our tape is never nil, so this returns true
  (defmethod cue-leftmost  ((tm tm-list)) 
    (setf (parameters tm) (car (tape tm))) ; prevents gc of object
    (setf (HA tm) (tape tm))
    tm
    )
  
;;--------------------------------------------------------------------------------
;;  head location predicates
;;

  ;; if both heads are on the same cell, then step has already locked object from being
  ;; gc'd so the true result of the compare will be stable.  If the heads are on different
  ;; cells, then those cell objects have also been locked in by the copy to parameters in
  ;; the step function, so again the compare result will be stable.
  (defmethod heads-on-same-cell 
    (
      (tm0 tm-list) 
      (tm1 tm-list) 
      &optional
      (cont-true (be t))
      (cont-false (be ∅))
      ) 
    (if
      ;; compares pointers, can't compare objects
      ;; our boundary value calculus causes this test to be complete (without end cases)
      (eq (cdr (HA tm0)) (cdr (HA tm1))) 
      (funcall cont-true)
      (funcall cont-false)
      ))

;;--------------------------------------------------------------------------------
;; head stepping
;;
  (defmethod s
    (
      (tm tm-list)
      &optional
      (cont-ok (be t))
      (cont-rightmost (be ∅))
      )
    (if 
      (cdr (HA tm))
      (progn
        (setf (parameters tm) (cadr (HA tm))) ; prevents gc of object
        (setf (HA tm) (cdr (HA tm)))
        (funcall cont-ok)
        )
      (funcall cont-rightmost)
      ))

  (defmethod park ((tm tm-wk-list))
    (setf (HA tm) (type-of tm))
    (change-class tm 'tm-parked)
    ;; tape remains unchanged
    (setf (parameters tm) ∅)
    ;; entanglements remains unchanged
    )

;;--------------------------------------------------------------------------------
;; cell allocation
;;
  ;; Allocates a cell to the right of the head.
  (defmethod a 
    (
      (tm tm-list)
      object 
      &optional 
      (cont-ok (be t))
      (cont-no-alloc (λ()(error 'alloc-fail)))
      )
    (declare (ignore cont-no-alloc)) ;; should do something with this ..
    (let*(
           (connection-point (cdr (HA tm)))
           (new-cell (cons object connection-point))
           )
      (rplacd (HA tm) new-cell)
      (funcall cont-ok)
      ))

  (defmethod aw
    (
      (tm tm-list)
      object 
      &optional 
      (cont-ok (be t))
      (cont-no-alloc (λ()(error 'alloc-fail)))
      )
    )    
  
          

          
  (defmethod a◧
    (
      (tm tm-list)
      object 
      &optional 
      (cont-ok (be t))
      (cont-no-alloc (λ()(error 'alloc-fail)))
      )
    (declare (ignore cont-no-alloc)) ;; should do something with this ..
    (setf (tape tm) (cons object (tape tm)))
    (funcall cont-ok)
    )

;;--------------------------------------------------------------------------------
;; deallocating cells
;;
  ;; we know there are no entanglements (or the garbage collector would not have
  ;; 
  (defun d-weak (region-address-cell c0)
      



  ;; deallocates the cell just to the right of the head
  (defmethod d 
    (
      (tm tm-list)
      &optional 
      spill
      (cont-ok #'echo)
      (cont-rightmost (λ()(error 'dealloc-on-rightmost)))
      (cont-not-supported (λ()(error 'not-supported)))
      (cont-collision (λ()(error 'dealloc-entangled)))
      (cont-no-alloc (λ()(error 'alloc-fail)))
      )
    (declare (ignore cont-not-supported))
    (tm-list-on-rightmost tm
      cont-rightmost
      (λ()
          ;; as we elimated the rightost case, dealloc-cell must exist
          (let*(
                 (dealloc-cell (cdr (HA tm)))
                 (dealloc-object (car dealloc-cell))
                 (connection-point (cdr dealloc-cell))
                 )
            (∃-collision-s tm
              cont-collision
              (λ()
                (when spill
                  (as spill dealloc-object 
                    #'do-nothing 
                    (λ()(return-from d (funcall cont-no-alloc)))
                    ))
                (rplacd (HA tm) connection-point)
                (funcall cont-ok dealloc-object)
                )
              )))
      ))
     
  ;; deallocates the leftmost cell
  (defmethod d◧
    (
      (tm tm-list)
      &optional 
      spill
      (cont-ok #'echo)
      (cont-rightmost (λ()(error 'dealloc-on-rightmost)))
      (cont-not-supported (λ()(error 'not-supported)))
      (cont-collision (λ()(error 'dealloc-entangled)))
      (cont-no-alloc (λ()(error 'alloc-fail)))
      )
    (declare (ignore cont-rightmost cont-not-supported))
    (∃-collision◧ tm
      cont-collision
      (λ() ; if there is no collision on the cell, it can't be rightmost
        (let(
              (dealloc-object (car (tape tm)))
              )
          (when spill
            (as spill dealloc-object 
              #'do-nothing 
              (λ()(return-from d◧ (funcall cont-no-alloc)))
              ))
          (setf (tape tm) (cdr (tape tm)))
          (funcall cont-ok dealloc-object)
          ))
      ))
        
