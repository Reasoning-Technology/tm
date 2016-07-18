#|
Copyright (c) 2016 Thomas W. Lynch and Reasoning Technology Inc.
Released under the MIT License (MIT)
See LICENSE.txt

A tape machine is defined by giving definitions to these primitives.

CLOS, like many object systems, requires that the parent type signature be duplicated by
children.  However, in cases our child types will have more continuations than defined for
the parent.  Hence we include a &rest parameter that children may take advantage of for
adding more continuations.  These should be called out in a destructuring bind immediately
after the call.

Note that '⋯' is a single character that we use as a variable name for holding the rest
parameters.

|#

(in-package #:tm)

;;--------------------------------------------------------------------------------
;; copying
;;  
  (defgeneric mk-shallow-copy
    (
      tm-orig
      &optional
      cont-ok
      cont-no-alloc
      )
    (:documentation
      "Makes a new tape machine.  Initializes the tape with a copy of the tape found in
       tm-orig.  The new tape references the same objects as the tm-orig tape.  Because it
       has its own tape, the new machine is not entangled with the tm-orig machine.
       "
      ))

  ;; will work for most machines
  (defmethod mk-shallow-copy
    (
      (tm-orig tape-machine)
      &optional
      (cont-ok #'echo)
      (cont-no-alloc (λ()(error 'alloc-fail)))
      )
    (let(
          (tm-copy (make-instance (type-of tm-orig)))
          )
      (as* tm-copy tm-orig
        (λ()(funcall cont-ok tm-copy))
        cont-no-alloc
        )))


;;--------------------------------------------------------------------------------
;; accessing data
;;
  (defgeneric r (tm &rest ⋯))
  (defgeneric esr (tm &optional cont-ok cont-rightmost &rest ⋯))

  (defgeneric w (tm object &rest ⋯))
  (defgeneric esw (tm object &optional cont-ok cont-rightmost &rest ⋯))

;;--------------------------------------------------------------------------------
;; absolute head placement
;;
  (defgeneric cue-leftmost (tm &rest ⋯))


;;--------------------------------------------------------------------------------
;; head stepping
;;
  (defgeneric s
    (
      tm
      &optional 
      cont-ok
      cont-rightmost
      )
    (:documentation
      "If the head is on a cell, and there is a right neighbor, puts the head on the
       right neighbor and cont-ok.  If there is no right neighbor, then cont-rightmost.
       "))

;;--------------------------------------------------------------------------------
;; cell allocation
;;
  (defgeneric a
    (
      tm
      object
      &optional
      cont-ok
      cont-no-alloc
      )
    (:documentation
    "If no cells are available, cont-no-alloc.  Otherwise, allocate a new cell and place
     it to the right of the cell the head is currently on.  The newly allocated cell will
     be initialized with the given object.
     "))
      
