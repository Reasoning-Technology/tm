#|

Copyright (c) 2016 Thomas W. Lynch and Reasoning Technology Inc.
Released under the MIT License (MIT)
See LICENSE.txt

|#


(in-package :asdf-user)

(defsystem #:tm
  :name "tm"
  :version "0.5"
  :author "Thomas W. Lynch <thomas.lynch@reasoningtechnology.com>"
  :description "Formalized Iteration Library for Common LISP"
  :license "MIT License"
  :depends-on ("local-time" "trivial-garbage" "bordeaux-threads")
  :serial t
  :components(
               (:module "package-def"
                 :components (
                               (:file "package")
                               (:file "conditions")
                               ))

               (:module "src-0"
                 :components (
                               (:file "synonyms")
                               (:file "list-qL")
                               (:file "reader-macros")
                               (:file "functions")
                               ))

               (:module "src-test"
                 :components (
                               (:file "test")
                               ))

               (:module "test-0"
                 :components (
                               (:file "list-qL")
                               (:file "functions")
                               ))

               (:module "src-list" ; both the list and generic interface
                 :components (
                               (:file "tm-type")
                               (:file "tm-decl-only")
                               (:file "tm-generic")
                               (:file "tm-quantifiers")
                               (:file "tm-quantified")
;;                               (:file "tm-print")

                               (:file "list-tm-type")
                               (:file "list-tm-definitions")
                               (:file "list-tm-specialized-generic")

                               ;; no destructive functions, but has entangled copy functions
                               (:file "nd-tm-type")
                               (:file "nd-tm-decl-only")
                               (:file "nd-tm-generic") 

                               (:file "nd-tm-quantified")

                               (:file "list-nd-tm-type")
                               (:file "list-nd-tm-definitions")

                               ;; includes destructive functions, but no entangled copy functions
                               (:file "solo-tm-type")
                               (:file "solo-tm-decl-only")
                               (:file "solo-tm-quantified")

                               ;; a solo-tm implemenation
                               (:file "list-solo-tm-type")
                               (:file "list-solo-tm-definitions")

                               ;; this machine must be managed
                               (:file "haz-tm-type")
                               (:file "list-haz-tm-type")

                               ;; bi-directional list, support -s
                               (:file "bilist")
                               (:file "bilist-tm-type")
                               (:file "bilist-tm-definitions")
                               (:file "bilist-nd-tm-type")
                               (:file "bilist-nd-tm-definitions")
                               (:file "bilist-solo-tm-type")
                               (:file "bilist-solo-tm-definitions")
                               (:file "bilist-haz-tm-type")

;;                               (:file "nd-tm-subspace") ; issues with 'manifold'
;;                               (:file "tm-subspace")
;;                               (:file "convert")

                               ))

               (:module "test-list"
                :components (
                              ;; generic interface tests
                              (:file "bilist")
                              (:file "list-nd-tm-definitions")
                              (:file "list-solo-tm-definitions")
                              (:file "list-tm-definitions")
                              (:file "nd-tm-generic")
                              (:file "nd-tm-quantified")
                              (:file "nd-tm-quantifiers")
                              (:file "solo-tm-quantified")
                              (:file "tm-generic")
                              (:file "tm-quantified")
                              (:file "tm-quantifiers")
                              ))

               (:module "src-tr"
                 :components (
                               (:file "identity")
                               ))

               (:module "test-tr"
                :components (
                              (:file "identity")
                              ))

               (:module "src-second-order"
                 :components (
                               (:file "status-type")
                               (:file "status-definitions")
                               (:file "status-abandoned")
                               (:file "status-empty")
                               (:file "status-parked")
                               (:file "status-active")

                               (:file "ea-type")
                               (:file "ea-definitions")
                               (:file "ea-empty")
                               (:file "ea-parked")
                               (:file "ea-active")

                               (:file "ea2-type")
                               (:file "ea2-definitions")
                               (:file "ea2-empty")
                               (:file "ea2-parked")
                               (:file "ea2-active")

                               (:file "ts1-type")
                               (:file "ts1-definitions")
                               (:file "ts1-empty")
                               (:file "ts1-parked")
                               (:file "ts1-active")
                               ))

               (:module "test-second-order"
                 :components (
                               (:file "status")
                               (:file "ea")
                               (:file "ts1")
                               ))


#|

               (:module "src-generators" 
                 :components (
                               (:file "length")
                               (:file "location")
                               (:file "tm-DE")
                               ))




               (:module "test-generators"
                :components (
                              (:file "length")
                              (:file "location")

                             (:file "tm-DE")

                              ))

|#

#|


               (:module "src-array"
                :components (

                              (:file "worker")
                              (:file "worker-utilities")

                              (:file "tm-array-adj-mk")
                              (:file "tm-array-adj-primitives")
                              (:file "tm-array-adj-derived")
                              (:file "tm-array-adj-convert")

                              (:file "tm-array-mk")
                              (:file "tm-array-primitives")
                              (:file "tm-array-derived")
                              (:file "tm-array-convert")

                              (:file "tm-aggregate-mk")
                              (:file "tm-aggregate-primitives")

                              (:file "access-lang")
                              ))

               (:module "test-2"
                 :components (
                               (:file "worker")
                               (:file "tm-array-adj")
                               (:file "tm-aggregate")
                               (:file "access-lang")
                               ))
|#
               ))
  
  



