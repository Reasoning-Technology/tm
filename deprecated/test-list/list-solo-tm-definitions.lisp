#|
Copyright (c) 2016 Thomas W. Lynch and Reasoning Technology Inc.
Released under the MIT License (MIT)
See LICENSE.txt

  All tests have names of the form test-fun-n  where fun is the function
  or logical concept being tested.

|#
(in-package #:tm)

(defun test-epa-0 ()
  (let*(
         (tm0 (mk 'list-solo-tm {:tape {1 2 3}}))
         )
    (∧
      (s tm0)
      (epa tm0 7)
      (equal (tape tm0) {7 1 2 3})
      (¬ (on-leftmost tm0))
      )))
(test-hook test-epa-0)

(defun test-d-0 ()
  (let*(
         (tm0 (mk 'list-solo-tm {:tape {1 2 3 4}}))
         (tm1 (mk 'list-solo-tm {:tape {-100}}))
         )
    (∧
      (s tm0)
      (d tm0 tm1)
      (equal (tape tm0) {1 2 4})
      (equal (tape tm1) {-100 3})
      (= (r tm0) 2)
      (= (r tm1) 3)
      (¬ (on-rightmost tm0))
      (d tm0)
      (equal (tape tm0) {1 2})
      (on-rightmost tm0)
      (= (d tm0 ∅ {:➜ok (be -1) :➜rightmost (be -2) :➜no-alloc (be -3)}) -2)
      (equal (tape tm0) {1 2})
      (on-rightmost tm0)
      (-s* tm0)
      (d tm0)
      (on-rightmost tm0)
      (on-leftmost tm0)
      (= (d tm0 ∅ {:➜ok (be -1) :➜rightmost (be -2) :➜no-alloc (be -3)}) -2)
      )))
(test-hook test-d-0)

(defun test-epd-0 ()
  (let*(
         (tm0 (mk 'list-solo-tm {:tape {1 2 3}}))
         (tm1 (mk 'list-solo-tm {:tape {-100}}))
         )
    (∧
      (s tm0)
      (¬ (on-leftmost tm0))
      (epd tm0 tm1)
      (equal (tape tm0) {2 3})
      (equal (tape tm1) {-100 1})
      (= (r tm0) 2)
      (= (r tm1) 1)
      (on-leftmost tm0)
      (on-rightmost tm1)
      (eq (epd tm0 ∅ {:➜ok (be 'ok) :➜no-alloc (be 'na) :➜collision (be 'c)}) 'c)
      )))
(test-hook test-epd-0)

(defun test-epd-1 ()
  (let*(
         (tm1 (mk 'list-solo-tm {:tape {1 2 3 'end}}))
         (tm2 (mk 'list-solo-tm {:tape {0}}))
         )
    (∧
      (s tm1)
      (epd tm1 tm2)
      (s tm1)
      (epd tm1 tm2)
      (s tm1)
      (epd tm1 tm2)
      (¬ (s tm1))
      (= (r tm2) 3)
      (-s* tm2)
      (= (r tm2) 0)
      (s tm2)
      (= (r tm2) 1)
      (s tm2)
      (= (r tm2) 2)
      (s tm2)
      (= (r tm2) 3)
      (¬ (s tm2))
      )
    ))
(test-hook test-epd-1)
