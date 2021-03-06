#|

Copyright (c) 2016 Thomas W. Lynch and Reasoning Technology Inc.
Released under the MIT License (MIT)
See LICENSE.txt


|#

(in-package #:tm)

;;--------------------------------------------------------------------------------
;; 
  (define-condition cant-happen (error)
    ((text :initarg :text :reader text)))


;;--------------------------------------------------------------------------------
;; list-L
;;
  ;; the tm:o function may only be used inside of L (or [])
  (define-condition use-of-o (error)
    ((text :initarg :text :reader text)))

;;--------------------------------------------------------------------------------
;; mk
;;
  (define-condition bad-init-value (error)
    ((text :initarg :text :reader text)))

;;--------------------------------------------------------------------------------
;; src-1
;;
  (define-condition alloc-fail (error)
    ((text :initarg :text :reader text)))
  (define-condition accessed-empty (error)
    ((text :initarg :text :reader text)))

  (define-condition no-parent (error)
    ((text :initarg :text :reader text)))
  (define-condition bad-channel (error)
    ((text :initarg :text :reader text)))
  (define-condition bad-parent (error)
    ((text :initarg :text :reader text)))


;;--------------------------------------------------------------------------------
;; src-tape
;;
  (define-condition use-of-abandoned (error)
    ((text :initarg :text :reader text)))

  ;; we have abstracted to potentially multiple neighbors, so -n steps is unclear
  (define-condition accessed-parked (error)
    ((text :initarg :text :reader text)))

  (define-condition out-of-bounds-start-point (error)
    ((text :initarg :text :reader text)))

  (define-condition zero-direction (error)
    ((text :initarg :text :reader text)))

;;--------------------------------------------------------------------------------
;; src-tape-machine
;;
  (define-condition out-of-bounds (error)
    ((text :initarg :text :reader text)))

  (define-condition dealloc-on-rightmost (error)
    ((text :initarg :text :reader text)))

  (define-condition left-dealloc-on-leftmost (error)
    ((text :initarg :text :reader text)))

  (define-condition dealloc-collision (error)
    ((text :initarg :text :reader text)))

  (define-condition dealloc-last (error)
    ((text :initarg :text :reader text)))

  (define-condition dealloc-parked (error)
    ((text :initarg :text :reader text)))

;;--------------------------------------------------------------------------------
;; quantifiers
;;
  (define-condition non-function-continuation (error)
    ((text :initarg :text :reader text)))

;;--------------------------------------------------------------------------------
;; tm second level

  ;; machine was abandoned to the garbage collector, but someon uses it
  (define-condition operation-on-abandoned (error)
    ((text :initarg :text :reader text)))

  (define-condition accessed-empty (error)
    ((text :initarg :text :reader text)))

  ;; the head is parked, but someone tries to read or write through it
  (define-condition access-through-parked-head (error)
    ((text :initarg :text :reader text)))

  (define-condition negative-address (error)
    ((text :initarg :text :reader text)))
 

;;--------------------------------------------------------------------------------
;; dataflow
;;
  (define-condition not-ready (error)
    ((text :initarg :text :reader text)))

;;--------------------------------------------------------------------------------
;; buffers
;;
  (define-condition dequeue-from-empty (error)
    ((text :initarg :text :reader text)))

;;--------------------------------------------------------------------------------
;; worker
;;
  ;; nothing has been allocated at this location
  (define-condition worker-must-have-src-or-dst (error)
    ((text :initarg :text :reader text)))

;;--------------------------------------------------------------------------------
;; worker-utilities
;;
  (define-condition binner-no-such-bin (error)
    ((text :initarg :text :reader text)))

;;--------------------------------------------------------------------------------
;; tm-aggregate
;;
  ;; nothing has been allocated at this location
  (define-condition object-not-tape-machine (error)
    ((text :initarg :text :reader text)))



;;--------------------------------------------------------------------------------
;; access lang
;;
  (define-condition Δ-malformed-access-program (error)
    ((text :initarg :text :reader text)))

  (define-condition Δ-unrecognized-command (error)
    ((text :initarg :text :reader text)))

  (define-condition Δ-required-arg-missing (error)
    ((text :initarg :text :reader text)))
  
