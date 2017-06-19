#|
Copyright (c) 2017 Thomas W. Lynch and Reasoning Technology Inc.
Released under the MIT License (MIT)
See LICENSE.txt

Architectural definition of a tape.

This tape machine interface does not take into account entanglements or threads.  These
things must be enforced externally.

Though these are tapes, not tape machines, function names found here appear to refer to
head operations. For example, '◧' which reads as entanglement copy and step left to
leftmost.  These names are used only because they are descriptive of what the
corresponding function does to the tape.

Not all tapes implement all of the interface.  The tapes only implement the interface
portions that are primitive relative to the implementation.  As an example, the
singly linked list has no left going operations.

When the call interface of a tape function differes from its tape machine analog
we append <tape> or <cell> to its name.

We pushe end cases into dispatch.  Dispatch already makes decisions based
on operand type, and it won't mind having a few more types to work with.

|# 

(in-package #:tm)

;;--------------------------------------------------------------------------------
;;
  (def-type cell ()()) ; a union of cell types

  ;; context senstive functions at the tape level
  (def-type tape-class ()
    (
      (tape-class-d.<cell>
        :initform 
        (λ (tape-ctx cell-0 &optional ➜)
          (destructuring-bind
            (&key
              (➜rightmost (λ()(error 'dealloc-on-rightmost)))
              &allow-other-keys
              )
            ➜
            (let(
                  (cell-0-instance (r<cell> cell-0))
                  )
              [(right-neighbor tape-ctx) cell-0
                {
                  :➜ok
                  (λ(cell-1)
                    (let(
                          (cell-1-instance (r<cell> cell-1))
                          )
                      [(w<cell> tape-ctx) cell-0 cell-1-instance]
                      [(w<cell> tape-ctx) cell-1 cell-0-instance]
                      [(d<cell> tape-ctx) cell-0 ➜]
                      ))
                  :➜rightmost ➜rightmost
                  }]
              )))
        )))
  (defvar *tape-class* (make-instance 'tape-class))

  (def-type tape ()
    (
      ;; these functions are optimized on a per type basis:
      ;; type-class  ; use dispatch instead of walking through here

      ;; these functions are custom optimized for each instance:
      (=<cell>
        :initarg :cons-list
        :accessor cons-list
        )
      (r<cell>
        :initarg :r<cell>
        :accessor r<cell>
        )
      (w<cell>
        :initarg :w<cell>
        :accessor w<cell>
        )
      (right-neighbor
        :initarg :right-neighbor
        :accessor right-neighbor
        )
      (a<cell>
        :initarg :a<cell>
        :accessor a<cell>
        )
      (a<instance>
        :initarg :a<instance>
        :accessor a<instance>
        )
      (d<cell>
        :initarg :d<cell>
        :accessor d<cell>
        )
      (d.<cell>
        :initarg :d<cell>
        :accessor d<cell>
        )
      (d*<cell>
        :initarg :d*<cell>
        :accessor d*<cell>
        )))

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
                   [(w<cell> tape-1) cell-1 initial-instance]
                   [(right-neighbor tape-1) cell-1
                     {
                       :➜rightmost #'do-nothing ; we are finished
                       :➜ok (λ(rn-1)(copy-2 rn-1))
                       }])
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
                   [(w<cell> tape-1) cell-1 initial-instance]
                   [(right-neighbor tape-1) cell-1
                     {
                       :➜rightmost #'do-nothing ; we are finished
                       :➜ok (λ(rn-1)(copy-2 rn-1))
                       }])

                 (copy-1 (cell-1 cell-0)
                   [(w<cell> tape-1) cell-1 (r<cell> cell-0)]
                   [(right-neighbor tape-1) cell-1
                     {
                       :➜rightmost #'do-nothing ; we are finished
                       :➜ok
                       (λ(rn-1)
                         [(right-neighbor tape-0) cell-0
                           {
                             :➜rightmost ; uh-oh ran out of copyializer data
                             (λ()(copy-2 rn-1))
                             :➜ok
                             (λ(rn-0)
                               (copy-1 rn-1 rn-0)
                               )
                             }])}])

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

    ;; appends new cell to cell-1 and initializes it to the instance from cell-0
    ;; recurs on right neighbors of cell-1 and cell-0
    ;; returns rightmost of tape-1, in case it is needed, perhaps for a tail pointer
    (defun shallow-copy-topo-extend (tape-ctx-1 cell-1 tape-ctx-0 cell-0 &optional (cont-ok #'echo))
      (labels(
               (shallow-copy-topo-extend-1 (cell-1 cell-0)
                 [(a<instance> tape-ctx-1) cell-1 [(r<cell> tape-ctx-0) cell-0]]
                 [(right-neighbor tape-ctx-1) cell-1
                   {
                     :➜ok
                     (λ(rn-1)
                       [(right-neighbor tape-ctx-0) cell-0
                         {
                           :➜ok
                           (λ(rn-0)(shallow-copy-topo-extend-1 rn-1 rn-0))
                           :➜rightmost
                           (λ()[cont-ok rn-1])
                           }])
                     :➜rightmost #'cant-happen ; we just added a cell
                     }])
               )
        (shallow-copy-topo-extend-1 cell-1 cell-0)
        ))

    (defun shallow-copy-topo-overwrite (tape-ctx-1 cell-1 tape-ctx-0 cell-0 &optional (cont-ok #'echo))
      (labels(
               (shallow-copy-topo-overwrite-1 (cell-1 cell-0)
                 [(w<cell> tape-ctx-1) cell-1 [(r<cell> tape-ctx-0) cell-0]]
                 [(right-neighbor tape-ctx-0) cell-0
                   {
                     :➜ok
                     (λ(rn-0)
                       [(right-neighbor tape-ctx-1) cell-1
                         {
                           :➜ok
                           (λ(rn-1)(shallow-copy-topo-overwrite-1 rn-1 rn-0))
                           :➜rightmost ;ran out of places to write initialization data, so extend..
                           (λ()
                             (shallow-copy-topo-extend 
                               tape-ctx-1 cell-1 
                               tape-ctx-0 rn-0
                               cont-ok)) 
                           }])
                     :➜rightmost ; no more initialization data, we are done
                     (λ()
                       [(d*<cell> tape-ctx-1) cell-1]
                       [cont-ok cell-1]
                       )}])
               )
        (shallow-copy-topo-overwrite-1 cell-1 cell-0)
        ))

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
                    [(right-neighbor tape-0) cell-0
                      {
                        :➜ok
                        (λ(rn-0)(shallow-copy-topo-extend tape-1 cell-1 tape-0 rn-0))
                        :➜rightmost ; no more initialization data, so we are done!
                        (λ()[➜ok cell-1])
                        }])
                  :➜empty #'cant-happen ; we just added a cell
                  }))
             })))
    (defun-typed shallow-copy-topo ((tape-1 tape-active) (tape-0 tape-active) &optional ➜)
      (let(
            (cell-1 (leftmost tape-1))
            (cell-0 (leftmost tape-0))
            )
        (shallow-copy-topo-overwrite tape-1 cell-1 tape-0 cell-0 ➜)
        ))

