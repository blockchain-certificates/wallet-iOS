# wallet
[![Build Status](https://travis-ci.org/blockchain-certificates/wallet-iOS.svg?branch=master)](https://travis-ci.org/blockchain-certificates/wallet-iOS)


Blockcerts mobile app for iOS to receive and share certificates that are verifiable via the blockchain.

## Blockcerts Libraries

### Cert-verifier-js
* Javascript library for verifying Blockcerts Certificates

#### Updating cert-verifier-js to a new version

Pull down the cvjs repository: 

```
https://github.com/blockchain-certificates/cert-verifier-js.git && cd cert-verifier-js
```

CVJS requires an npm token, so create one on [npm](https://docs.npmjs.com/creating-and-viewing-authentication-tokens)

```
export NPM_TOKEN={insert token here}
```

Install

```
npm install
```

Generate build

```
npm run-script build
```

Copy content of `/dist/verifier-iife.js`

Paste in this wallet-iOS project at this location: `wallet-iOS/wallet/Verification/verifier.js`


## Contact

Contact us at [the Blockcerts community forum](http://community.blockcerts.org/).

