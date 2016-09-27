#|
Copyright (c) 2016 Thomas W. Lynch and Reasoning Technology Inc.
Released under the MIT License (MIT)
See LICENSE.txt

  Quantified operations.

|#

(in-package #:tm)

;;--------------------------------------------------------------------------------
;; repeated until end of tape operations
;;   more specific versions, if they exist, are surely more efficient
;;
  ;; if you want fill to be a single value, make it a singular-affine machine
  ;; cont-rightmost is called when the fill machine hits rightmost
  (defgeneric w* 
    (
      tm
      fill
      &optional
      cont-ok
      cont-rightmost-tm
      &rest ⋯
      )
    (:documentation
      "Reads fill, and writes tm, steps both, and repeats until fill passes rightmost;
       it then follows cont-ok.  Should tm hit rightmost first, then cont-rightmost-tm.
       "
      ))

  (defmethod w* 
    (
      (tm tape-machine)
      fill
      &optional 
      (cont-ok (be t))
      (cont-rightmost-tm (be ∅))
      &rest ⋯
      )
    (declare (ignore ⋯))
    (w tm (r fill))
    (⟳-loop(λ(cont-loop)
             (s fill
               (λ()(s tm
                     (λ()(w tm (r fill))(funcall cont-loop))
                     cont-rightmost-tm
                     ))
               cont-ok
               ))))

  (defgeneric s* (tm)
    (:documentation 
      "This is a synonym for cue-to-rightmost. There is no guarantee that intermediate
       cells will be visited."
      ))

  (defmethod s* ((tm tape-machine)) (cue-rightmost tm))

  (defgeneric -s* (tm)
    (:documentation 
      "This is a synonym for cue-to-leftmost. There is no guarantee that intermediate
       cells will be visited."
      ))

  (defmethod -s*((tm tape-machine))(cue-leftmost tm))

  ;; note the fill data will be reversed at the tm insert point
  ;; use as* to fill without reversal
  ;; use eas* to fill forward without moving tm (requires at least nd-tm)
  (defgeneric a* (tm fill &optional cont-ok cont-no-alloc)
    (:documentation 
      "Calls #'a repeatedly with successive objects from tm-fill. 
       tm will not be stepped.  tm-fill will be stepped.
       The sequence order as it is found on tm-fill will be reversed on tm.
       "      
      ))

  ;; cont-no-alloc is not transactional here ... need to fix the other a* versions too
  ;; do we want it to be transactional?  But if it did a spot fix it would have to be
  ;; possible to restart the a* where we left off ..
  (defmethod a*
    (
      (tm tape-machine)
      fill
      &optional
      (cont-ok (be t))
      (cont-no-alloc #'alloc-fail)
      )
    (⟳-loop
      (λ(cont-loop)
        (a tm (r fill) 
          (λ()(s fill cont-loop cont-ok))
          cont-no-alloc
          ))))

  (defgeneric as* (tm fill &optional cont-ok cont-no-alloc)
    (:documentation 
      "Calls #'as repeatedly with successive objects from tm-fill.
       Both tm and tm-fill will be stepped.
       "
      ))


  (defun as*-1
    (
      tm 
      fill
      &optional
      (cont-ok (be t))
      (cont-no-alloc #'alloc-fail)
      )
    (⟳-loop
      (λ(cont-loop)
        (as tm (r fill) 
          (λ()(s fill cont-loop cont-ok))
          cont-no-alloc
          ))))

  (defmethod as*
    (
      (tm0 tape-machine)
      fill
      &optional
      (cont-ok (be t))
      (cont-no-alloc #'alloc-fail)
      )
    (as*-1 tm0 fill cont-ok cont-no-alloc)
    )


;;--------------------------------------------------------------------------------
;; repeated by count operations
;;   more specific versions, if they exist, are surely more efficient
;;
  (defgeneric sn (tm n &optional cont-ok cont-rightmost)
    (:documentation 
      "Step n times.  When called, cont-rightmost is passed the current value of n.  For
       example, if the head is on leftmost, and the tape has two cells, and sn is called
       with n set to 3, then the step from rightmost continuation will be called with a
       value of 2.
      "
      ))

  (defmethod sn
    (
      (tm tape-machine)
      (n integer)
      &optional 
      (cont-ok (be t))
      (cont-rightmost (λ(n)(declare (ignore n)) ∅))
      )
    (⟳-loop(λ(cont-loop)
             (if
               (> n 0)
               (s tm
                 (λ()(decf n)(funcall cont-loop))
                 (λ()(funcall cont-rightmost n))
                 )
               (funcall cont-ok) 
               ))))


  (defgeneric asn (tm n &optional fill cont-ok cont-rightmost-fill cont-no-alloc)
    (:documentation 
      "Similar to calling #'as n times. fill provides initialization
       data. tm and fill are both stepped n times."
      ))

  ;; interesting that the fill iterator is one ahead, pointing at the next
  ;; thing to be written.  Thus this routine does not maintain inclusive bounds.
  (defmethod asn
    (
      (tm tape-machine)
      (n integer)
      &optional 
      fill
      (cont-ok (be t))
      (cont-rightmost-fill (λ(cnt)(declare (ignore cnt))∅))
      (cont-no-alloc (λ(tm n)(declare (ignore tm n))(error 'alloc-fail)))
      )
    (⟳-loop(λ(cont-loop)
             (if
               (> n 0)
               (as tm (r fill)
                 (λ()
                   (s fill 
                     (λ()(decf n) (funcall cont-loop)) 
                     (λ()(funcall cont-rightmost-fill n))
                     ))
                 cont-no-alloc
                 )
               (funcall cont-ok)
               ))))



