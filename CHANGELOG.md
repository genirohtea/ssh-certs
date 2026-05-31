# Changelog

## [1.2.0](https://github.com/genirohtea/ssh-certs/compare/v1.1.0...v1.2.0) (2026-05-31)


### Features

* **ssh agent:** support certifying keys that are in an ssh-agent ([3284775](https://github.com/genirohtea/ssh-certs/commit/328477584eb98da14437444965b8e8b4cc925c13))

## [1.1.0](https://github.com/genirohtea/ssh-certs/compare/v1.0.0...v1.1.0) (2024-09-03)


### Features

* **ansible scripts:** added ssh based pass auth flag defaulting to host key auth ([3c6f1ae](https://github.com/genirohtea/ssh-certs/commit/3c6f1aed069563be8510bce0eef2a138692cbe1a))
* **azure:** factored out azure secret retrieval in preparation for bws ([0dfde9b](https://github.com/genirohtea/ssh-certs/commit/0dfde9b2783732881e17a4b1bbf2e5194c1a44e6))
* **bitwarden secrets:** added matching secret creation implementation for bitwarden secrets manager ([3bc778f](https://github.com/genirohtea/ssh-certs/commit/3bc778f1a7054f18dd2d6c26334867ca25130769))
* **bws:** added bws implementation as default secret retrieval ([c913f03](https://github.com/genirohtea/ssh-certs/commit/c913f03ec4618573fe1d63c6b242630cdfab42cd))


### Bug Fixes

* **cert signing:** fixed case where the new cert would not be created due to existing cert ([5806d67](https://github.com/genirohtea/ssh-certs/commit/5806d67836575177c91e0fbf4e68b8fcab9b505f))

## 1.0.0 (2024-08-11)


### Features

* **ansible:** added ansible playbooks to sign + use ssh CAs on workstations and servers ([040e069](https://github.com/genirohtea/ssh-certs/commit/040e0694e810ea195f72f1cfefc6f3664488dfcf))
* **azure vault:** added terraform generation of SSH CA keys ([69830b6](https://github.com/genirohtea/ssh-certs/commit/69830b693327e48cd6a8f3cb7b77aec065209528))
* **github template:** initialized repo with 1.1 github template ([1912e50](https://github.com/genirohtea/ssh-certs/commit/1912e50fa3cbad9cf5ecaf9dd90fda2ffdfa7ad0))


### Bug Fixes

* **host key:** fixed issue where ansible would not create cert due to existing file ([d37d55f](https://github.com/genirohtea/ssh-certs/commit/d37d55f71d61cf01c3966e0c84693434b63f4c24))
