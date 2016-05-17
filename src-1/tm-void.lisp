#|
Copyright (c) 2016 Thomas W. Lynch and Reasoning Technology Inc.
Released under the MIT License (MIT)
See LICENSE.txt

The void projective machine has the control mechanism for a tape, but any attempt to
access the tape or modify the tape has no effect and takes a continuation path.

A machine becomes void when all of the cells on the tape have been deallocated. A
cell can only be deallocated when a head is not on it.  It follows that only 
parked singleton machines can become void. tm-void machines can also be created 
directly.

To void a machine we change its type to tm-void and overwrite its tape slot with ∅.  HA is
unchanged and will continue to hold the machine type as it did for the parked machine.
parameters and entanglements are left unchanged.

Calling alloc, #'a, will cause the machine to transition to 'tm-parked.

|#

(in-package #:tm)

;;--------------------------------------------------------------------------------
;; a specialization
;;
  (defclass tm-void (tape-machine)())

  (defmethod init 
    (
      (tm tm-void)
      init-list 
      &optional
      (cont-ok (be t))
      (cont-fail (λ()(error 'bad-init-value)))
      )
    (destructuring-bind
      (&key tm-type mount &allow-other-keys) init-list
      (cond
        (mount (funcall cont-fail)) ; don't know if we should bother with this
        (tm-type
          (change-class tm tm-type) 
          (init tm (remove-key-pair init-list :tm-type) cont-ok cont-fail)
          (funcall cont-ok)
          )
        (t
          (setf (HA tm) 'tm-void)
          (setf (tape tm) ∅)
          (setf (parameters tm) ∅)
          (setf (entanglements tm) (make-entanglements tm))
          (funcall cont-ok)
          ))))

  (defmethod unmount ((tm tm-void))
    (case (HA tm)
      (tm-void ∅)
      (tm-list ∅)
      (tm-array #())
      (t (error 'can-not-unmount))
      ))


;;--------------------------------------------------------------------------------
;; primitive methods
;;
  (defmethod r ((tm tm-void))
    (declare (ignore tm))
    (error 'void-access)
    )
  (defmethod r◧
    (
      (tm tm-void)
      &optional
      (cont-ok #'echo) 
      (cont-void (λ()(error 'void-access)))
      )
    (declare (ignore cont-ok))
    (funcall cont-void)
    )

  (defmethod w ((tm tm-void) object)
    (declare (ignore tm object))
    (error 'void-access)
    )

  (defmethod cue-leftmost ((tm tm-void)) t)

  (defun heads-on-same-cell-void-0 (tm0 tm1 cont-true cont-false)
    (if
      (∧
        (typep tm0 'tm-void)
        (typep tm1 'tm-void)
        (eq (HA tm0) (HA tm1))
        )
      (funcall cont-true)
      (funcall cont-false)
      ))

  (defmethod heads-on-same-cell 
    (
      (tm0 tm-void) 
      (tm1 tape-machine) 
      &optional
      (cont-true (be t))
      (cont-false (be ∅))
      ) 
    (heads-on-same-cell-void-0 tm0 tm1 cont-true cont-false)
    )

  (defmethod heads-on-same-cell 
    (
      (tm0 tape-machine) 
      (tm1 tm-void) 
      &optional
      (cont-true (be t))
      (cont-false (be ∅))
      ) 
    (heads-on-same-cell-void-0 tm0 tm1 cont-true cont-false)
    )

  (defmethod s
    (
      (tm tm-void)
      &optional
      (cont-ok (be t))
      (cont-rightmost (be ∅))
      )
    (declare (ignore cont-ok))
    (funcall cont-rightmost)
    )

  ;; like a parked machine with an empty tape
  (defmethod a◧
    (
      (tm tm-void)
      object
      &optional
      (cont-ok (be t))
      (cont-no-alloc (λ()(error 'alloc-fail)))
      )
    (when (eq (HA tm) 'tm-void) (return-from a◧ (funcall cont-no-alloc)))
    (change-class tm 'tm-parked)
    (a◧ tm object
      (λ() ; continue success
        (let(
              (tape (tape tm))
              (es (entanglements tm))
              )
          (⟳(λ(cont-loop cont-return) ; update the entangled machine tapes
              (setf (tape (r es)) tape)
              (s es cont-loop cont-return)
              )))
        (funcall cont-ok)
        )
      (λ() ; continue fail
        (change-class tm 'tm-void) ; transactional behavior, reset to void 
        (setf (tape tm) ∅)
        (funcall cont-no-alloc)
      )))

  ;; same behavior for tm-parked
  (defmethod a
    (
      (tm tm-void)
      object
      &optional
      (cont-ok (be t))
      (cont-no-alloc (λ()(error 'alloc-fail)))
      )
    (a◧ tm object cont-ok cont-no-alloc)
    )

  ;; if we repeatedly delete cells from a tape, then eventually we will get cont-rightmost 
  ;; now, if repeatedly delete cells from a parked tape, then the same thing, cont-rightmost
  (defmethod d
    (
      (tm tm-void)
      &optional 
      spill
      (cont-ok #'echo)
      (cont-rightmost (λ()(error 'dealloc-on-rightmost)))
      (cont-not-supported (λ()(error 'not-supported)))
      (cont-collision (λ()(error 'dealloc-entangled)))
      (cont-no-alloc (λ()(error 'alloc-fail)))
      )
    (declare (ignore tm spill cont-ok cont-not-supported cont-collision cont-no-alloc))
    (funcall cont-rightmost)
    )

  ;; on a parked machine d◧ is the same as d, note the comments above
  (defmethod d◧
    (
      (tm tm-void)
      &optional 
      spill
      (cont-ok #'echo)
      (cont-rightmost (λ()(error 'dealloc-on-rightmost)))
      (cont-not-supported (λ()(error 'not-supported)))
      (cont-collision (λ()(error 'dealloc-entangled)))
      (cont-no-alloc (λ()(error 'alloc-fail)))
      )
    (declare (ignore tm spill cont-ok cont-not-supported cont-collision cont-no-alloc))
    (funcall cont-rightmost)
    )

      
