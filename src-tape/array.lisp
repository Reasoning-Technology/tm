#|
Copyright (c) 2017 Thomas W. Lynch and Reasoning Technology Inc.
Released under the MIT License (MIT)
See LICENSE.txt

  A tape space implemented over an array. Each cell holds an array element.

  Topology modification is not supported.


|#

(in-package #:tm)

;;--------------------------------------------------------------------------------
;;

  ;; If this were C we could have an actual cell rather than emulating one here.
  ;; Accordingly, instead of the index we would have a reference, then dereference it to
  ;; do a read.  Though we would still need to know the max index to handle the
  ;; rightmost endcase on a right-neighbor call.
  (def-type cell-array (cell)
    (
      (tape
        :initarg :tape
        :accessor tape
        )
      (index
        :initarg :index
        :accessor index
        )
      ))

  ;; potentially shared by a number of tape-arrays
  ;; stuff one would like to see compiled away, would like to put in sym table instead
  (def-type tape-array-parms ()
    (
      (name ; name for the parms
        :initarg :name
        :accessor name
        )
      (maxdex ; maximum index into the array
        :initarg :maxdex
        :accessor maxdex
        )
      (element-length ;; ingnored at the moment, our arrays currently only hold references
        :initarg :element-length
        :accessor element-length
        )
      ))

  (def-type tape-array (tape)
    (
      (the-array
        :initarg :the-array
        :accessor the-array
        )
      (parms
        :initarg :parms
        :accessor parms
        )
      ))

  (def-type tape-array-active (tape-array tape-active)())
  (def-type tape-array-empty (tape-array tape-empty)())
  (defun-typed to-active ((tape tape-array)) (change-class tape 'tape-array-active))
  (defun-typed to-empty  ((tape tape-array)) (change-class tape 'tape-array-empty))

  (defun init-parms-tape-array (tape seq ➜ cont-ok cont-empty)
    (destructuring-bind
      (&key
        ;; parms ; to pass a parms in we need a parms dictionary to look the name up ..
        maxdex
        &allow-other-keys
        )
      ➜
      (let(
            (length-seq (length seq)) ; in Common Lisp (length ∅) -> 0
            )
        (cond
          ((∧ (¬ maxdex) (= 0 length-seq))
            [cont-empty]
            )
          (t
            (when (¬ maxdex) (setf maxdex (1- length-seq)))
            (setf
              (parms tape)
              (make-instance
                'tape-array-parms
                :name 'local
                :maxdex maxdex
                ))
            (let*(
                   (length-array (1+ maxdex))
                   (the-array
                     (make-array length-array
                       :element-type t
                       :adjustable ∅
                       :fill-pointer ∅
                       :displaced-to ∅
                       ))
                   )
              (setf (the-array tape) the-array)
              (cond
                ((≥ length-seq length-array)
                  (do
                    ((i 0 (1+ i)))
                    ((≥ i length-array))
                    (setf (aref the-array i) (elt seq i))
                    ))
                (t
                  (do
                    ((i 0 (1+ i)))
                    ((≥ i length-seq))
                    (setf (aref the-array i) (elt seq i))
                    )
                  (do
                    ((i length-seq (1+ i)))
                    ((≥ i length-array))
                    (setf (aref the-array i) ∅)
                    )))
              ); end let*
            [cont-ok]
            )))))
                
  (defun-typed init ((tape tape-array) (seq sequence) &optional ➜)
    (destructuring-bind
      (&key
        ;; parms ; to pass a parms in we need a parms dictionary to look the name up ..
        (➜ok #'echo)
        &allow-other-keys
        )
      ➜
      (init-parms-tape-array tape seq ➜
          (λ()
            (to-active tape)
            [➜ok tape]
            )
          (λ()
            (to-empty tape)
            [➜ok tape]
            )
        )))

  (defun-typed init ((tape-1 tape-array) (tape-0 tape-empty) &optional ➜)
    (destructuring-bind
      (&key
        (➜ok #'echo)
        &allow-other-keys
        )
      ➜
      (init-parms-tape-array tape-1 ∅ ➜
          ;; They are teasing us by handing us a null initializer and simultaneously
          ;; specifying an initial tape length.  We will set the intial tape to all ∅.
          (λ()
            (to-active tape-1)
            [➜ok tape-1]
            )
          (λ()
            (to-empty tape-1)
            [➜ok tape-1]
            )
          )))

  (defun-typed init ((tape-1 tape-array) (tape-0 tape-active) &optional ➜)
    (destructuring-bind
      (&key
        maxdex
        (➜ok #'echo)
        &allow-other-keys
        )
      ➜
      (cond
        ((∧ maxdex (≥ 0 maxdex)) ; if you spec maxdex, we do not share parms
          (setf
            (parms tape-1)
            (make-instance
              'tape-array-parms
              :name 'local
              :maxdex maxdex
              )))
          (t
            (setf (parms tape-1) (parms tape-0))
            (setf maxdex (maxdex (parms tape-0)))
            ))

      (setf (the-array tape-1)
        (make-array (1+ maxdex)
          :element-type t
          :adjustable ∅
          :fill-pointer ∅
          :displaced-to ∅
          ))
      (to-active tape-1)

      (labels(
               (init-2 (cell-1)
                 (w<cell> cell-1 ∅)
                 (right-neighbor cell-1
                   {
                     :➜rightmost #'do-nothing ; we are finished
                     :➜ok (λ(rn-1)(init-2 rn-1))
                     }))
               (init-1 (cell-1 cell-0)
                 (w<cell> cell-1 (r<cell> cell-0))
                 (right-neighbor cell-1
                   {
                     :➜rightmost #'do-nothing ; we are finished
                     :➜ok
                     (λ(rn-1)
                       (right-neighbor cell-0
                         {
                           :➜rightmost ; uh-oh ran out of initializer data
                           (λ()(init-2 rn-1))
                           :➜ok
                           (λ(rn-0)
                             (init-1 rn-1 rn-0)
                             )
                           }))}))
               (init-0 ()
                 (let(
                       (cell-1 (leftmost tape-1)) ; active tapes always have a leftmost
                       (cell-0 (leftmost tape-0)) ; active tapes always have a leftmost
                       )
                   (init-1 cell-1 cell-0)
                   ))
               )
        (init-0)
        )
      [➜ok tape-1]
      ))


;;--------------------------------------------------------------------------------
;; accessing instances
;;


;;--------------------------------------------------------------------------------
;; topology queries
;;
  (defun-typed =<cell> ((cell-0 cell-array) (cell-1 cell-array))
    (∧
      (eq  (tape cell-0)  (tape cell-1))
      (eql (index cell-0) (index cell-1))
      ))

  (defun-typed r<cell> ((cell cell-array))
    (let(
          (the-array (the-array (tape cell)))
          (index (index cell))
          )
      (aref the-array index)
      ))

  ;; Writing a zero into the rightmost tile makes the natural shorter.  But this is a cell
  ;; operation not a tape operation, so the outer tape operation will have to take this
  ;; into account.
  (defun-typed w<cell> ((cell cell-array) instance)
    (let(
          (the-array (the-array (tape cell)))
          (index (index cell))
          )
      (setf (aref the-array index) instance)
      ))

  (defun-typed leftmost ((tape tape-array-active) &optional ➜)
    (destructuring-bind
      (&key
        (➜ok #'echo)
        &allow-other-keys
        )
      ➜
      [➜ok 
        (make-instance 
          'cell-array
          :tape tape
          :index 0
          )]
      ))

  (defun-typed right-neighbor ((cell cell-array) &optional ➜)
    (destructuring-bind
      (&key
        (➜ok #'echo)
        (➜rightmost (λ()(error 'step-from-rightmost)))
        &allow-other-keys
        )
      ➜
      (let*(
             (tape  (tape  cell))
             (index (index cell))
             (parms (parms tape))
             (maxdex (maxdex parms))
             )
        (cond
          ((< index maxdex)
            [➜ok (make-instance 'cell-array :tape tape :index (1+ index))]
            )
          (t
            [➜rightmost]
            )))))


;;--------------------------------------------------------------------------------
;; topology manipulation
;;   no topology manipulation allowed for array
;; 


;;--------------------------------------------------------------------------------
;; length-tape
;;
   (defun-typed maximum-address ((tape tape-array-active) &optional ➜)
    (destructuring-bind
      (&key
        (➜ok #'echo)
        &allow-other-keys
        )
      ➜
      [➜ok (maxdex (parms tape))]
      ))
