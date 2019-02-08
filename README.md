
![Hyperledger Sawtooth](https://raw.githubusercontent.com/hyperledger/sawtooth-core/master/images/sawtooth_logo_light_blue-small.png)

# Hyperledger Sawtooth SDK

*Hyperledger Sawtooth* is an enterprise solution for building, deploying, and
running distributed ledgers (also called blockchains). It provides an extremely
modular and flexible platform for implementing transaction-based updates to
shared state between untrusted parties coordinated by consensus algorithms.

The *Sawtooth Swift SDK* provides a number of useful components that simplify
developing Swift applications which interface with the Sawtooth platform.

## Installation

The Swift SDK's SawtoothSigning module can be imported to a Cocoa/Cocoa Touch
project via [Carthage](https://github.com/Carthage/Carthage), a dependency
manager for Cocoa applications.

1. Install Carthage using
[these installation instructions](https://github.com/Carthage/Carthage#installing-carthage).

2. Create a Cartfile in the same directory where your `.xcodeproj` or
`.xcworkspace` is.

3. In the Cartfile for your project, add:
  ```
  github "bitwiseio/sawtooth-sdk-swift" "master"
  ```

4. Run `carthage update`

  After the framework is downloaded and built, it can be found at
  `path/to/your/project/Carthage/Build/<platform>/SawtoothSigning.framework`

5. Add the built .framework binaries to the Embedded Binaries and Linked
Frameworks and Libraries sections in your Xcode project.

## Capabilities

- Generate private/public key pairs
- Sign transactions
- Verify signatures

  ###### Example

  ```
  import SawtoothSigning

  let context = Secp256k1Context()
  let privateKey = context.newRandomPrivateKey()
  let signer = Signer(context: context, privateKey: privateKey)
  let signature = signer.sign(data: message_bytes)
  context.verify(signature: signature, data: message_bytes,
    publicKey: signer.getPublicKey())
  ```

For full usage information, please refer to the Swift SDK documentation
included in this repository.


## Documentation

To generate the Swift SDK documentation from source:
1. Install [sphinx](http://www.sphinx-doc.org/en/master/).
  ```
  pip install -U Sphinx
  ```
2. Install the sphinx theme used by the Sawtooth documentation using pip.
  ```
  pip install sphinx_rtd_theme
  ```
3. In the `sawtooth-sdk-swift/docs` directory run
  ```
  make html
  ```

  Sphinx generates the documentation and puts it in the folder
  `sawtooth-sdk-swift/docs/_build`.

4. To open the index file, run
  ```
  open _build/html/index.html
  ```

For more information, please see the
[Hyperledger Sawtooth documentation](https://sawtooth.hyperledger.org/docs/),
especially the
[Application Developer's Guide](https://sawtooth.hyperledger.org/docs/core/releases/latest/app_developers_guide.html).

License
-------
Hyperledger Sawtooth software is licensed under the
[Apache License Version 2.0](LICENSE) software license.
