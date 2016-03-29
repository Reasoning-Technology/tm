#|
Copyright (c) 2016 Thomas W. Lynch and Reasoning Technology Inc.
Released under the MIT License (MIT)
See LICENSE.txt

  note (adjustable-array-p a) for checking if an array is adjustable
  this may be needed as (type-of an-array) just returns (vector T size)
  both are also (typep a 'array).

  (array dimension d 0) returns allocation length for 0 dimension of array d, while
  (length d) returns the fill pointer for vector d, as does (fill-pointer d).

.. the new tm-mk approach makes the tm-init initialized from sequence code look a bit
funny .. also probably should remove the initialization of tm-array so as not to
duplicate computation when tape is set explicitly.

|#

(in-package #:tm)

;;--------------------------------------------------------------------------------
;; a specialization
;;
  ;; head will be the index, tape the array proper
  (defclass tm-array (tape-machine))


;;--------------------------------------------------------------------------------
;;
  (defmethod tm-init
    (
      (i tm-array)
      &optional 
      init
      (cont-ok #'echo) 
      (cont-fail 
        (λ() (error 'tm-mk-bad-init-type :text "unrecognized array tape type") ∅)
        ))
    (cond
      ((typep init 'sequence)
        (funcall cont-ok
          (make-instance 'tm-array 
            :tape (make-array 
                    (length init) 
                    :initial-contents init
                    ))))
      (t
        (funcall cont-fail)
        )))

  ;; need to share this between adjustable and fixed arrays,
  ;; as both will come through (sequence 'array)
  ;;
    (defmethod mount
      (
        (sequence array) 
        &optional
        (cont-ok #'echo)
        (cont-fail 
          (λ() (error 'tm-mk-init-failed :text "unrecognized array tape type"))
          ))
      (unless (adjustable-array-p sequence) ; temporary until the fixed array is implemented
        (funcall cont-fail)
        )
      (let(
            (instance (make-instance 'tm-array))
            )
        (tm-init instance sequence cont-ok cont-fail)
        ))
 
  