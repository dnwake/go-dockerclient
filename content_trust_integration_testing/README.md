# docker_notary_demo

Description
===========

Tests the modified Docker client code for Docker Content Trust functionality.

Three scenarios are tested:


"Bad" scenario (negative test)
------------------------------

To invoke this scenario, run "make test_bad".

* Docker content trust is disabled on Kubernetes.  
* The Docker registry is deliberately corrupted so that the "bad" image is
   returned when the "good" image is requrested.
* We expect the "bad" image to be run by Kubernetes.


"Good" scenario (negative test)
------------------------------

To invoke this scenario, run "make test_good".

* Docker content trust is enabled on Kubernetes.  
* The Docker registry is not corrupted.
* We expect the "good" image to be run by Kubernetes.


"Error" scenario (positive test)
------------------------------

To invoke this scenario, run "make test-error".

* Docker content trust is enabled on Kubernetes.  
* The Docker registry is corrupted.
* We expect Kubernetes to fail to load the image because of the manifest mismatch
** You will see the kubectl command wait forever.
** This can be verified by searching for the string "manifest unknown" in 
    /tmp/kubelet.log on the Kubernetes container.


Requirements
============

* Docker (1.10 +)
* Docker-compose
* git
* make
* bash


To invoke
=========

* make -s all


To debug
========

Try running without the -s flag:

* make all

Docker containers
-----------------

The following containers should be running at the end of the test:

* Image: client_image; Name: client_container; Function: Pulls the good /bad images and tests them.
* Image: client_image; Name: image_pusher; Function: pushes the good, bad and corrupted images to the registry container.
* Image: registry_image; Name: registry_container; Function: Docker Registry v2
* Image: notary_notaryserver; Name: notary_notaryserver_1; Function: Notary server
* Image: notary_notarysigner; Name: notary_notarysigner_1; Function: Notary signer (used by Notary server)
* Image: notary_notarymysql; Name: notary_notarymysql_1; Function: MySQL DB (used by Notary server and signer)