;;--------------------------------------------------------------------------------
;; instance specific functions
;;
  (def-function-class mk-type-class-functions (tape))

;;--------------------------------------------------------------------------------
;; accessing instances
;;
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
      [➜ok [(r<cell> tape) (leftmost tape)]]
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
        [(right-neighbor tape) leftmost
          {
            :➜ok 
            (λ(the-right-neighbor)
              [➜ok [(r<cell> tape) the-right-neighbor]]
              )
            :➜rightmost ➜rightmost
            }])))

  (def-function-class ◧w (tape instance &optional ➜))
  (defun-typed ◧w ((tape tape-empty) instance &optional ➜)
    (declare (ignore tape))
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
        (➜ok #'echo)
        &allow-other-keys
        )
      ➜
      [➜ok [(w<cell> tape) (leftmost tape) instance]]
      ))


  ;; (➜ok #'echo) (➜rightmost (be ∅))
  (def-function-class ◧sw (tape instance &optional ➜))
  (defun-typed ◧sw ((tape tape-empty) instance &optional ➜)
    (declare (ignore tape))
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
        (➜ok #'echo)
        (➜rightmost (λ()(error 'step-from-rightmost)))
        &allow-other-keys
        )
      ➜
      (let(
            (leftmost (leftmost tape))
            )
        [(right-neighbor tape) leftmost
          {
            :➜ok 
            (λ(the-right-neighbor)
              [➜ok [(w<cell> tape) the-right-neighbor instance]]
              )
            :➜rightmost ➜rightmost
            }])))


  ;; for doubly linked lists we also have:

  (def-function-class es*r (tape &optional ➜))
  (defun-typed es*r ((tape tape-empty) &optional ➜)
    (declare (ignore tape))
    (destructuring-bind
      (&key
        (➜empty #'accessed-empty)
        &allow-other-keys
        )
      ➜
      [➜empty]
      ))
  (defun-typed es*r ((tape tape-active) &optional ➜)
    (destructuring-bind
      (&key
        (➜ok #'echo)
        &allow-other-keys
        )
      ➜
      [➜ok [(r<cell> tape)(rightmost tape)]]
      ))

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
              [➜ok [(r<cell> tape) the-left-neighbor]]
              )
            :➜leftmost ➜leftmost
            }))))

  (def-function-class es*w (tape instance &optional ➜))
  (defun-typed es*w ((tape tape-empty) instance &optional ➜)
    (declare (ignore tape instance))
    (destructuring-bind
      (&key
        (➜empty #'accessed-empty)
        &allow-other-keys
        )
      ➜
      [➜empty]
      ))
  (defun-typed es*w ((tape tape-active) instance &optional ➜)
    (destructuring-bind
      (&key
        (➜ok #'echo)
        &allow-other-keys
        )
      ➜
      [➜ok [(w<cell> tape) (rightmost tape) instance]]
      ))

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
        (➜leftmost (λ()(error 'step-from-leftmost)))
        &allow-other-keys
        )
      ➜
      (let(
            (rightmost (rightmost tape))
            )
        [(left-neighbor tape) rightmost
          {
            :➜ok 
            (λ(the-left-neighbor)
              [➜ok [(w<cell> tape) the-left-neighbor instance]]
              )
            :➜leftmost ➜leftmost
            }])))

;;--------------------------------------------------------------------------------
;; topology queries
;;
  (def-function-class leftmost (tape &optional ➜)) ; returns a cell
  (defun-typed leftmost ((tape tape-empty) &optional ➜)
    (declare (ignore tape))
    (destructuring-bind
      (&key
        (➜empty #'accessed-empty)
        &allow-other-keys
        )
      ➜
      [➜empty]
      ))

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

  ;;;; this is now declared within a tape context
  ;;;; (➜ok #'echo) (➜leftmost (be ∅))
  ;;;; (def-function-class left-neighbor (cell &optional ➜))

;;--------------------------------------------------------------------------------
;; topology manipulation
;;
  ;; inserts the given cell as a new leftmost cell
  (def-function-class epa<cell> (tape cell))

  ;; makes and inserts a new leftmost cell initialized to the given instance
  (def-function-class epa<instance> (tape instance))

  ;; for a doubly linked list, these are the 'operate on tail' versions of the above
  (def-function-class es*a<cell> (tape cell))
  (def-function-class es*a<instance> (tape instance))
  ;; (➜ok #'echo) (➜leftmost (be ∅))
  (def-function-class ◨d<tape> (tape &optional ➜))
  (defun-typed ◨d<tape> ((tape tape-empty) &optional ➜)
    (declare (ignore tape))
    (destructuring-bind
      (&key
        (➜leftmost (λ()(error 'dealloc-on-leftmost)))
        &allow-other-keys
        )
      ➜
      [➜leftmost]
      ))

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

  ;;;; left neighbor version for doubly linked lists
  ;;;; (➜ok #'echo) (➜leftmost (be ∅))
  ;;;; (def-function-class -d<cell> (cell &optional ➜))

  ;; If there is no rightneighbor, fails with ➜rightneighbor.
  ;; Swaps instances with the rightneighbor, then deletes the rightneighbor.
  ;; Returns the deleted rightneighbor after the instance swap.
  ;; Creates the appearence of deleting 'this cell' even for a singly linked list.
  ;; This is not needed for doubly linked lists, which can simply use 's-d'.
  ;;
  ;; (➜ok #'echo) (➜rightmost  (λ()(error 'dealloc-on-rightmost))).
  ;;
    (defun tape-class-d.<cell> (tape-ctx cell-0 &optional ➜)
      (destructuring-bind
        (&key
          (➜rightmost (λ()(error 'dealloc-on-rightmost)))
          &allow-other-keys
          )
        ➜
        (let(
              (cell-0-instance (r<cell> cell-0))
              )
          [(right-neighbor tape-ctx) cell-0
            {
              :➜ok
              (λ(cell-1)
                (let(
                      (cell-1-instance (r<cell> cell-1))
                      )
                  [(w<cell> tape-ctx) cell-0 cell-1-instance]
                  [(w<cell> tape-ctx) cell-1 cell-0-instance]
                  [(d<cell> tape-ctx) cell-0 ➜]
                  ))
              :➜rightmost ➜rightmost
              }]
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
  (def-function-class epd*<tape> (tape &optional ➜))


;;--------------------------------------------------------------------------------
;; length-tape
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
      [(right-neighbor tape) (leftmost tape)
        {
          :➜ok (λ(cell)(declare (ignore cell))[➜∅])
          :➜rightmost ➜t
          }]))

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
      [(right-neighbor tape) (leftmost tape)
        {
          :➜ok (λ(cell)
                 [(right-neighbor tape) cell
                   {
                     :➜ok (λ(cell)(declare (ignore cell))[➜∅])
                     :➜rightmost ➜t
                     }])
          :➜rightmost ➜∅
          }]))

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
                   [(right-neighbor tape) cell
                     {
                       :➜ok
                       (λ(the-right-neighbor)
                         (incf index)
                         (init-1 the-right-neighbor)
                         )
                       :➜rightmost
                       #'do-nothing
                       }])
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
                
     

     
     
