#|
Copyright (c) 2016 Thomas W. Lynch and Reasoning Technology Inc.
Released under the MIT License (MIT)
See LICENSE.txt

These functions derive the remainder of the tape-machine interface while using only the
primitives from tm-primitives.  

There is no functional need for a new tape machine implementation to specialize these
functions.  Still, some implementations will want to specialize these functions for
performance reasons.

Because these are built upon the primitives, they can only be tested against implementations
of the primitives.


|#

(in-package #:tm)


;;--------------------------------------------------------------------------------
;; tape-machine duplication
;;
;;   a dangerous operation to combine with deallocation. If one machine deletes
;;   a cell that another machine's head is on, things probably go haywire afterward.
;;   adding listeners and checks is one of the todo items, but those will come
;;   at a higher price if we do them.
;;
;;   originally I thought cue-to could be generic, but we cue-to a machine with
;;   more slots than head and tape, and expect to go back again, hence we have to
;;   with within the those slots and this cue-to to not have an entropy problem.
;;
  (defun cue-to
    (
      tm-cued ; original contents get clobbered
      tm-orig ; remains undisturbed
      )
    "Unless tm-cued type is (typep (type-of tm-orig)), tm-cued is changed to the type of
     tm-orig.  tm-cued is either already on the same tape as tm-orig, or it mounts it.
     tm-cued is cued to the same cell that tm-orig's head is on.  Returns tm-cued.
     "
    (unless (typep tm-cued (type-of tm-orig)) (change-class tm-cued (type-of tm-orig)))
    (setf (tape tm-cued) (tape tm-orig))
    (setf (HA tm-cued) (HA tm-orig))
    tm-cued
    )

  (defun dup (tm-orig)
    "Returns a tm with head on the same cell."
    (let(
          (tm-dup (make-instance (type-of tm-orig)))
          )
      (setf (tape tm-dup) (tape tm-orig))
      (setf (HA tm-dup) (HA tm-orig))
      tm-dup
      ))

  ;; Mounts the same tape that another machine has mounted.
  ;; Unlike dup, upon exit the head is at leftmost.
  (defmethod mount ((tm tape-machine) &optional (cont-ok #'echo) cont-fail)
    (declare (ignore cont-fail))
    (let(
          (tm-dup (dup tm))
          )
      (cue-leftmost tm-dup)
      (funcall cont-ok tm-dup)
      ))


;;--------------------------------------------------------------------------------
;; accessing data
;;

  (defgeneric wsn (tm object &optional index cont-ok cont-rightmost)
    (:documentation "Writes object into the cell under the tape head, and steps tm.")
    )

  (defmethod wsn
    (
      (tm tape-machine)
      object
      &optional 
      (index 1)
      (cont-ok (be t)) 
      (cont-rightmost (be ∅))
      )
    (w tm object)
    (sn tm index cont-ok cont-rightmost)
    )

  (defgeneric r-index (tm index &optional cont-ok cont-index-beyond-rightmost)
    (:documentation 
      "Read as though tm stepped index number of times before the read.
       index defaults to 1."
      ))

  ;; cont-rightmost throws an error, because anything we might return could alias 
  ;; against echo.  Chances are when using this method one will want to define
  ;; the continatuations. More specific versions might perform better.
  (defmethod r-index
    (
      (tm tape-machine)
      index
      &optional 
      (cont-ok #'echo) 
      (cont-index-beyond-rightmost
        (λ() (error 'tm-read-beyond-rightmost :text "attempt to read beyond the rightmost allocated cell of the tape") ∅)
        )
      )
    (let(
          (tm1 (dup tm))
          )
      (sn tm1 index
        (λ()(funcall cont-ok (r tm1)))
        (λ(n)(funcall cont-index-beyond-rightmost n))
        )))

  (defgeneric w-index (tm object index &optional cont-ok cont-index-beyond-rightmost))

  (defmethod w-index
    (
      (tm tape-machine)
      object
      index
      &optional 
      (cont-ok (be t)) 
      (cont-index-beyond-rightmost (be ∅))
      )
    (let(
          (tm1 (dup tm))
          )
      (sn tm index
        (λ() (w tm1 object) (funcall cont-ok))
        (λ() (funcall cont-index-beyond-rightmost))
        )))

;;--------------------------------------------------------------------------------
;; cueing
;;  
  (defgeneric cue-rightmost (tm)
    (:documentation "Cue tm's head to the rightmost cell.")
    )

  ;; primary does not depend on quantifiers, so I build the loop
  (defmethod cue-rightmost ((tm tape-machine))
    (labels(
             (work() (s tm #'work (be t)))
             )
      (work)
      ))


;;--------------------------------------------------------------------------------
;; These are primitives for the generic implementation of location.  They must have
;; specializations.
;;  
  (defgeneric on-leftmost (tm &optional cont-true cont-false)
    (:documentation
      "tm head is on the leftmost cell."
      ))

  (defmethod on-leftmost
    (
      tm 
      &optional 
      (cont-true (be t))
      (cont-false (be ∅))
      )
    (let(
          (tm1 (dup tm))
          )
      (cue-leftmost tm1)
      (heads-on-same-cell tm1 tm cont-true cont-false)
      ))

  (defgeneric on-rightmost (tm &optional cont-true cont-false)
    (:documentation
      "tm head is on the rightmost cell."
      ))

  (defmethod on-rightmost
    (
      tm 
      &optional 
      (cont-true (be t))
      (cont-false (be ∅))
      )
    (let(
          (tm1 (dup tm))
          )
      (s tm1 cont-false cont-true)
      ))

;;--------------------------------------------------------------------------------
;; stepping a single tape machine
;;
;;
  (defgeneric s≠ (tm0 tm1 &optional cont-ok cont-rightmost cont-bound)
    (:documentation "step tm0 unless it is equal to tm1")
    )

  (defmethod s≠ 
    (
      (tm0 tape-machine) 
      (tm1 tape-machine)
      &optional
      (cont-ok (be t))
      (cont-rightmost (be ∅))
      (cont-bound (be ∅))
      )
    (cond
      ((heads-on-same-cell tm0 tm1) (funcall cont-bound))
      (t
        (s tm0 cont-ok cont-rightmost)
      )))

;;--------------------------------------------------------------------------------
;; cell allocation
;;
;; Allocated cells must be initialized.  The initialization value is provided
;; by a three way fill function.  The three being skip, object, tm-fill.  
;;

  (defgeneric a◧ (tm object &optional cont-ok cont-no-alloc)
    (:documentation
      "Allocates a new leftmost cell."
      ))

  (defmethod a◧
    (
      (tm tape-machine)
      object
      &optional
      (cont-ok (be t))
      (cont-no-alloc (λ()(error 'tm-alloc-fail)))
      )
    (let(
          (tm1 (dup tm))
          )
      (cue-leftmost tm1)
      (a tm1 (r tm1)
        (λ() (w tm1 object)(funcall cont-ok))
        cont-no-alloc
        )
      ))

  (defgeneric as (tm object &optional cont-ok cont-no-alloc)
    (:documentation 
      "Like #'a, but tm is stepped to the new cell"
      ))

  (defmethod as
    (
      (tm tape-machine)
      object
      &optional
      (cont-ok (be t))
      (cont-no-alloc (λ()(error 'tm-alloc-fail)))
      )
    (a tm object 
      (λ()(s tm cont-ok #'cant-happen))
      cont-no-alloc
      ))

  (defgeneric a&h◨ (tm object &optional cont-ok cont-no-alloc)
    (:documentation 
      "#'a with a contract that the head is on rightmost.
       Some implementatons will be able to specialize this and make it more efficient.
      "))

  (defmethod a&h◨
    (
      (tm tape-machine)
      object
      &optional
      (cont-ok (be t))
      (cont-no-alloc (λ()(error 'tm-alloc-fail)))
      )
    (a tm object (λ()(s tm)(funcall cont-ok)) cont-no-alloc)
    )

  (defgeneric a&h◨s (tm object &optional cont-ok cont-no-alloc)
    (:documentation 
      "#'as with a contract that the head is on rightmost.
       Some implementatons will be able to specialize this and make it more efficient.
      "))

  (defmethod a&h◨s
    (
      (tm tape-machine)
      object
      &optional
      (cont-ok (be t))
      (cont-no-alloc (λ()(error 'tm-alloc-fail)))
      )
    (as tm object cont-ok cont-no-alloc)
    )

  (defgeneric a◨ (tm object &optional cont-ok cont-no-alloc)
    (:documentation
      "Allocates a cell to the right of rightmost (thus making a new rightmost)."
      ))

  (defmethod a◧
    (
      (tm tape-machine)
      object
      &optional
      (cont-ok (be t))
      (cont-no-alloc (λ()(error 'tm-alloc-fail)))
      )
    (let(
          (tm1 (dup tm))
          )
      (cue-rightmost tm1)
      (a tm1 object cont-ok cont-no-alloc)
      ))

  (defgeneric a◨s (tm object &optional cont-ok cont-no-alloc)
    (:documentation
      "Allocates a cell to the right of rightmost, and steps to it"
      ))

  (defmethod a◨s
    (
      (tm tape-machine)
      object
      &optional
      (cont-ok (be t))
      (cont-no-alloc (λ()(error 'tm-alloc-fail)))
      )
    (a◨ tm object
      (λ() (s tm cont-ok #'cant-happen))
      cont-no-alloc
      ))

  (defgeneric -a (tm object &optional cont-ok cont-no-alloc)
    (:documentation 
      "Allocate a new cell to the left of the head."
      ))

  (defmethod -a (tm object &optional cont-ok cont-no-alloc)
    (a tm (r tm) 
      (λ()
        (w tm object)
        (s tm
          cont-ok
          (λ()(error 'tm-impossible-to-get-here :text "we just called #'a"))
          ))
      cont-no-alloc
      ))

  (defgeneric -a-s (tm object &optional cont-ok cont-no-alloc)
    (:documentation 
      "Allocate a new cell to the left of the head.  Then step left."
      ))

  (defmethod -a-s (tm object &optional cont-ok cont-no-alloc)
    (a tm (r tm) 
      (λ() 
        (w tm object)
        (funcall cont-ok)
        )
      cont-no-alloc
      ))

;;--------------------------------------------------------------------------------
;;
;;
  (defgeneric d◧ (tm &optional spill cont-ok cont-rightmost cont-no-alloc)
    (:documentation 
      "Similar to #'d but the leftmost cell is deallocated independent of where the head
       is located. The tape machine could become empty, but if not, and the tape head is on
       the leftmost cell, the head is moved to the new leftmost cell.
       "
      ))

  ;; after an object is collapsed to empty, allocating a new cell to the empty will
  ;; recreate an object of the same type that collapsed.  (init) is used for this,
  ;; and only one option is given, that of :mount.
  ;;
  ;; If the object doesn't collapse, then it must have started with at least two 
  ;; cells, so the swap trick can work to deallocate the right neighbor of leftmost
  ;; using #'d (after the object in the right neighbor is moved to leftmost)
  ;;
  ;; If more options are needed, or if the swap trick doesn't work on the given 
  ;; tape type, then the programmer must provide a specialization for d◧
  ;;
    (defmethod d◧
      (
        (tm tape-machine)
        &optional 
        spill
        (cont-ok #'echo)
        (cont-no-dealloc (λ()(error 'dealloc-fail)))
        (cont-no-alloc (λ()(error 'alloc-fail)))
        )
      (let(
            (tm-type (type-of tm))
            (dealloc-object (r tm-leftmost))
            )

        (if (singleton tm)

          ;; collapse to empty
          (progn
            (when spill
              (as spill dealloc-object 
                #'do-nothing 
                (λ()(return-from d◧ (funcall cont-no-alloc)))
                ))
            (change-class tm 'tm-void)
            (init tm {:tm-type tm-type}
              (λ() (funcall cont-ok dealloc-object))
              #'cant-happen
              ))

          ;;normal dealloc, not singleton, so has at least two cells
          ;; swap objects, delete second cell
          (progn
            (let(
                  (tm◧ (dup tm))
                  )
              (cue-leftmost tm◧)
              (w tm◧ (r-index tm◧ 1 #'do-nothing #'cant-happen))
              (d tm◧ spill cont-ok cont-no-dealloc cont-no-alloc)
            ))
          )))

;;--------------------------------------------------------------------------------
;; moving data
;;

  ;; In repeated move operations we probably throw the displaced objects away if the
  ;; programmer wants to keep them zhe should copy them first, complications with
  ;; implementing this more efficiently on lists due to head cell locations with shared
  ;; tapes. In any case with repeated ops we can hop n places instead of shuffling.
  ;;
    (defgeneric m (tm fill)
      (:documentation
        "The object in rightmost is returned.
         All other objects on the tape move right one cell.
         Leftmost is written with the provided fill-object. 
         "
        ))

    (defmethod m 
      (
        (tm tape-machine)
        fill-object
        )
      (⟳ (λ(cont-loop cont-return)
           (let((displaced-object (r tm)))
             (w tm fill-object)
             (setf fill-object displaced-object)
             (s tm cont-loop cont-return)
             )))
      fill-object
      )

