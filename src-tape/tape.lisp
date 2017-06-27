#|
Copyright (c) 2017 Thomas W. Lynch and Reasoning Technology Inc.
Released under the MIT License (MIT)
See LICENSE.txt

Architectural definition of a tape.

This tape interface does not take into account entanglements or threads.  These
things must be enforced externally.

These are tapes, not tape machines, function names found here appear to refer to head
operations. For example, '◧sr' which reads as entanglement copy, step left to leftmost,
step right, and read.  These names are used only because they are descriptive of what the
corresponding function does, not because there is a tape head.  In this case, ◧sr, reads
the second instance on the tape.

Because these are tapes, and not tape machines, I avoided the temptation to implement
iteration here.  I have come back and added right-nieghbor-n and left-neighbor-n.
This is because it is easy to add 'n' to an array index for the arrays.

Not all tapes implement all of the interface.  The tapes only implement the interface
portions that are primitive relative to the implementation.  As an example, the singly
linked list has no left going operations.

When the call interface of a tape function differes from its tape machine analog we append
<tape> or <cell> to its name.

We push end cases into dispatch.  Dispatch already makes decisions based on operand type,
and it won't mind having a few more types to work with.

|# 

(in-package #:tm)

;;--------------------------------------------------------------------------------
;; type
;;
  (def-type cell ()()) ; a union of cell types

  (def-type tape ()()) ; a union of tape types
  (def-type tape-active (tape)()) ; a union of tape types
  (def-type tape-empty (tape)()) ; a union of tape types

  (def-function-class to-empty (tape))
  (def-function-class to-active (tape))

  ;;----------------------------------------
  ;; generic init
  ;;
  ;; Generic init methods are difficult in general. This is because init's whole purpose
  ;; is to set up the custom type.
  ;;

  ;;   note that in Common Lisp (typep ∅ 'sequence) -> t
  ;;   I would argue this is a design flaw, because dispatch is all about choosing
  ;;   different functions for end cases.  Because (typep ∅ 'sequence) is true, we must
  ;;   explicitly test for null sequences in guard code.
  ;;
  ;;   Note, Mathematica will let us add additional tests into dispatch, so we can
  ;;   also have a special function for sequence length of zero:
  ;;   (defun-typed init ((tape tape) (seq?(= 0 (length seq)) sequence) &optional ➜)
  ;;    ..  but CLOS does not, so we must build the (= 0 length) test into guard code for
  ;;    every specialization (as opposed to specifying it in the argument list for every
  ;;    specialization -- LOL, seems sequence length zero should be another type also.)
  ;;
  ;; (defun-typed init ((tape tape) (init null) &optional ➜)

  ;; In general for intialization to an empty machine, for machines that can modify
  ;; topology, the function #'epa can transition them to tape-active.  If such machines
  ;; can also be customized by parameters then there will have to be a more specific
  ;; version of empty init so as to catch those paramters.
  ;;
    (defun-typed init ((tape-1 tape) (tape-0 tape-empty) &optional ➜)
      (destructuring-bind
        (&key
          (➜ok #'echo)
          &allow-other-keys
          )
        ➜
        (to-empty tape-1)
        [➜ok tape-1]
        ))

   ;; It is possible to write a generic tape copy initializer for tapes that support toplogy
   ;; modification and do not take customization parameters by making use of #'epa.
   ;;
   ;; This would be its call interface:
   ;;   (defun-typed init ((tape-1 tape) (tape-0 tape-active) &optional ➜)
   

  ;;----------------------------------------
  ;; copy - similar to init
  ;; 
    (def-function-class shallow-copy-no-topo (tape-1 tape-0 &optional ➜))
    (defun-typed shallow-copy-no-topo ((tape-1 tape-empty) (tape-0 tape) &optional ➜)
      (destructuring-bind
        (&key
          (➜ok (be t))
          &allow-other-keys
          )
        ➜
        [➜ok]
        ))
    (defun-typed shallow-copy-no-topo ((tape-1 tape-active) (tape-0 tape-empty) &optional ➜)
      (destructuring-bind
        (&key
          initial-instance
          (➜ok (be t))
          &allow-other-keys
          )
        ➜
        (labels(
                 (copy-2 (cell-1)
                   (w<cell> cell-1 initial-instance)
                   (right-neighbor cell-1
                     {
                       :➜rightmost #'do-nothing ; we are finished
                       :➜ok (λ(rn-1)(copy-2 rn-1))
                       }))
                 (copy-0 ()
                   (let(
                         (cell-1 (leftmost tape-1)) ; active tapes always have a leftmost
                         )
                     (copy-2 cell-1)
                     ))
                 )
          (copy-0)
          )
        [➜ok]
        ))
    (defun-typed shallow-copy-no-topo ((tape-1 tape-active) (tape-0 tape-active) &optional ➜)
      (destructuring-bind
        (&key
          initial-instance
          (➜ok (be t))
          &allow-other-keys
          )
        ➜
        (labels(
                 (copy-2 (cell-1)
                   (w<cell> cell-1 initial-instance)
                   (right-neighbor cell-1
                     {
                       :➜rightmost #'do-nothing ; we are finished
                       :➜ok (λ(rn-1)(copy-2 rn-1))
                       }))
                 (copy-1 (cell-1 cell-0)
                   (w<cell> cell-1 (r<cell> cell-0))
                   (right-neighbor cell-1
                     {
                       :➜rightmost #'do-nothing ; we are finished
                       :➜ok
                       (λ(rn-1)
                         (right-neighbor cell-0
                           {
                             :➜rightmost ; uh-oh ran out of copyializer data
                             (λ()(copy-2 rn-1))
                             :➜ok
                             (λ(rn-0)
                               (copy-1 rn-1 rn-0)
                               )
                             }))}))
                 (copy-0 ()
                   (let(
                         (cell-1 (leftmost tape-1)) ; active tapes always have a leftmost
                         (cell-0 (leftmost tape-0)) ; active tapes always have a leftmost
                         )
                     (copy-1 cell-1 cell-0)
                     ))
                 )
          (copy-0)
          )
        [➜ok]
        ))

    ;; appends new cell to cell-1 and initialized to isntance from cell-0
    ;; recurs on right neighbors of cell-1 and cell-0
    ;; returns rightmost of tape-1, in case it is needed, perhaps for a tail pointer
    (defun shallow-copy-topo-extend (cell-1 cell-0 &optional (cont-ok #'echo))
      (a<instance> cell-1 (r<cell> cell-0))
      (right-neighbor cell-1
        {
          :➜ok
          (λ(rn-1)
            (right-neighbor cell-0
              {
                :➜ok
                (λ(rn-0)(shallow-copy-topo-extend rn-1 rn-0))
                :➜rightmost
                (λ()[cont-ok rn-1])
                }))
          :➜rightmost #'cant-happen ; we just added a cell
          }))

    (defun shallow-copy-topo-overwrite (cell-1 cell-0 &optional (cont-ok #'echo))
      (w<cell> cell-1 (r<cell> cell-0))
      (right-neighbor cell-0
        {
          :➜ok
          (λ(rn-0)
            (right-neighbor cell-1
              {
                :➜ok
                (λ(rn-1)(shallow-copy-topo-overwrite rn-1 rn-0))
                :➜rightmost ;ran out of places to write initialization data, so extend..
                (λ()(shallow-copy-topo-extend cell-1 rn-0 cont-ok))
                }))
          :➜rightmost ; no more initialization data, we are done
          (λ()
            (d*<cell> cell-1)
            [cont-ok cell-1]
            )}))

    ;; ➜ok returns last cell of tape-1 after copy
    (def-function-class shallow-copy-topo (tape-1 tape-0 &optional ➜))
    (defun-typed shallow-copy-topo ((tape-1 tape-empty) (tape-0 tape-empty) &optional ➜)
      (destructuring-bind
        (&key
          (➜empty (be ∅))
          &allow-other-keys
          )
        ➜
        [➜empty]
        ))
    (defun-typed shallow-copy-topo ((tape-1 tape-active) (tape-0 tape-empty) &optional ➜)
      (destructuring-bind
        (&key
          (➜empty (be ∅))
          &allow-other-keys
          )
        ➜
        (epd*<tape> tape-1)
        [➜empty]
        ))
    (defun-typed shallow-copy-topo ((tape-1 tape-empty) (tape-0 tape-active) &optional ➜)
      (destructuring-bind
        (&key
          (➜ok #'echo)
          &allow-other-keys
          )
        ➜
        (leftmost tape-0
          {
            :➜empty #'cant-happen ; tape is active
            :➜ok
            (λ(cell-0)
              (epa<instance> tape-1 (r<cell> cell-0))
              (leftmost tape-1
                {
                  :➜ok 
                  (λ(cell-1)
                    (right-neighbor cell-0
                      {
                        :➜ok
                        (λ(rn-0)(shallow-copy-topo-extend cell-1 rn-0))
                        :➜rightmost ; no more initialization data, so we are done!
                        (λ()[➜ok cell-1])
                        }))
                  :➜empty #'cant-happen ; we just added a cell
                  }))
             })))
    (defun-typed shallow-copy-topo ((tape-1 tape-active) (tape-0 tape-active) &optional ➜)
      (let(
            (cell-1 (leftmost tape-1))
            (cell-0 (leftmost tape-0))
            )
        (shallow-copy-topo-overwrite cell-1 cell-0 ➜)
        ))

;;--------------------------------------------------------------------------------
;; tape queries
;;
  (def-function-class =<cell> (cell-0 cell-1 &optional ➜))

  (def-function-class r<cell> (cell)) ; returns an instance
  (def-function-class w<cell> (cell instance))

  (def-function-class leftmost (tape &optional ➜)) ; returns a cell
  (defun-typed leftmost ((tape tape-empty) &optional ➜)
    (destructuring-bind
      (&key
        (➜empty #'accessed-empty)
        &allow-other-keys
        )
      ➜
      [➜empty]
      ))

  ;; (➜ok #'echo) (➜rightmost (be ∅))
  (def-function-class right-neighbor (cell &optional ➜))

  ;; then nth neighbor to the right
  (defun right-neighbor-n (cell n &optional ➜)
      (if
        (< 0 n)
        (left-neighbor-n cell (- n))
        (destructuring-bind
          (&key
            (➜ok #'echo)
            (➜rightmost (λ(n1 cell)(declare (ignore n1 cell))(error 'step-from-rightmost)))
            &allow-other-keys
            )
          ➜
          (labels(
                  (work (i c0)
                    (cond
                      ((= 0 i) [➜ok c0])
                      (t
                        (right-neighbor c0
                          {
                            :➜ok (λ(c1)(work (1- i) c1))
                            :➜rightmost (λ()[➜rightmost i c0])
                            }))))
                  )
            (work n cell)
            ))))

  ;; for doubly linked lists we also have:

  (def-function-class rightmost (tape &optional ➜)) ; returns a cell
  (defun-typed rightmost ((tape tape-empty) &optional ➜)
    (declare (ignore tape))
    (destructuring-bind
      (&key
        (➜empty #'accessed-empty)
        &allow-other-keys
        )
      ➜
      [➜empty]
      ))

  ;; (➜ok #'echo) (➜leftmost (be ∅))
  (def-function-class left-neighbor (cell &optional ➜))
  (defun left-neighbor-n (cell n &optional ➜)
      (if
        (< 0 n)
        (right-neighbor-n cell (- n))
        (destructuring-bind
          (&key
            (➜ok #'echo)
            (➜leftmost (λ(n1 cell)(declare (ignore n1 cell))(error 'step-from-leftmost)))
            &allow-other-keys
            )
          ➜
          (labels(
                  (work (i c0)
                    (cond
                      ((= 0 i) [➜ok c0])
                      (t
                        (left-neighbor c0
                          {
                            :➜ok (λ(c1)(work (1- i) c1))
                            :➜leftmost (λ()[➜leftmost i c0])
                            }))))
                  )
            (work n cell)
            ))))


;;--------------------------------------------------------------------------------
;; advanced tape queries
;;

  ;; returns an instance
  (defun esr<cell> (cell &optional ➜)
    (destructuring-bind
      (&key
        (➜ok #'echo)
        (➜rightmost (λ()(error 'step-from-rightmost)))
        &allow-other-keys
        )
      ➜
      (right-neighbor cell
        {
          :➜ok (λ(rn)[➜ok (r<cell> rn)])
          :➜rightmost ➜rightmost
          })))

  (defun esnr<cell> (cell n &optional ➜)
    (destructuring-bind
      (&key
        (➜ok #'echo)
        (➜rightmost (λ(k)(declare (ignore k))(error 'step-from-rightmost)))
        &allow-other-keys
        )
      ➜
      (right-neighbor-n cell n
        {
          :➜ok (λ(rn)[➜ok (r<cell> rn)])
          :➜rightmost (λ(k rn)(declare (ignore rn))[➜rightmost k])
          })))

  (def-function-class ◧r (tape &optional ➜))
  (defun-typed ◧r ((tape tape-empty) &optional ➜)
    (declare (ignore tape))
    (destructuring-bind
      (&key
        (➜empty #'accessed-empty)
        &allow-other-keys
        )
      ➜
      [➜empty]
      ))
  (defun-typed ◧r ((tape tape-active) &optional ➜)
    (destructuring-bind
      (&key
        (➜ok #'echo)
        &allow-other-keys
        )
      ➜
      [➜ok (r<cell> (leftmost tape))]
      ))

  ;; (➜ok #'echo) (➜rightmost (be ∅))
  (def-function-class ◧sr (tape &optional ➜))
  (defun-typed ◧sr ((tape tape-empty) &optional ➜)
    (destructuring-bind
      (&key
        (➜empty #'accessed-empty)
        &allow-other-keys
        )
      ➜
      [➜empty]
      ))
  (defun-typed ◧sr ((tape tape-active) &optional ➜)
    (destructuring-bind
      (&key
        (➜ok #'echo)
        (➜rightmost (λ()(error 'step-from-rightmost)))
        &allow-other-keys
        )
      ➜
      (let(
            (leftmost (leftmost tape))
            )
        (right-neighbor leftmost
          {
            :➜ok 
            (λ(the-right-neighbor)
              [➜ok (r<cell> the-right-neighbor)]
              )
            :➜rightmost ➜rightmost
            }))))

  (def-function-class ◧snr (tape n &optional ➜))
  (defun-typed ◧snr ((tape tape-empty) n &optional ➜)
    (declare (ignore n))
    (destructuring-bind
      (&key
        (➜empty #'accessed-empty)
        &allow-other-keys
         )
      ➜
      [➜empty]
      ))
  (defun-typed ◧snr ((tape tape-active) n &optional ➜)
    (destructuring-bind
      (&key
        (➜ok #'echo)
        (➜rightmost (λ()(error 'step-from-rightmost)))
        &allow-other-keys
        )
      ➜
      (let(
            (leftmost (leftmost tape))
            )
        (right-neighbor-n leftmost n
          {
            :➜ok 
            (λ(the-right-neighbor)
              [➜ok (r<cell> the-right-neighbor)]
              )
            :➜rightmost ➜rightmost
            }))))


  (defun esw<cell> (cell instance &optional ➜)
    (destructuring-bind
      (&key
        (➜ok #'echo)
        (➜rightmost (λ()(error 'step-from-rightmost)))
        &allow-other-keys
        )
      ➜
      (right-neighbor cell
        {
          :➜ok (λ(rn)(r<cell> rn instance)[➜ok])
          :➜rightmost ➜rightmost
          })))

  (defun esnw<cell> (cell n instance &optional ➜)
    (destructuring-bind
      (&key
        (➜ok #'echo)
        (➜rightmost (λ(k)(declare (ignore k))(error 'step-from-rightmost)))
        &allow-other-keys
        )
      ➜
      (right-neighbor-n cell n
        {
          :➜ok (λ(rn)(w<cell> rn instance)[➜ok])
          :➜rightmost (λ(k rn)(declare (ignore rn))[➜rightmost k])
          })))

  (def-function-class ◧w (tape instance &optional ➜))
  (defun-typed ◧w ((tape tape-empty) instance &optional ➜)
    (declare (ignore instance))
    (destructuring-bind
      (&key
        (➜empty #'accessed-empty)
        &allow-other-keys
        )
      ➜
      [➜empty]
      ))
  (defun-typed ◧w ((tape tape-active) instance &optional ➜)
    (destructuring-bind
      (&key
        (➜ok (be t))
        &allow-other-keys
        )
      ➜
      (w<cell> (leftmost tape) instance)
      [➜ok]
      ))


  ;; (➜ok #'echo) (➜rightmost (be ∅))
  (def-function-class ◧sw (tape instance &optional ➜))
  (defun-typed ◧sw ((tape tape-empty) instance &optional ➜)
    (declare (ignore instance))
    (destructuring-bind
      (&key
        (➜empty #'accessed-empty)
        &allow-other-keys
         )
      ➜
      [➜empty]
      ))
  (defun-typed ◧sw ((tape tape-active) instance &optional ➜)
    (destructuring-bind
      (&key
        (➜ok (be t))
        (➜rightmost (λ()(error 'step-from-rightmost)))
        &allow-other-keys
        )
      ➜
      (let(
            (leftmost (leftmost tape))
            )
        (right-neighbor leftmost
          {
            :➜ok 
            (λ(the-right-neighbor)
              (w<cell> the-right-neighbor instance)
              [➜ok]
              )
            :➜rightmost ➜rightmost
            }))))

  (def-function-class ◧snw (tape n instance &optional ➜))
  (defun-typed ◧snw ((tape tape-empty) n instance &optional ➜)
    (declare (ignore n instance))
    (destructuring-bind
      (&key
        (➜empty #'accessed-empty)
        &allow-other-keys
         )
      ➜
      [➜empty]
      ))
  (defun-typed ◧snw ((tape tape-active) n instance &optional ➜)
    (destructuring-bind
      (&key
        (➜ok (be t))
        (➜rightmost (be ∅))
        &allow-other-keys
        )
      ➜
      (let(
            (leftmost (leftmost tape))
            )
        (right-neighbor-n leftmost n
          {
            :➜ok 
            (λ(the-right-neighbor)
              (w<cell> the-right-neighbor instance)
              [➜ok]
              )
            :➜rightmost ➜rightmost
            }))))


  ;; for doubly linked lists we also have:
  (def-function-class ◨r (tape &optional ➜))
  (defun-typed ◨r ((tape tape-empty) &optional ➜)
    (declare (ignore tape))
    (destructuring-bind
      (&key
        (➜empty #'accessed-empty)
        &allow-other-keys
        )
      ➜
      [➜empty]
      ))
  (defun-typed ◨r ((tape tape-active) &optional ➜)
    (destructuring-bind
      (&key
        (➜ok #'echo)
        &allow-other-keys
        )
      ➜
      [➜ok (r<cell> (rightmost tape))]
      ))

  (def-function-class ◨-sr (tape &optional ➜))
  (defun-typed ◨-sr ((tape tape-empty) &optional ➜)
    (declare (ignore tape))
    (destructuring-bind
      (&key
        (➜empty #'accessed-empty)
        &allow-other-keys
        )
      ➜
      [➜empty]
      ))
  (defun-typed ◨-sr ((tape tape-active) &optional ➜)
    (destructuring-bind
      (&key
        (➜ok #'echo)
        (➜leftmost (λ()(error 'step-from-leftmost)))
        &allow-other-keys
        )
      ➜
      (let(
            (rightmost (rightmost tape))
            )
        (left-neighbor rightmost
          {
            :➜ok 
            (λ(the-left-neighbor)
              [➜ok (r<cell> the-left-neighbor)]
              )
            :➜leftmost ➜leftmost
            }))))

  (def-function-class ◨w (tape instance &optional ➜))
  (defun-typed ◨w ((tape tape-empty) instance &optional ➜)
    (declare (ignore tape instance))
    (destructuring-bind
      (&key
        (➜empty #'accessed-empty)
        &allow-other-keys
        )
      ➜
      [➜empty]
      ))
  (defun-typed ◨w ((tape tape-active) instance &optional ➜)
    (destructuring-bind
      (&key
        (➜ok #'echo)
        &allow-other-keys
        )
      ➜
      [➜ok (w<cell> (rightmost tape) instance)]
      ))

  (def-function-class ◨-sw (tape instance &optional ➜))
  (defun-typed ◨-sw ((tape tape-empty) instance &optional ➜)
    (declare (ignore tape instance))
    (destructuring-bind
      (&key
        (➜empty #'accessed-empty)
        &allow-other-keys
        )
      ➜
      [➜empty]
      ))
  (defun-typed ◨-sw ((tape tape-active) instance &optional ➜)
    (destructuring-bind
      (&key
        (➜ok #'echo)
        (➜leftmost (λ()(error 'step-from-leftmost)))
        &allow-other-keys
        )
      ➜
      (let(
            (rightmost (rightmost tape))
            )
        (left-neighbor rightmost
          {
            :➜ok 
            (λ(the-left-neighbor)
              [➜ok (w<cell> the-left-neighbor instance)]
              )
            :➜leftmost ➜leftmost
            }))))

;;--------------------------------------------------------------------------------
;; topology manipulation
;;
  ;; prepends tape0 to tape1
  (def-function-class epa<tape> (tape1 tape0))

  ;; inserts the given cell as a new leftmost cell
  (def-function-class epa<cell> (tape cell))

  ;; makes and inserts a new leftmost cell initialized to the given instance
  (def-function-class epa<instance> (tape instance))

  ;; for a doubly linked list, these are the 'operate on tail' versions of the above
  (def-function-class ◨a<cell> (tape cell))
  (def-function-class ◨a<instance> (tape instance))

  ;; inserts tape0 between cell-0 and its right neighbor
  (def-function-class a<tape> (cell-0 tape0))

  ;; makes cell-1 a right-neighbor of cell-0
  (def-function-class a<cell> (cell-0 cell-1))

  ;; makes a new right neighbor for cell, and initializes it with instance.
  (def-function-class a<instance> (cell instance))

  ;; makes cell-1 a left-neighbor of cell-0
  (def-function-class -a<cell> (cell-0 cell-1))

  ;; makes a new left neighbor for cell, and initializes it with instance.
  (def-function-class -a<instance> (cell instance))

  ;; removes the leftmost cell and returns it
  ;; (➜ok #'echo) (➜rightmost (be ∅))
  (def-function-class epd<tape> (tape &optional ➜))
  (defun-typed epd<tape> ((tape tape-empty) &optional ➜)
    (declare (ignore tape))
    (destructuring-bind
      (&key
        (➜rightmost (λ()(error 'dealloc-on-rightmost)))
        &allow-other-keys
        )
      ➜
      [➜rightmost]
      ))

  ;; releases tape data
  ;; afterward tape will be empty
  (def-function-class epd*<tape> (tape &optional ➜))

  ;; (➜ok #'echo) (➜leftmost (be ∅))
  (def-function-class ◨-sd<tape> (tape &optional ➜))
  (defun-typed ◨-sd<tape> ((tape tape-empty) &optional ➜)
    (declare (ignore tape))
    (destructuring-bind
      (&key
        (➜leftmost (λ()(error 'dealloc-on-leftmost)))
        &allow-other-keys
        )
      ➜
      [➜leftmost]
      ))

  ;; given a cell removes its right neighbor and returns it
  ;; (➜ok #'echo) (➜rightmost (λ()(error 'dealloc-on-rightmost)))
  (def-function-class d<cell> (cell &optional ➜))

  ;; left neighbor version for doubly linked lists
  ;; (➜ok #'echo) (➜leftmost (be ∅))
  (def-function-class -d<cell> (cell &optional ➜))

  ;; If there is no rightneighbor, failes with ➜rightneighbor.
  ;; Swaps instances with the rightneighbor, then deletes the rightneighbor.
  ;; Returns the deleted rightneighbor after the instance swap.
  ;; Creates the appearence of deleting 'this cell' even for a singly linked list.
  ;; This is not needed for doubly linked lists, which can simply use 's-d'.
  ;;
  ;; (➜ok #'echo) (➜rightmost  (λ()(error 'dealloc-on-rightmost))).
  (def-function-class d.<cell> (cell &optional ➜))
  (defun-typed d.<cell> ((cell-0 cell) &optional ➜)
    (destructuring-bind
      (&key
        (➜rightmost (λ()(error 'dealloc-on-rightmost)))
        &allow-other-keys
        )
      ➜
      (let(
            (cell-0-instance (r<cell> cell-0))
            )
        (right-neighbor cell-0
          {
            :➜ok
            (λ(cell-1)
              (let(
                    (cell-1-instance (r<cell> cell-1))
                    )
                (w<cell> cell-0 cell-1-instance)
                (w<cell> cell-1 cell-0-instance)
                (d<cell> cell-0 ➜)
                ))
            :➜rightmost ➜rightmost
            })
        )))

  ;; appears to delete the leftmost cell, but doesn't, hence avoiding sharing issues
  ;; however external references to the right neighbor of leftmost become orphaned
  ;; (➜ok #'echo) (➜empty #'accessed-empty)
  (def-function-class ◧d.<tape> (tape &optional ➜))
  (defun-typed ◧d.<tape> ((tape tape-empty) &optional ➜)
    (declare (ignore tape))
    (destructuring-bind
      (&key
        (➜empty #'accessed-empty)
        &allow-other-keys
        )
      ➜
      [➜empty]
      ))

  ;; (➜ok (be t))
  (def-function-class d*<cell> (cell &optional ➜))


;;--------------------------------------------------------------------------------
;; length
;;
  (def-function-class tape-length-is-one (tape &optional ➜))
  (defun-typed tape-length-is-one ((tape tape-empty) &optional ➜)
    (declare (ignore tape))
    (destructuring-bind
      (&key
        (➜∅ (be ∅))
        &allow-other-keys
        )
      ➜
      [➜∅]
      ))
  (defun-typed tape-length-is-one ((tape tape) &optional ➜)
    (destructuring-bind
      (&key
        (➜t (be t))
        (➜∅ (be ∅))
        &allow-other-keys
        )
      ➜
      (right-neighbor (leftmost tape)
        {
          :➜ok (λ(cell)(declare (ignore cell))[➜∅])
          :➜rightmost ➜t
          })))

  (def-function-class tape-length-is-two (tape &optional ➜))
  (defun-typed tape-length-is-two ((tape tape-empty) &optional ➜)
    (declare (ignore tape))
    (destructuring-bind
      (&key
        (➜∅ (be ∅))
        &allow-other-keys
        )
      ➜
      [➜∅]
      ))
  (defun-typed tape-length-is-two ((tape tape) &optional ➜)
    (destructuring-bind
      (&key
        (➜t (be t))
        (➜∅ (be ∅))
        &allow-other-keys
        )
      ➜
      (right-neighbor (leftmost tape)
        {
          :➜ok (λ(cell)
                 (right-neighbor cell
                   {
                     :➜ok (λ(cell)(declare (ignore cell))[➜∅])
                     :➜rightmost ➜t
                     }))
          :➜rightmost ➜∅
          })))

 (def-function-class maximum-address (tape &optional ➜))
 (defun-typed maximum-address ((tape tape-empty) &optional ➜)
    (declare (ignore tape))
    (destructuring-bind
      (&key
        (➜empty #'accessed-empty)
        &allow-other-keys
        )
      ➜
      [➜empty]
      ))
 (defun-typed maximum-address ((tape tape-active) &optional ➜)
    (destructuring-bind
      (&key
        (➜ok #'echo)
        &allow-other-keys
        )
      ➜
      (let(index cell)
        (labels(
                 (init-1 (cell)
                   (right-neighbor cell
                     {
                       :➜ok
                       (λ(the-right-neighbor)
                         (incf index)
                         (init-1 the-right-neighbor)
                         )
                       :➜rightmost
                       #'do-nothing
                       }))
                 (init-0 ()
                   (setf index 0)
                   (setf cell (leftmost tape))
                   (init-1 cell)
                   )
                 )
          (init-0)
          )
        [➜ok index]
        )))
                
     

     
     
