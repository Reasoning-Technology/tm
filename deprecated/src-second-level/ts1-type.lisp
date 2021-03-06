#|
Copyright (c) 2016 Thomas W. Lynch and Reasoning Technology Inc.
Released under the MIT License (MIT)
See LICENSE.txt

  A thread safe version of the ea machine.

  The ea machine keeps an entangelements machine so as to know:
   1. which machines to make empty, or not empty
   2. which machines to update their leftmost cell pointer for epa  or epd
   3. which machines to check for a collision before deleteing a cell

  With multiple threads we must also synchronize between certain interface
  functions, so as to avoid these hazards:
   1. the machine is adding or deleting a cell, and another machine
      gets messed up in the construction work.  This could happen with head
      motion or competing structural operations.
   2. address incf/decf gets the wrong answer, because between the read and write of
      the incremented address, the address value was written.

  We discuss various approaches to avoiding hazards related to the synchronization of
  resources in doc/implementation/multiple-threads.txt. This is an implementation of the
  first algorithm discussed there.  Accordingly, any routine that causes structural changes,
  uses the entanglement machine, or cause head motion must own the deed to the 
  machine (i.e. the lock).

---

Any function that has operations that must be consistent across the type of the machine
must synchronize with functions that change the type of the machine.

Head motion functions must synchronize with structural change funcitons.  Otherwise we
might walk through the under construction work being done by a structural function.

Structural change operations must synchronize between each other.  Otherwise adjacent
structural change operations can confuse each other.  Also, the entangelments list 
must be modified in a coherent manner.

We do not need to synchronize synonyms. 

---

We need a recursive lock so that we compose simpler functions into more
complex ones.  For example this will affect generic functions.

---

ts1-active is inherited from ts1-tm and ea-active. 

We inherit from ts1-tm so that ts1-active will have the same slots as ts1-tm. Thus the
change-class calls will not have any work to do. 

We inherit from ea-active so that (typep 'active) will be true for the
call-next-method executions.  Perhaps we should have instead just inherited directly from
active instead of ea-active, but synonyms do not need locks, so perhaps there are
some ea-active synonyms defined.

If any of non-synonym calls fall through to the superclass then we are in trouble as that
would mean the function is called without a lock (expect subtle bugs!).  Wonder if there
is a qualifer for turning off the type resolution.

---

All instances will be of type ts1-empty ts1-parked or ts1-active. Type resolution will
then bring us back to the ts1-tm specified functions.  For ts1 there are no more
specific functions.

|#

(in-package #:tm)

;;--------------------------------------------------------------------------------
;;
  (def-type ts1-tape-machine (ea-tape-machine)())

  (def-type ts1-tm (ts1-tape-machine ea-tm)
    (
      (deed
        :initarg :deed
        :accessor deed
        )
      ))

  (def-type ts1-abandoned (abandoned ts1-tm)()) ;ts1-tm is inherited so that slots will not differ
  (def-type ts1-active    (ts1-tm ea-active)())
  (def-type ts1-empty     (ts1-tm ea-empty)())
  (def-type ts1-parked    (ts1-tm ea-parked)())

;;--------------------------------------------------------------------------------
;; state transition functions
;;
  (defun-typed to-abandoned ((tm ts1-tm)) (change-class tm 'ts1-abandoned))
  (defun-typed to-active    ((tm ts1-tm)) (change-class tm 'ts1-active))
  (defun-typed to-empty     ((tm ts1-tm)) (change-class tm 'ts1-empty))
  (defun-typed to-parked    ((tm ts1-tm)) (change-class tm 'ts1-parked))

;;--------------------------------------------------------------------------------
;; 
  (defun-typed init
    (
      (tm ts1-tm)
      &optional
      keyed-parms
      ➜
      )
    (destructuring-bind
      (&key
        (➜ok #'echo)
        &allow-other-keys
        )
      ➜
      (call-next-method tm keyed-parms
        {
          :➜ok (λ(tm)
                 (setf (deed tm) (bt:make-recursive-lock))
                 [➜ok tm]
                 )
          (o (remove-key-pair ➜ :➜ok))
          })))

  (defun-typed entangle ((tm-orig ts1-tm) &optional ➜)
    (bt:with-recursive-lock-held ((deed tm-orig))
      (call-next-method tm-orig
        {
          :➜ok (λ(tm)
                 (setf (deed tm) (deed tm-orig))
                 tm
                 )
          (o (remove-key-pair ➜ :➜ok))
          })))
