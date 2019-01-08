Overview
========

This tutorial shows how to use the Sawtooth iOS SDK to develop a
client. The client is responsible for creating and signing transactions, combining
those transactions into batches, and submitting them to the validator. The
client can post batches through the REST API or connect directly to the
validator via `ZeroMQ <http://zeromq.org>`_.

.. note::

   This tutorial demonstrates the relevant concepts for a Sawtooth
   client, but does not create a complete implementation.

.. Licensed under Creative Commons Attribution 4.0 International License
.. https://creativecommons.org/licenses/by/4.0/
