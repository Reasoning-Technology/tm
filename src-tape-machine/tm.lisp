#|
Copyright (c) 2017 Thomas W. Lynch and Reasoning Technology Inc.
Released under the MIT License (MIT)
See LICENSE.txt

A generic implementation of a tape machine built only using only the tape interface (see
src-tape/tape.lisp). This implementation defines the behavior for tape machines.  All
optimized machines, e.g. tape-machine-cons, must provide the same functionality.

This tm is not entanglment safe, and not thread safe.

|#

(in-package #:tm)

;;--------------------------------------------------------------------------------
;; type
;;
  (def-type tm (tape-machine)
    (
      (head
        :initarg :head
        :accessor head
        )
      (tape 
        :initarg :tape
        :accessor tape
        )
      ))

  (def-type tm-abandoned (tm tape-machine-abandoned)())
  (defun-typed tm-empty-or-parked (tm)())
  (defun-typed tm-parked-or-active (tm)())
  (def-type tm-empty
    (
      tm-empty-or-parked
      tape-machine-empty
      )
    ()
    )
  (def-type tm-parked
    (
      tm-empty-or-parked 
      tm-parked-or-active
      tape-machine-parked
      )
    ()
    )
  (def-type tm-active 
    (
      tm-parked-or-active
      tape-machine-active
      )
    ()
    )

  (defun-typed to-abandoned ((tm tm)) (change-class tm 'tm-abandoned))
  (defun-typed to-active    ((tm tm)) (change-class tm 'tm-active))
  (defun-typed to-empty     ((tm tm)) (change-class tm 'tm-empty))
  (defun-typed to-parked    ((tm tm)) (change-class tm 'tm-parked))

  ;; binds to a tape
  ;; 
    (defun-typed init ((tm tm) (init tape-empty) &optional ➜)
      (destructuring-bind
        (&key
          (➜empty #'echo)
          &allow-other-keys
          )
        ➜
        (setf (tape tm) init)
        (to-empty tm)
        [➜empty tm]
        ))
    (defun-typed init ((tm tm) (init tape-active) &optional ➜)
      (destructuring-bind
        (&key
          (➜ok #'echo)
          &allow-other-keys
          )
        ➜
        (setf (tape tm) init)
        (setf (head tm) (leftmost init))
        (to-active tm)
        [➜ok tm]
        ))

;;--------------------------------------------------------------------------------
;; entanglement
;;
  ;; returns an entangled machine
  (defun-typed entangle ((tm0 tm-empty)  &optional ➜)
    (destructuring-bind
      (&key
        (➜ok #'echo)
        &allow-other-keys
        )
      ➜
      (let(
            (tm1 (make-instance 'tm))
            )
        (setf (tape tm1) (tape tm0))
        (to-empty tm1)
        [➜ok tm1]
        )))
  (defun-typed entangle ((tm0 tm-parked)  &optional ➜)
    (destructuring-bind
      (&key
        (➜ok #'echo)
        &allow-other-keys
        )
      ➜
      (let(
            (tm1 (make-instance 'tm))
            )
        (setf (tape tm1) (tape tm0))
        (to-parked tm1)
        [➜ok tm1]
        )))
  (defun-typed entangle ((tm0 tm-active)  &optional ➜)
    (destructuring-bind
      (&key
        (➜ok #'echo)
        &allow-other-keys
        )
      ➜
      (let(
            (tm1 (make-instance 'tm))
            )
        (setf (head tm1) (head tm0))
        (setf (tape tm1) (tape tm0))
        (to-active tm1)
        [➜ok tm1]
        )))

  ;; predicate tells if two generic machines are entangled
  (defun-typed entangled ((tm0 tm) (tm1 tm) &optional ➜)
    (destructuring-bind
      (&key
        (➜∅ (be ∅))
        (➜t (be t))
        &allow-other-keys
        )
      ➜
      (if
        (eq (tape tm0) (tape tm1))
        [➜t]
        [➜∅]
        )))


;;--------------------------------------------------------------------------------
;; location
;;
  (defun-typed on-leftmost ((tm tm-empty) &optional ➜)
    (destructuring-bind
      (&key
        (➜∅ (be ∅))
        &allow-other-keys
        )
      ➜
      [➜∅]
      ))
  (defun-typed on-leftmost ((tm tm-parked) &optional ➜)
    (destructuring-bind
      (&key
        (➜∅ (be ∅))
        &allow-other-keys
        )
      ➜
      [➜∅]
      ))
  (defun-typed on-leftmost ((tm tm-active) &optional ➜)
    (=cell
      (head tm)
      (leftmost (tape tm))
      ➜
      ))

  (defun-typed on-rightmost ((tm tm-empty) &optional ➜)
    (destructuring-bind
      (&key
        (➜∅ (be ∅))
        &allow-other-keys
        )
      ➜
      [➜∅]
      ))
  (defun-typed on-rightmost ((tm tm-parked) &optional ➜)
    (destructuring-bind
      (&key
        (➜∅ (be ∅))
        &allow-other-keys
        )
      ➜
      [➜∅]
      ))
  (def-typed on-rightmost ((tm tm-active) &optional ➜)
    (=cell
      (head tm)
      (rightmost (tape tm))
      ))

  (def-function-class heads-on-same-cell 
    (
      (tm0 tm-active)
      (tm1 tm-active)
      &optional
      ➜
      )
      (=<cell> (head tm0) (head tm1) ➜)
      )

;;--------------------------------------------------------------------------------
;; length
;;
  (defun-typed tape-length-is-one ((tm tm-parked-or-active) &optional ➜)
    (tape-length-is-one (tape tm) ➜)
    )

  (defun-typed tape-length-is-two ((tm tm-parked-or-active) &optional ➜)
    (tape-length-is-two (tape tm) ➜)
    )

;;--------------------------------------------------------------------------------
;; accessing data
;;
  (defun-typed r ((tm tm-active) &optional ➜)
    (destructuring-bind
      (&key
        (➜ok #'echo)
        &allow-other-keys
        )
      ➜
      [➜ok (r<cell> (head tm))]
      ))

  (defun-typed esr ((tm tm-active) &optional ➜)(esr<cell> (head tm) ➜))

  (defun-typed esnr ((tm tm-parked) n &optional ➜)
    (cond
      ((< 0 n) (e-snr tm (- n) ➜))
      ((= 0 n) (r tm ➜))
      (t
        (esnr<cell> (head tm) (1- n) ➜)
        )))
  (defun-typed esnr ((tm tm-active) n &optional ➜)
    (cond
      ((< 0 n) (e-snr tm (- n) ➜))
      ((= 0 n) (r tm ➜))
      (t
        (esnr<cell> (head tm) n ➜)
        )))

  (defun-typed ◧r ((tm tm-parked-or-active) &optional ➜) (◧r (tape tm) ➜))
  (defun-typed ◧sr ((tm tm-parked-or-active) &optional ➜)(◧sr (tape tm) ➜))

  (defun-typed ◧snr ((tm tm-parked) n &optional ➜)
    (cond
      ((< 0 n) (◧-snr tm (- n) ➜))
      ((= 0 n) (◧r tm ➜))
      (t
        (◧snr (tape tm) (1- n) ➜)
        )))
  (defun-typed ◧snr ((tm tm-active) n &optional ➜)
    (cond
      ((< 0 n) (◧-snr tm (- n) ➜))
      ((= 0 n) (◧r tm ➜))
      (t
        (◧snr (tape tm) n ➜)
        )))

  (defun-typed ◨r ((tm tm-parked-or-active) &optional ➜)  (◨r (tape tm) ➜))
  (defun-typed ◨-sr ((tm tm-parked-or-active) &optional ➜)(◨-sr (tape tm) ➜))

  (defun-typed w ((tm tm-active) instance &optional ➜)
    (destructuring-bind
      (&key
        (➜ok (be t))
        &allow-other-keys
        )
      ➜
      (w<cell> (head tm) instance)
      [➜ok]
      ))

  (defun-typed esw ((tm tm-active) instance &optional ➜)(esw<cell> (head tm) instance ➜))

  (defun-typed esnw ((tm tm-parked) n instance &optional ➜)
    (cond
      ((< 0 n) (e-snw tm (- n) instance ➜))
      ((= 0 n) (w tm instance ➜))
      (t
        (esnw<cell> (head tm) (1- n) instance ➜)
        )))
  (defun-typed esnw ((tm tm-active) n instance &optional ➜)
    (cond
      ((< 0 n) (e-snw tm (- n) instance ➜))
      ((= 0 n) (w tm instance ➜))
      (t
        (esnw<cell> (head tm) n instance ➜)
        )))

  (defun-typed ◧w ((tm tm-parked-or-active) instance &optional ➜) (◧w (tape tm) instance ➜))
  (defun-typed ◧sw ((tm tm-parked-or-active) instance &optional ➜)(◧sw (tape tm) instance ➜))

  (defun-typed ◧snw ((tm tm-parked) n instance &optional ➜)
    (cond
      ((< 0 n) (◧-snw tm (- n) ➜))
      ((= 0 n) (◧r tm ➜))
      (t
        (◧snw (tape tm) (1- n) instance ➜)
        )))
  (defun-typed ◧snw ((tm tm-active) n instance &optional ➜)
    (cond
      ((< 0 n) (◧-snw tm (- n) ➜))
      ((= 0 n) (◧r tm ➜))
      (t
        (◧snw (tape tm) n instance ➜)
        )))

  (defun-typed ◨w ((tm tm-parked-or-active) instance &optional ➜)  (◨w (tape tm) instance ➜))
  (defun-typed ◨-sw ((tm tm-parked-or-active) instance &optional ➜)(◨-sw (tape tm) instance ➜))

;;--------------------------------------------------------------------------------
;; head motion
;;
  (defun-typed s (tm &optional ➜)
    (destructuring-bind
      (
        &key
        (➜rightmost (be ∅))
        &allow-other-keys
        )
      ➜
      [➜rightmost]
      ))


  (defun-typed -s (tm &optional ➜))

  (defun-typed s* (tm &optional ➜)) ; move to rightmost

  ;; typically there is a more efficient way of doing this because we know
  ;; the leftmost cell of the tape
  (defun-typed -s* (tm &optional ➜)) ; move to leftmost

  ;; by contract, tm0 and tm1 are entangled
  ;; because they are entangled they are of the same type (thus far in this implementation)
  ;; tm0 empty <=> tm1 empty
  ;; tm0 abandoned <=> tm1 abandoned
  ;; tm0 parked, tm1 can be active, vice versa
  (defun-typed s≠ (tm0 tm1 &optional ➜))

  (defun-typed p (tm &optional ➜)) ; cue the head to parked


;;--------------------------------------------------------------------------------
;; topology modification
;;
  (defun-typed a (tm instance &optional ➜)
    (:documentation
    "If no cells are available, ➜no-alloc.  Otherwise, allocate a new cell and place
     it to the right of the cell the head is currently on.  The newly allocated cell will
     be initialized with the given instance.
     "))
  (defun-typed -a (tm instance &optional ➜)
    (:documentation
    "If no cells are available, ➜no-alloc.  Otherwise, allocate a new cell and place
     it to the left of the cell the head is currently on.  The newly allocated cell will
     be initialized with the given instance. This function is not available for
     singly linkedin lists.
     "))
  (defun-typed epa (tm instance &optional ➜)
    (:documentation
      "Allocates a cell to the left of leftmost (thus becoming the new leftmost).
      "
      ))
  (defun-typed ◨a (tm instance &optional ➜)
    (:documentation
      "Allocates a cell to the right of rightmost (thus becoming the new rightmost)."
      ))
  (defun-typed as (tm instance &optional ➜)
    (:documentation
      "Like #'a, but tm is stepped to the new cell
      "))

  (defun-typed as ((tm tm) instance &optional ➜)
    (destructuring-bind
      (
        &key
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

  (defun-typed a&h◨ (tm instance &optional ➜)
    (:documentation
      "#'a with a contract that the head is on rightmost.
      "))
  ;; surely specializations will make better use of the contract
  (defun-typed a&hs* 
    (
      (tm tm)
      instance
      &optional ➜
      )
      (a tm instance ➜)
      )

  (defun-typed as&h◨ (tm instance &optional ➜)
    (:documentation
      "#'as with a contract that the head is on rightmost.
      "))
   ;; surely specializations will make better use of the contract
  (defun-typed as&hs* 
    (
      (tm tm)
      instance
      &optional ➜
      )
    (as tm instance ➜)
    )


  ;; Spill can be ∅, in which case we just drop the deallocated cell.  When spill is not ∅,
  ;; then the deallocated cell is moved to spill, or a new allocation is made on spill and
  ;; the instance from the deallocated cell is moved to it, preferably the former. 
  ;;
  ;; d must have transactional behavior, i.e. the cell is only dealloced if all goes well,
  ;; otherwise d makes no structural changes.  E.g. d will fail if spill is not nil, and
  ;; reallocation to spill fails
  ;;
    (defun-typed d (tm &optional spill ➜)
      (:documentation
        "Deallocate the right neighbor of the cell the head is on.
         I.e. deallocates a region of length 1 located to the right of the head.
         Returns the instance from the deallocated cell.
         If spill is not ∅, the deallocated cell is moved to spill, or a new
         cell is allocated to spill and the instance reference is moved there.
        "
        ))

    (defun-typed epd (tm &optional spill ➜)
      (:documentation
        "Deallocates leftmost.
         Returns the instance from the deallocated cell.
         If spill is not ∅, the deallocated cell is moved to spill, or a new
         cell is allocated to spill and the instance reference is moved there.
        "
        ))

  ;; this function is private. intended to be used with entanglement accounting.
  ;; after another machine in the entanglement group does an epa, we need to
  ;; update the tape reference for the other memebers of the group.
  (defun-typed update-tape-after-epa (tm tm-ref))

  ;; this function is private. intended to be used with entanglement accounting.
  ;; after another machine in the entanglement group does an epa, we need to
  ;; update the tape reference for the other memebers of the group.
  (defun-typed update-tape-after-epd (tm tm-ref))




