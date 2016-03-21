#|
Copyright (c) 2016 Thomas W. Lynch and Reasoning Technology Inc.
Released under the MIT License (MIT)
See LICENSE.txt

  The machine's tape has been weaved through a tree.

|#

(in-package #:tm)

;;--------------------------------------------------------------------------------
;;  tape machine follows a depth first traversal of a tree
;;
  (defclass tm-depth (tm-tape-machine)())

  (defun tm-mk-depth
    (
      &optional 
      init
      (cont-ok #'echo) 
      (cont-fail 
        (λ() (error 'tm-mk-bad-init-type :text "unrecognized list tape type"))
        ))
    (let(
          (i (make-instance 'tm-depth-list))
          )
      (init-tm-list i init cont-ok cont-fail)
      (setf (history i) (mk-stack-list))
      i
      ))
  (tm-mk-hook 'tm-depth-list #'tm-mk-depth-list)


  ;; When stepping from a sublist, we step into the sublist to its first object.  We stack
  ;; the tm of the sublist so that we can return to the sublist and step over it later.
  ;;
  ;; The history buffer should be a stack for depth first.  If it is made a queue, we
  ;; shave off elements at the front of each node.  Going the depth on all first elements,
  ;; walking right, then second elements, etc.
  ;;
  ;; Between steps, destructive oeprations must preserve the nodes that are actively
  ;; descended into, other changes are legal. As examples appending or prepending to
  ;; nodes, or modifying cell values.  If new sublists are added that have not yet
  ;; been stepped to, then they will be stepped to when they are gotten to.
  ;;
  ;; Any parallel traversals, for example, for map, must taken into account that
  ;; deque-sublist is recursive until a tm is found that is not on rightmost and can thus
  ;; be stepped forward (to step over the sublist just traversed).  It would be possible
  ;; to avoid this recursive unwinding by not stacking tm points unless they have
  ;; rightmost, but this is not as friendly to tree modifications between steps. There
  ;; could be a long time betweeen stacking a tm and getting back to it.  Perhaps we
  ;; should provide two versions for s-depth, one constant time but not as malable between
  ;; steps, the other more malable but has that recursive unwind.
  ;;
    (defun s-depth-ru ; ru = recursive unwind
      (
        tm
        history
        &optional
        (cont-so (be 'so))
        (cont-si (be 'si))
        (cont-rightmost (be 'rightmost))
        (cont-dequeue (be 'dequeue))
        )
      (labels
        (

          (save-and-step-in() ; a saved traversal point is always one past a sublist
            (enqueue history (dup tm)) ; for later traversal from
            (si tm 
              cont-si
              (λ()
                (error 'tm-impossible-to-get-here 
                  :text "save-and-step-in is called after a consp check on tm"
                  ))
              ))

          (dequeue-sublist()
            (dequeue history
              (λ(tm0) 
                (so tm0 ; step past the sublist we just descended into
                  (λ()
                    (cue-to tm tm0)
                    (funcall cont-dequeue)
                    )
                  #'dequeue-sublist ; can't repeat for more than the levels in the tree
                  ))
              cont-rightmost ; there were no saved traversal points to continue from
              ))
          )

        (if (consp (r tm)) ; then it is a sublist
          (save-and-step-in) 
          (so tm cont-so #'dequeue-sublist)
          )))

    (defmethod s
      (
        (tm tm-depth)
        &optional
        (cont-ok (be t))
        (cont-rightmost (be ∅))
        )
      (labels(
               (step-depth()
                 (s-depth-ru
                   tm
                   (history tm)
                   cont-ok
                   cont-ok
                   cont-rightmost
                   cont-ok
                   ))
               )
        (step-depth)
        ))


;;--------------------------------------------------------------------------------
;;  tape machine follows a breadth first traversal of a tree
;;
  (defclass tm-breadth (tm-tree)())

  (defclass tm-breadth-list (tm-breadth tm-list)())

  ;; temporary, init needs a set-by-caller flag ...
  (defun tm-mk-breadth-list (&optional init buffer-tm)
    (declare (ignore buffer-tm))
    (let(
          (i (make-instance 'tm-breadth-list))
          )
      (init-tm-list i init)
      (setf (history i) (mk-queue-list))
      i
      ))
  (tm-mk-hook 'tm-beadth-list #'tm-mk-breadth-list)



  ;; When stepping from a sublist, we step over the sublist to the next object.
  ;; We queue the sublist so that we can go back to it and traverse through it later.
  ;;
  ;; The history buffer should be a queue.  If it is made a stack we get a depth
  ;; first search along the right side of the tree, instead of along the left.
  ;;
  ;; Between steps, atoms in the tree may be deleted, and sublists or atoms added, as
  ;; long as it is possible to still take a correct next step (whatever that step is
  ;; now supposed to be) from the cell under the head.  For list structures this means
  ;; that (cdr (HA tm)) must be valid.
  ;;
    (defun s-breadth 
      (
        tm
        history
        &optional
        (cont-so (be 'so))
        (cont-si (be 'si))
        (cont-rightmost (be 'rightmost))
        )
      (labels
        (
          
          (save-sublist ()
            (enqueue history (dup tm))
            )
          
          (dequeue-and-step-in ()
            (dequeue history
              (λ(tm0)
                (cue-to tm tm0)
                (si 
                  tm 
                  cont-si
                  (λ()(error 'tm-impossible-to-get-here :text "we only save lists"))
                  )
                )
              cont-rightmost ; there were no sublists to explore
              ))
          
          )
        (when (consp (r tm)) (save-sublist)) ; queue for later stepping into
        (so 
          tm
          cont-so
          #'dequeue-and-step-in
          )
        ))

    (defmethod s
      (
        (tm tm-breadth)
        &optional
        (cont-ok (be t))
        (cont-rightmost (be ∅))
        )
      (s-breadth
        tm
        (history tm)
        cont-ok
        cont-ok
        cont-rightmost
        ))


