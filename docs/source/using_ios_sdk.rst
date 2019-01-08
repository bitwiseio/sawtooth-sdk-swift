********************************************
Client: Building and Submitting Transactions
********************************************

The process of encoding information to be submitted to a distributed ledger is
generally non-trivial. A series of cryptographic safeguards are used to
confirm identity and data validity. Hyperledger Sawtooth is no different, but
the iOS SDK does provide client functionality that abstracts away
most of these details, and greatly simplifies the process of making changes to
the blockchain.


Creating a Private Key and Signer
=================================

In order to confirm your identity and sign the information you send to the
validator, you will need a 256-bit key. Sawtooth uses the secp256k1 ECDSA
standard for signing, which means that almost any set of 32 bytes is a valid
key. It is fairly simple to generate a valid key using the SDK’s signing module.

A *Signer* wraps a private key and provides some convenient methods for signing
bytes and getting the private key's associated public key.


**Swift**

.. code-block:: swift

    import SawtoothSigning

    let context = Secp256k1Context()
    let privateKey = context.newRandomPrivateKey()
    let signer = Signer(context: context, privateKey: privateKey)

.. note::

    This key is the **only** way to prove your identity on the blockchain. Any
    person possessing it will be able to sign Transactions using your identity,
    and there is no way to recover it if lost. It is very important that any
    private key is kept secret and secure.


Encoding Your Payload
=====================

    Transaction payloads are composed of binary-encoded data that is opaque to the
    validator. The logic for encoding and decoding them rests entirely within the
    particular Transaction Processor itself. As a result, there are many possible
    formats, and you will have to look to the definition of the Transaction
    Processor itself for that information. As an example, the *IntegerKey*
    Transaction Processor uses a payload of three key/value pairs encoded as
    `CBOR <https://en.wikipedia.org/wiki/CBOR>`_. Creating one might look like this:

**Swift**

.. code-block:: swift

    import SwiftCBOR

    let payload : CBOR = [
        "Verb": "set"
        "Name": "foo"
        "Value": 42
    ]
    payload.encode()


Building the Transaction
========================

*Transactions* are the basis for individual changes of state to the Sawtooth
blockchain. They are composed of a binary payload, a binary-encoded
*TransactionHeader* with some cryptographic safeguards and metadata about how
it should be handled, and a signature of that header. It would be worthwhile
to familiarize yourself with the information in  `Transactions and Batches
<https://sawtooth.hyperledger.org/docs/core/releases/latest/architecture/transactions_and_batches.html>`_,
particularly the definition of TransactionHeaders.


1. Create the Transaction Header
--------------------------------

A TransactionHeader contains information for routing a transaction to the
correct transaction processor, what input and output state addresses are
involved, references to prior transactions it depends on, and the public keys
associated with the its signature. The header references the payload through a
SHA-512 hash of the payload bytes.

**Swift**

.. code-block:: swift

    import CommonCrypto
    import os

    private func hash(item: String) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
        if let data = item.data(using: String.Encoding.utf8) {
            let value = data as NSData
            CC_SHA512(value.bytes, CC_LONG(data.count), &digest)
        }
        let digestHex = digest.map { String(format: "%02hhx", $0) }.joined()
        return digestHex
    }

    var transactionHeader = TransactionHeader()
    do {
        transactionHeader.signerPublicKey = try signer.getPublicKey().hex()
        transactionHeader.batcherPublicKey = try signer.getPublicKey().hex()
    } catch {
        os_log("Failed to get signer public key")
    }
    transactionHeader.familyName = "intkey"
    transactionHeader.familyVersion = "1.0"
    transactionHeader.inputs = ["1cf1266e282c41be5e4254d8820772c5518a2c5a8c0c7f7eda19594a7eb539453e1ed7"]
    transactionHeader.outputs = ["1cf1266e282c41be5e4254d8820772c5518a2c5a8c0c7f7eda19594a7eb539453e1ed7"]
    transactionHeader.payloadSha512 = hash(item: payload)
    transactionHeader.nonce = UUID().uuidString

.. note::

   Remember that a *batcher public key* is the hex public key matching the private
   key that will later be used to sign a Transaction's Batch, and
   *dependencies* are the *header signatures* of Transactions that must be
   committed before this one (see `TransactionHeaders
   <https://sawtooth.hyperledger.org/docs/core/releases/latest/
   architecture/transactions_and_batches.html>`_).

.. note::

   The *inputs* and *outputs* are the state addresses a Transaction is allowed
   to read from or write to. With the Transaction above, we referenced the
   specific address where the value of  ``'foo'`` is stored.  Whenever possible,
   specific addresses should be used, as this will allow the validator to
   schedule transaction processing more efficiently.

   Note that the methods for assigning and validating addresses are entirely up
   to the Transaction Processor. In the case of IntegerKey, there are `specific
   rules to generate valid addresses <https://sawtooth.hyperledger.org/docs/core/
   releases/latest/transaction_family_specifications/
   integerkey_transaction_family.html#addressing>`_, which must be followed or
   Transactions will be rejected. You will need to follow the addressing rules
   for whichever Transaction Family you are working with.


2. Create the Transaction
-------------------------

Once the TransactionHeader is constructed, its bytes are then used to create a
signature.  This header signature also acts as the ID of the transaction.  The
header bytes, the header signature, and the payload bytes are all used to
construct the complete Transaction.

**Swift**

