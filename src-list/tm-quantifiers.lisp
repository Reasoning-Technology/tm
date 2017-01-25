#|
Copyright (c) 2016 Thomas W. Lynch and Reasoning Technology Inc.
Released under the MIT License (MIT)
See LICENSE.txt

  Quantification

  Note the true and false continuations are not optional on pred.

  continuation arguments the existential and universl quantification are
  given in the argument list

|#

(in-package #:tm)

;;--------------------------------------------------------------------------------
;; looping, see also s-together⟳  --> need to replace these with quantifiers
;;
  (defun ⟳ (work &rest ⋯)
    "⟳ (pronounced \"do\") accepts a 'work' function and arguments. work may be a nameless
     lambda. ⟳ prepends a value to the argument list and calls work.  When the prepended
     value is called with funcall, work is called again with the same arguments.
     "
    (labels(
             (again() (apply work (cons #'again ⋯)))
             )
      (again)
      ))

;;--------------------------------------------------------------------------------
;; trivial predicates 
;;
  (defun always-false (tm ➜t ➜∅)
    (declare (ignore tm ➜t))
      [➜∅]
      )

  (defun always-true (tm ➜t ➜∅)
    (declare (ignore tm ➜∅))
      [➜t]
      )

;;--------------------------------------------------------------------------------
;; quantification
;;
;; careful:
;;
;; The quantifiers start where the head is located, they do not cue-leftmost first.  I do
;; this so that prefix values may be processed before calling a quantifier.
;;
;; I pass to the predicate the entire tape machine, rather than just the instance in the
;; cell the head is on.  I do this so that predicates may use the head as a general marker
;; on the tape, for example, as the origin for a sliding window.
;;
;; pred is a function that accepts a machine and two continuations, ➜t, and ➜∅.
;;
  (defun ∃ (tm pred &optional (➜t (be t)) (➜∅ (be ∅)))
    "Tests each instance in tm in succession starting from the current location of the head.
     Exits via ➜t upon the test passing.  Otherwise steps and repeats. Exits via
     ➜∅ when stepping right from rightmost.  The head is left on the cell that holds the
     instance that passed.
    "
    (⟳(λ(again)[pred tm ➜t (λ()(s tm {:➜ok again :➜rightmost ➜∅}))]))
    )

  ;; there does not exist an instance for which pred is false
  ;; pred is true for all instances
  (defun ∀ (tm pred &optional (➜t (be t)) (➜∅ (be ∅)))
    "➜t when all instances on the tape pass the test, otherwise ➜∅, head left on cell with first failed test."
    (∃ tm (λ(tm ct c∅)[pred tm c∅ ct]) ➜∅ ➜t)
    )

  ;; similar to ∃, but tests every instance.  Returns a number pair, the total tests done
  ;; (= length of tape tail), and the number of tests that returned true.
  (defun ∃* (tm pred)
    "Calls (pred tm ➜t ➜∅), and steps head, until reaching the end fo the tape, returns
     number pair: (true.count.false-count)."
    (let (
           (true-count 0)
           (false-count 0)
           )
      (⟳(λ(again)
          [pred tm
            (λ()(incf true-count))
            (λ()(incf false-count))
            ]
          (s tm
            {
              :➜ok again
              :➜rightmost #'do-nothing
              }
            )))
      (cons true-count false-count)
      ))

  (defun ∀* (tm function)
    "Calls (function tm), and steps head, until reaching the end of the tape. Returns
     nothing."
    (⟳(λ(again)
        [function tm]
        (s tm
          {
            :➜ok again
            :➜rightmost #'do-nothing
            }
          ))))

