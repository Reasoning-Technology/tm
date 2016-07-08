#|
Copyright (c) 2016 Thomas W. Lynch and Reasoning Technology Inc.
Released under the MIT License (MIT)
See LICENSE.txt

These functions derived from non-destructive primitives. 

There is no functional need for a new tape machine implementation to specialize these
functions.  


|#
(in-package #:tm)

;;--------------------------------------------------------------------------------
;; copying
;;  
  (defun cue-to (tm-cued tm-orig)
    "The tm-cued machine will be change-class'ed to the same type as tm-orig, share the
     same tape and parameters, but maintain an independent head. This new head will be set
     on the same cell as that of tm-orig. cue-to returns tm-cued. This facilitates
     interchangable calls with mk-cue-to.
     "
    (cue-to-0 tm-cued tm-orig (state tm-orig))
    )

  (defun mk-cue-to (tm-orig)
    "Make a new tape machine, then cue-to tm-orig.
     Returns the new machine.
     "
    (mk-cue-to-0 tm-orig (state tm-orig))
    )


;;--------------------------------------------------------------------------------
;; leftmost read and write
;;
  (defun r◧
    (
      tm
      &optional
      (cont-ok #'echo)
      (cont-void (λ()(error 'access-void)))
      )
    "read leftmost cell of the tape"
    (r◧-0 tm (state tm) cont-ok cont-void)
    )
  (defgeneric r◧-0 (tm tm-state cont-ok cont-void))
  (defmethod r◧-0  (tm (tm-state void) cont-ok cont-void)
    (declare (ignore tm cont-ok))
    (funcall cont-void)
    )
  (defmethod r◧-0  ((tm nd-tape-machine) (tm-state active) cont-ok cont-void)
    (declare (ignore cont-void))
    (let(
          (tm1 (mk-cue-to-0 tm))
          )
      (cue-leftmost tm1)
      (r tm1 cont-ok #'cant-happen) ; cue-leftmost would have unparked the head
      ))
  (defmethod r◧-0  ((tm nd-tape-machine) (tm-state parked) cont-ok cont-void)
    (r◧-0 tm active cont-ok cont-void)
    )

  (defun w◧
    (
      tm
      object
      &optional
      (cont-ok #'echo)
      (cont-void (λ()(error 'access-void)))
      )
    "read leftmost cell of the tape"
    (w◧-0 tm (state tm) object cont-ok cont-void)
    )
  (defgeneric w◧-0 (tm tm-state object cont-ok cont-void))
  (defmethod w◧-0  (tm (tm-state void) cont-ok cont-void)
    (declare (ignore tm cont-ok))
    (funcall cont-void)
    )
  (defmethod w◧-0  ((tm nd-tape-machine) (tm-state active) object cont-ok cont-void)
    (declare (ignore cont-void))
    (let(
          (tm1 (mk-cue-to-0 tm))
          )
      (cue-leftmost tm1)
      (w tm1 object cont-ok #'cant-happen) ; cue-leftmost would have unparked the head
      ))
  (defmethod w◧-0  ((tm nd-tape-machine) (tm-state parked) object cont-ok cont-void)
    (w◧-0 tm active object cont-ok cont-void)
    )

;;--------------------------------------------------------------------------------
;; location
;;  
...
  (defun on-leftmost 
    (
      tm
      &optional
      (cont-true (be t))
      (cont-false (be ∅))
      )
    "tm head is on the leftmost cell."
    (on-leftmost-0 tm (state tm) cont-true cont-false)
    )
  (defgeneric on-leftmost-0 (tm state cont-true cont-false))
  (defmethod on-leftmost-0 (tm (state void) cont-true cont-false)
    (declare (ignore tm state cont-true))
    (funcall cont-false)
    )
  (defmethod on-leftmost-0 (tm (state parked) cont-true cont-false)
    (declare (ignore tm state cont-true))
    (funcall cont-false)
    )
  (defmethod on-leftmost-0 (tm (state active) cont-true cont-false)
    (let(
          (tm1 (fork-0 tm))
          )
      (cue-leftmost tm1)
      (heads-on-same-cell tm1 tm cont-true cont-false)
      ))

  (defun on-rightmost
    (tm
      &optional
      (cont-true (be t))
      (cont-false (be ∅))
      )
    "tm head is on the rightmost cell."
    (on-rightmost-0 tm cont-true cont-false)
    )
  (defgeneric on-rightmost-0 (tm cont-true cont-false))
  (defmethod on-rightmost-0 (tm cont-true cont-false)
    (let(
          (tm1 (fork-0 tm))
          )
      (s tm1 cont-false cont-true)
      ))

