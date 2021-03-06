#|
Copyright (c) 2017 Thomas W. Lynch and Reasoning Technology Inc.
Released under the MIT License (MIT)
See LICENSE.txt

Architectural definition of Tape Machine.
I.e. the tape machine interface.

A tape machine is a specialization of a tape, one that includes a head for keeping
a reference to one of the cells on the tape.

Tape machines can have abstract implementations, i.e. be implemented through functions,
and they can also have unconventional implementations. Hence we don't include the head and
tape slots as part of the most general statement of the tape machine type.

'abandoned' is a status that a programmer can give to an tape machine instance to mark
that it as no longer being used by the program.  No operations are defined for abandoned
machines, so machines marked as such will keep this status until the garbage collector
picks them up.

|#

(in-package #:tm)

;;--------------------------------------------------------------------------------
;; type
;;
  (def-type tape-machine (cell tape)())

  (def-type tape-machine-abandoned (tape-machine)())

  (def-type tape-machine-empty-or-parked (tape-machine)())
  (def-type tape-machine-parked-or-active (tape-machine)())
  (def-type tape-machine-valid (tape-machine)())

  (def-type tape-machine-empty
    (
      tape-machine-empty-or-parked
      tape-machine-valid
      )
    ()
    )
  (def-type tape-machine-parked
    (
      tape-machine-empty-or-parked
      tape-machine-parked-or-active
      tape-machine-valid
      )
    ()
    )
  (def-type tape-machine-active
    (
      tape-machine-parked-or-active
      tape-machine-valid
      )
    ()
    )
  
  ;; to-abandoned, to-active, and to-empty function classess are defined in src-tape/interface.lisp
  (def-function-class to-parked (tm))

  (defun-typed to-abandoned ((tm tape-machine)) (change-class tm 'tape-machine-abandoned))
  (defun-typed to-active    ((tm tape-machine)) (change-class tm 'tape-machine-active))
  (defun-typed to-empty     ((tm tape-machine)) (change-class tm 'tape-machine-empty))
  (defun-typed to-parked    ((tm tape-machine)) (change-class tm 'tape-machine-parked))

;;--------------------------------------------------------------------------------
;; helpers
;;
  (defmacro def-empty-1 (f &rest args)
    `(defun-typed ,f ((tm tape-machine-empty) ,@args &optional ➜)
       (declare (ignore ,@args))
       (destructuring-bind
         (
           &key
           (➜empty #'accessed-empty)
           &allow-other-keys
           )
         ➜
         [➜empty]
         ))
    )

  (defmacro def-parked-1 (f &rest args)
    `(defun-typed ,f ((tm tape-machine-parked) ,@args &optional ➜)
       (declare (ignore ,@args))
       (destructuring-bind
         (
           &key
           (➜parked #'access-through-parked-head)
           &allow-other-keys
           )
         ➜
         [➜parked]
         ))
    )

;;--------------------------------------------------------------------------------
;; entanglement
;;
  ;; returns an entangled machine
  (def-function-class entangle (tm0 &optional ➜))

  ;; I suppose this could get an allocation error
  ;; I need to fix the continuations on this one
  (defun with-entangled (tm work &optional ➜)
    (declare (ignore ➜))
    (let(
          (etm (entangle tm))
          )
      [work etm]
      (to-abandoned etm) ; when we have entanglement accounting this will free etm0 from the listener list
      ))

  ;; predicate tells if two generic machines are entangled
  (def-function-class entangled (tm0 tm1 &optional ➜))


;;--------------------------------------------------------------------------------
;; location
;;
  (def-function-class on-bound-left (tm &optional ➜)
    (:documentation
      "tm head is on bound-left ➜t, else ➜∅
      "))
  (defun-typed on-bound-left ((tm tape-machine-empty-or-parked) &optional ➜)
    (destructuring-bind
      (&key
        (➜∅ (be ∅))
        &allow-other-keys
        )
      ➜
      [➜∅]
      ))

  (def-function-class on-bound-right (tm &optional ➜)
    (:documentation
      "tm head is on the bound-right cell ➜t, else ➜∅
      "))
  (defun-typed on-bound-right ((tm tape-machine-empty-or-parked) &optional ➜)
    (destructuring-bind
      (&key
        (➜∅ (be ∅))
        &allow-other-keys
        )
      ➜
      [➜∅]
      ))

  ;; by contract, tm0 and tm1 must be entangled
  ;;
    (def-function-class heads-on-same-cell (tm0 tm1 &optional ➜))
    (defun-typed heads-on-same-cell
      (
        (tm0 tape-machine-parked) 
        (tm1 tape-machine-parked)
        &optional ➜
        )
      (destructuring-bind
        (&key
          (➜t (be t))
          &allow-other-keys
          )
        ➜
        [➜t]
      ))
    (defun-typed heads-on-same-cell
      (
        (tm0 tape-machine-empty-or-parked) 
        (tm1 tape-machine-valid)
        &optional ➜
        )
      (destructuring-bind
        (&key
          (➜∅ (be ∅))
          &allow-other-keys
          )
        ➜
        [➜∅]
      ))
    (defun-typed heads-on-same-cell
      (
        (tm0 tape-machine-valid) 
        (tm1 tape-machine-empty-or-parked)
        &optional ➜
        )
      (destructuring-bind
        (&key
          (➜∅ (be ∅))
          &allow-other-keys
          )
        ➜
        [➜∅]
      ))

    (def-function-class tm= (tm0 tm1 &optional ➜))
    (defun-typed tm= ((tm0 tape-machine-valid) (tm1 tape-machine-valid) &optional ➜)
      (destructuring-bind
        (&key
          (➜∅ (be ∅))
          &allow-other-keys
          )
        ➜
        (entangled tm0 tm1
          {
            :➜∅ ➜∅
            :➜t (heads-on-same-cell tm0 tm1 ➜)
            })))


;;--------------------------------------------------------------------------------
;; length
;;
  (def-function-class tape-length-is-one (tm &optional ➜))
  (defun-typed tape-length-is-one ((tm tape-machine-empty) &optional ➜)
    (destructuring-bind
      (&key
        (➜∅ (be ∅))
        &allow-other-keys
        )
      ➜
      [➜∅]
      ))

  (def-function-class tape-length-is-two (tm &optional ➜))
  (defun-typed tape-length-is-two ((tm tape-machine-empty) &optional ➜)
    (destructuring-bind
      (&key
        (➜∅ (be ∅))
        &allow-other-keys
        )
      ➜
      [➜∅]
      ))

;;--------------------------------------------------------------------------------
;; accessing data relative to the cell the head is on
;;

    (def-empty-1 r)
    (def-parked-1 r)

    ;; esr is defined on the tape interface
    (defun-typed esr ((tm tape-machine-parked) &optional ➜) (◧r tm ➜))
    (defun-typed esr ((tape tape-empty) &optional ➜)
      (destructuring-bind
        (
          &key
          (➜bound-right (be ∅))
          &allow-other-keys
          )
        ➜
        [➜bound-right]
        ))
    (defun-typed esnr ((tm tape-machine-empty) &optional ➜) (◧snr tm ➜))

    ;; cell op
    (def-empty-1 w instance)
    (def-parked-1 w instance)

    (defun-typed esw ((tm tape-machine-parked) instance &optional ➜)
      (◧w tm instance ➜)
      )
    (defun-typed esw ((tape tape-empty) instance &optional ➜)
      (destructuring-bind
        (
          &key
          (➜bound-right (be ∅))
          &allow-other-keys
          )
        ➜
        [➜bound-right]
        ))
    (defun-typed esnw ((tm tape-machine-empty) instance &optional ➜) (◧snw tm instance ➜))
    

;;--------------------------------------------------------------------------------
;; head motion
;;
  (def-function-class s (tm &optional ➜)
    (:documentation
      "If the head is on a cell, and there is a right neighbor, puts the head on the
       right neighbor and ➜ok.  If there is no right neighbor, then ➜bound-right.
       "))
  (defun-typed s ((tm tape-machine-empty) &optional ➜)
    (destructuring-bind
      (
        &key
        (➜bound-right (be ∅))
        &allow-other-keys
        )
      ➜
      [➜bound-right]
      ))

  (def-function-class -s (tm &optional ➜))
  (defun-typed -s ((tm tape-machine-empty) &optional ➜)
    (destructuring-bind
      (
        &key
        (➜bound-left (be ∅))
        &allow-other-keys
        )
      ➜
      [➜bound-left]
      ))

  (def-function-class sn (tm n &optional ➜))
  (defun-typed sn ((tm tape-machine-empty) n &optional ➜)
    (destructuring-bind
      (
        &key
        (➜ok (be t))
        (➜bound-right (be ∅))
        &allow-other-keys
        )
      ➜
      (if (= 0 n)
        [➜ok]
        [➜bound-right]
        )))
  (defun-typed sn ((tm tape-machine-parked) n &optional ➜)
    (destructuring-bind
      (
        &key
        (➜ok (be t))
        (➜bound-right (be ∅))
        &allow-other-keys
        )
      ➜
      (cond
        ((< 0 n) (sn tm (- n) ➜))
        ((= 0 n) [➜ok])
        (t
          (s tm
            {
              :➜ok (λ()(sn tm (1- n) ➜))
              :➜bound-right ➜bound-right
              }))
        )))

  ;; '*' is zero or more times
  (def-function-class s* (tm &optional ➜)) ; move to bound-right
  (defun-typed s* ((tm tape-machine-empty) &optional ➜)
    (destructuring-bind
      (
        &key
        (➜ok (be t))
        &allow-other-keys
        )
      ➜
      [➜ok]
      ))
  (defun-typed s* ((tm tape-machine-parked-or-active) &optional ➜)
    (destructuring-bind
      (
        &key
        (➜ok (be t))
        &allow-other-keys
        )
      ➜
      (⟳ (λ(➜again)
           (s tm
             {
               :➜ok [➜again]
               :➜bound-right [➜ok]
               })))
      ))

  ;; step backwards zero or more times, and as many times as possible
  ;; i.e. move to bound-left
  (def-function-class -s* (tm &optional ➜)) 
  (defun-typed -s* ((tm tape-machine-empty) &optional ➜)
    (destructuring-bind
      (
        &key
        (➜ok (be t))
        &allow-other-keys
        )
      ➜
      [➜ok]
      ))
  (defun-typed -s* ((tm tape-machine-parked-or-active) &optional ➜)
    (destructuring-bind
      (
        &key
        (➜ok (be t))
        &allow-other-keys
        )
      ➜
      (⟳ (λ(➜again)
           (-s tm
             {
               :➜ok [➜again]
               :➜bound-left [➜ok]
               })))
      ))

  ;; step tm0 unless its head is on a boundary cell.
  ;;
  ;; The boundary is the cell that tm1's head is on.
  ;;   
  ;;     ➜bound-right if head is on the boundary cell
  ;;     ➜ok if tm0 is not on a boundary cell.
  ;;
  ;; By contract, tm0 and tm1 are entangled. Because they are entangled they are of the
  ;; same type (thus far in this implementation anyway). Provided that tm0 and tm1 are
  ;; valid, tm0 empty implies that tm1 is empty, because they are entangled.
  ;;
    (def-function-class s= (tm0 tm1 &optional ➜))
    (defun-typed s= 
      (
        (tm0 tape-machine-empty)
        (tm1 tape-machine-valid)
        &optional ➜
        )
      (destructuring-bind
        (
          &key
          (➜bound-right (be ∅))
          &allow-other-keys
          )
        ➜
        [➜bound-right]
        ))

    (defun-typed s= 
      (
        (tm0 tape-machine-parked)
        (tm1 tape-machine-parked)
        &optional ➜
        )
      (destructuring-bind
        (
          &key
          (➜bound-right (be ∅))
          &allow-other-keys
          )
        ➜
        [➜bound-right]
        ))

    (defun-typed s= 
      (
        (tm0 tape-machine-parked-or-active)
        (tm1 tape-machine-active)
        &optional ➜
        )
      (destructuring-bind
        (
          &key
          (➜bound-right (be ∅))
          (➜ok (be t))
          &allow-other-keys
          )
        ➜
        (heads-on-same-cell tm0 tm1
          {
            :➜t ➜bound-right
            :➜∅ (λ() (s tm0 {:➜ok ➜ok :➜bound-right ➜bound-right}))
            })
        ))

  ;; cues the head to parked
  (def-function-class p (tm &optional ➜)) 
  ;; an empty machine is already parked
  (defun-typed p ((tm tape-machine-empty-or-parked) &optional ➜)
    (destructuring-bind
      (
        &key
        (➜ok (be t))
        &allow-other-keys
        )
      ➜
      [➜ok]
      ))
  (defun-typed p ((tm tape-machine-active) &optional ➜)
    (destructuring-bind
      (
        &key
        (➜ok (be t))
        &allow-other-keys
        )
      ➜
      (to-parked tm)
      [➜ok]
      ))

;;--------------------------------------------------------------------------------
;; existence quantification
;;
;;    pred takes three arguments, a tape machine, a false continuation, and a true
;;    continuation.  false is normally 0, and true 1,  so the false clause come first.
;;
  (def-function-class ∃ (tm pred &optional ➜))

  (defun-typed ∃ ((tm tape-machine-empty) (pred function) &optional ➜)
    (destructuring-bind
      (&key
        (➜∅ (be ∅))
        &allow-other-keys
        )
      ➜
      [➜∅]
      ))
  (defun-typed ∃ ((tm tape-machine-parked) (pred function) &optional ➜)
    (s tm
      {
        :➜ok (λ()(∃ tm pred ➜))
        :➜bound-right #'cant-happen ; tm is parked
        }))
  (defun-typed ∃ ((tm tape-machine) (pred function) &optional ➜)
    (destructuring-bind
      (&key
        (➜∅ (be ∅))
        (➜t (be t))
        &allow-other-keys
        )
      ➜
      (if (∧ (functionp ➜t) (functionp ➜∅))
        (⟳(λ(again)
            [pred tm (λ()(s tm {:➜ok again :➜bound-right ➜∅})) ➜t]
            ))
        (error 'non-function-continuation)
        )
      ))


  ;; existence from bound-left, atomic
  (def-function-class -s*∃ (tm pred &optional ➜))
  (defun-typed -s*∃ ((tm tape-machine-empty) pred &optional ➜)
    (destructuring-bind
      (&key
        (➜∅ (be ∅))
        &allow-other-keys
        )
      ➜
      [➜∅]
      ))
  (defun-typed -s*∃ ((tm tape-machine-parked) (pred function) &optional ➜)
    (∃ tm pred ➜)
    )
  (defun-typed -s*∃ ((tm tape-machine-active) (pred function) &optional ➜)
    (-s* tm)
    (∃ tm pred ➜)
    )

;;--------------------------------------------------------------------------------
;; universal quantification
;;    All that does not exist is a universe. ;-)
;;
  (def-function-class ∀ (tm pred &optional ➜))
  ;; there does not exist an instance for which pred is false
  ;; pred is true for all instances
  (defun-typed ∀ ((tm tape-machine-valid) pred &optional ➜)
    (destructuring-bind
      (&key
        (➜∅ (be ∅))
        (➜t (be t))
        &allow-other-keys
        )
      ➜
    (∃ 
      tm
      (λ(tm c∅ ct)[pred tm ct c∅])
      {:➜∅ ➜t :➜t ➜∅}
      )))

  ;; These cue bound-left first, note they do not entangle, the tape machines head is moved.
  ;; These are atomic operations, and the end case choices reflect this.
  (def-function-class -s*∀ (tm pred &optional ➜))
  (defun-typed -s*∀ ((tm tape-machine-valid) (pred function) &optional ➜)
    (-s* tm)
    (∀ tm pred ➜)
    )

;;--------------------------------------------------------------------------------
;; topology modification
;;
  (def-function-class a (tm instance &optional ➜)
    (:documentation
        "If no cells are available, ➜no-alloc.  Otherwise, allocate a new cell and place it
         to the right of the cell the head is currently on.  The newly allocated cell will
         be initialized with the given instance.
         "))
  ;; #'a to an empty machine is the same as #'epa. Specialized types may depend on this
  ;; synonym being present, and thus not implement their own #'a.
  (defun-typed a ((tm tape-machine-empty-or-parked) instance &optional ➜)
    (epa tm instance ➜)
    )

  (def-function-class -a (tm instance &optional ➜)
    (:documentation
      "If no cells are available, ➜no-alloc.  Otherwise, allocate a new cell and place
       it to the left of the cell the head is currently on.  The newly allocated cell will
       be initialized with the given instance. This function is not available for
       singly linkedin lists.
       "))
  ;; interesting asymetry with #'a
  (defun-typed -a ((tm tape-machine-empty) instance &optional ➜)
    (epa tm instance ➜)
    )
  (defun-typed -a ((tm tape-machine-parked) instance &optional ➜)
    (◨a tm instance ➜)
    )

  (def-function-class as (tm instance &optional ➜)
    (:documentation
      "Like #'a, but tm is stepped to the new cell
      "))
  (defun-typed as ((tm tape-machine-valid) instance &optional ➜)
    (destructuring-bind
      (&key
        ;; ➜ok and ➜bound-right snagged by #'s as part of #'a ➜ok
        (➜no-alloc #'alloc-fail)
        &allow-other-keys
        )
      ➜
      (a tm instance
        {
          :➜ok (λ()(s tm ➜))
          :➜no-alloc ➜no-alloc
          })
      ))

  (def-function-class a&h◨ (tm instance &optional ➜)
    (:documentation
      "#'a with a contract that the head is on bound-right.
      "))
  ;; surely specializations will make better use of the contract
  (defun-typed a&h◨ 
    (
      (tm tape-machine-valid)
      instance
      &optional ➜
      )
      (a tm instance ➜)
      )

  (def-function-class as&h◨ (tm instance &optional ➜)
    (:documentation
      "#'as with a contract that the head is on bound-right.
      "))
   ;; surely specializations will make better use of the contract
  (defun-typed as&h◨
    (
      (tm tape-machine-valid)
      instance
      &optional ➜
      )
    (as tm instance ➜)
    )


  ;; accepts :spill option.  When the spill is provided ∅, then the deallocated cell is
  ;; appended to spill if practical, otherwise a the instance from the
  ;; deallocated cell placed in a new cell and appended to it. Spill is stepped 
  ;; after the append, hence its head will be on the new cell.
  ;;
  ;; d must have transactional behavior, i.e. the cell is only dealloced if all goes well,
  ;; otherwise d makes no structural changes.  E.g. d will fail if spill is not nil, and
  ;; reallocation to spill fails.
  ;;
    (def-function-class epd (tm &optional ➜)
      (:documentation
        "Deallocates bound-left.
         Returns the instance from the deallocated cell.
         If spill is not ∅, the deallocated cell is moved to spill, or a new
         cell is allocated to spill and the instance reference is moved there.
        "
        ))
    (defun-typed epd ((tm tape-machine-empty) &optional ➜)
      (destructuring-bind
        (
          &key
          (➜empty #'accessed-empty)
          &allow-other-keys
          )
        ➜
        ;; (prins (print "epd empty"))
        [➜empty]
        ))

    (def-function-class ep-d (tm &optional ➜)
      (:documentation
        "Deallocates bound-right.
         Returns the instance from the deallocated cell.
         If spill is not ∅, the deallocated cell is moved to spill, or a new
         cell is allocated to spill and the instance reference is moved there.
        "
        ))
    (defun-typed ep-d ((tm tape-machine-empty) &optional ➜)
      (destructuring-bind
        (
          &key
          (➜empty #'accessed-empty)
          &allow-other-keys
          )
        ➜
        ;; (prins (print "epd empty"))
        [➜empty]
        ))


    ;; delete the whole tape
    (def-function-class epd*(tm &optional ➜))
    (defun-typed epd* ((tm tape-machine-empty) &optional ➜)
      (destructuring-bind
        (
          &key
          (➜ok (be t))
          &allow-other-keys
          )
        ➜
        [➜ok]
        ))
    (defun-typed epd* ((tm tape-machine-valid) &optional ➜)
      (destructuring-bind
        (
          &key
          (➜ok (be t))
          &allow-other-keys
          )
        ➜
        (labels(
                 (work ()
                   (epd tm
                     {
                       :➜ok #'work
                       :➜bound-right ➜ok
                       (o ➜) ; for the spill option
                       }
                     ))
                 )
          (work)
          )))

    (def-function-class d (tm &optional ➜)
      (:documentation
        "Deallocate the right neighbor of the cell the head is on.
         I.e. deallocates a region of length 1 located to the right of the head.
         Returns the instance from the deallocated cell.
         If spill is not ∅, the deallocated cell is moved to spill, or a new
         cell is allocated to spill and the instance reference is moved there.
        "
        ))
    (defun-typed d ((tm tape-machine-empty) &optional ➜)
      (destructuring-bind
        (
          &key
          (➜empty #'accessed-empty)
          &allow-other-keys
          )
        ➜
        [➜empty]
        ))
    (defun-typed d ((tm tape-machine-parked) &optional ➜)
      (epd tm ➜)
      )

    (def-function-class -d (tm &optional ➜)
      (:documentation
        "Deallocate the left neighbor of the cell the head is on.
         I.e. deallocates a region of length 1 located to the left of the head.
         Returns the instance from the deallocated cell.
         If spill is not ∅, the deallocated cell is moved to spill, or a new
         cell is allocated to spill and the instance reference is moved there.
        "
        ))
    (defun-typed -d ((tm tape-machine-empty) &optional ➜)
      (destructuring-bind
        (
          &key
          (➜empty #'accessed-empty)
          &allow-other-keys
          )
        ➜
        [➜empty]
        ))
    (defun-typed -d ((tm tape-machine-parked) &optional ➜)
      (ep-d tm ➜)
      )

    (def-function-class d. (tm &optional ➜))
    (defun-typed d. ((tm tape-machine-empty) &optional ➜)
      (destructuring-bind
        (&key
          (➜empty (λ()(error 'accessed-empty)))
          &allow-other-keys
          )
        ➜
        [➜empty]
        ))

    ;; delete the right hand side
    (def-function-class d*(tm &optional ➜))
    (defun-typed d* ((tm tape-machine-empty) &optional ➜)
      (destructuring-bind
        (
          &key
          (➜ok (be t))
          &allow-other-keys
          )
        ➜
        [➜ok]
        ))
    (defun-typed d* ((tm tape-machine-valid) &optional ➜)
      (destructuring-bind
        (
          &key
          (➜ok (be t))
          &allow-other-keys
          )
        ➜
        (labels(
                 (work ()
                   (d tm 
                     {
                       :➜ok #'work
                       :➜bound-right ➜ok
                       (o ➜) ; for the spill option
                       }
                     ))
                 )
          (work)
          )))


  ;; this function is private. intended to be used with entanglement accounting.
  ;; after another machine in the entanglement group does an epa, we need to
  ;; update the tape reference for the other memebers of the group.
  (def-function-class update-tape-after-epa (tm tm-ref))

  ;; this function is private. intended to be used with entanglement accounting.
  ;; after another machine in the entanglement group does an epd, we need to
  ;; update the tape reference for the other memebers of the group.
  (def-function-class update-tape-after-epd (tm tm-ref))