.. code-block:: swift

    var transaction = Transaction()
    do {
        let transactionHeaderData = try transactionHeader.serializedData()
        transaction.header = transactionHeaderData
        let signatureData = transactionHeaderData.map {UInt8 (littleEndian: $0)}
        do {
            let signature = try signer.sign(data: signatureData)
            transaction.headerSignature = signature
        } catch {
            os_log("Unexpected error signing batch ")
        }
    } catch {
        os_log("Unable to serialize data")
    }
    transaction.payload = payloadData!


3. (optional) Encode the Transaction(s)
---------------------------------------

If the same machine is creating Transactions and Batches there is no need to
encode the Transaction instances. However, in the use case where Transactions
are being batched externally, they must be serialized before being transmitted
to the batcher. The Swift SDK offers two options for this. One or more
Transactions can be combined into a serialized *TransactionList* method, or can
be serialized as a single Transaction.

**Swift**

.. code-block:: swift

    var txn_list = TransactionList()
    txn_list.transactions = [txn1, txn2]
    do {
        let txn_list_bytes = try txn_list.serializedData()
        let txn_bytes = try txn.serializedData()
    } catch {
        os_log("Unable to serialize data")
    }


Building the Batch
==================

Once you have one or more Transaction instances ready, they must be wrapped in a
*Batch*. Batches are the atomic unit of change in Sawtooth's state. When a Batch
is submitted to a validator each Transaction in it will be applied (in order),
or *no* Transactions will be applied. Even if your Transactions are not
dependent on any others, they cannot be submitted directly to the validator.
They must all be wrapped in a Batch.


1. Create the BatchHeader
-------------------------

Similar to the TransactionHeader, there is a *BatchHeader* for each Batch.
As Batches are much simpler than Transactions, a BatchHeader needs only  the
public key of the signer and the list of Transaction IDs, in the same order they
are listed in the Batch.

**Swift**

.. code-block:: swift

    var batchHeader = BatchHeader()
    do {
        batchHeader.signerPublicKey = try signer.getPublicKey().hex()
    } catch {
        os_log("Failed to get signer public key")
    }
    batchHeader.transactionIds = transactions.map({ $0.headerSignature })


2. Create the Batch
-------------------

Using the SDK, creating a Batch is similar to creating a transaction.  The
header is signed, and the resulting signature acts as the Batch's ID.  The Batch
is then constructed out of the header bytes, the header signature, and the
transactions that make up the batch.

**Swift**

.. code-block:: swift

    var batch = Batch()
    do {
        let batchHeaderData = try batchHeader.serializedData()
        batch.header = batchHeaderData
        let signatureData = batchHeaderData.map {UInt8 (littleEndian: $0)}
        do {
            let signature = try signer.sign(data: signatureData)
            batch.headerSignature = signature
        } catch {
            os_log("Unexpected error signing batch")
        }
    } catch {
        os_log("Unable to serialize data")
    }
    batch.transactions = transactions


3. Encode the Batch(es) in a BatchList
--------------------------------------

In order to submit Batches to the validator, they  must be collected into a
*BatchList*.  Multiple batches can be submitted in one BatchList, though the
Batches themselves don't necessarily need to depend on each other. Unlike
Batches, a BatchList is not atomic. Batches from other clients may be
interleaved with yours.

**Swift**

.. code-block:: swift

    var batchList = BatchList()
    batchList.batches = [batch]
    do {
        let batchList_data = batchList.serializedData()
    } catch {
        os_log("Unable to serialize data")
    }

.. note::

   Note, if the transaction creator is using a different private key than the
   batcher, the *batcher public_key* must have been specified for every Transaction,
   and must have been generated from the private key being used to sign the
   Batch, or validation will fail.


Submitting Batches to the Validator
===================================

The prescribed way to submit Batches to the validator is via the REST API.
This is an independent process that runs alongside a validator, allowing clients
to communicate using HTTP/JSON standards. Simply send a *POST* request to the
*/batches* endpoint, with a *"Content-Type"* header of
*"application/octet-stream"*, and the *body* as a serialized *BatchList*.

There are a many ways to make an HTTP request, and hopefully the submission
process is fairly straightforward from here, but as an example in Swift, this is what it
might look if you sent the request from the same process that
prepared the BatchList.

**Swift**

.. code-block:: swift

    let postBatch = URL("http://rest.api.domain/batches")!
    var postUrlRequest = URLRequest(url: postBatch)
    postUrlRequest.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
    postUrlRequest.httpMethod = "POST"
    let postUrlRequest.httpBody = batchList_data

    URLSession.shared.dataTask(with: postUrlRequest) { (data, response, error) in
        if error != nil {
            os_log("%@", error!.localizedDescription)
        }
        guard data != nil else {
            return
        }
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 202 {
                os_log(response)
            }
        } else {
            return
        }
    }.resume()

And here is what it would look like if you saved the binary to a file, and then
sent it from the command line with ``curl``:

**Swift**

.. code-block:: swift

    let file = "intkey.batches"
    if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        let file_path = dir.appendingPathComponent(file)

        do {
            try batchList_data.write(to: file_path, atomically: false, encoding: .utf8)
        } catch {
            os_log("Unable to write to file")
        }
    }

.. code-block:: bash

   % curl --request POST \
       --header "Content-Type: application/octet-stream" \
       --data-binary @intkey.batches \
       "http://rest.api.domain/batches"
