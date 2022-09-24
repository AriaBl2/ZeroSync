# ZeroSync Roadmap

This is a rough writeup of the project's roadmap. Nothing here is set in stone. Subgoals change frequently as we're still exploring the solution space. This document is probably not even up to date as you read it. However, it gives you an idea of where we're currently heading.


## Milestone 1: *"assumevalid"*

The goal is a chain proof that mimics the ["assumevalid" option of Bitcoin Core](https://bitcoincore.org/en/2017/03/08/release-0.14.0/#assumed-valid-blocks). It parses the blocks and its transactions, validates the chain's work, its chain of hashes, and correctly manages the set of UTXOs. It also validates coin creation, the transaction amounts, and fees. It verifies mostly everything except for the signatures. (More precisely: it verifies no witness data.)

- ✅ Parse blocks, headers, and transactions
- ✅ Verify the chain of hashes (block hash, previous block hash, Merkle root, TXIDs)
- 👷‍♂️ Verify the chain's work (proof-of-work and difficulty retargeting)
- ✅ Verify the UTXO set (Utreexo accumulator and a "bridge node" to provide the inclusion proofs)
- 👷‍♂️ Chain of proofs with recursive STARKs: Verify the previous chain proof in the current chain proof


## Milestone 2: *"measure and optimise"* 

The goal is to measure the performance of chain proofs using *assumevalid*, and optimise it such that we can also add to it the validation of Bitcoin Scripts.

- Benchmark the *assumevalid proof* with blocks full of transactions
- Identify the performance bottlenecks and see if there are any showstoppers
- Optimise the bottlenecks such that we can continue with milestone 3


## Milestone 3: *"Bitcoin Script"*

- Bitcoin Script
	- Compute signature hashes (ALL, NONE, SINGLE, ANYONECANPAY, ... )
	- Script interpreter (All opcodes)
- Payment types
	- Legacy: p2pk, p2pkh, p2sh
	- SegWit: p2wpkh, p2wsh
	- Taproot: p2tr; key path & script path spend
- Crypto
	- ECDSA, Schnorr
	- SHA256, HASH256, SHA1, RIPEMD160, HASH160, ...
- Chain verifier
	- Download and prove a chainstate directory for a Bitcoin Core full node
	- Demo for state proof in web browser?


## Milestone 4: *zerosync and scan the chain efficiently*

- *Block filters* for light clients to quickly check if a block is relevant to them
- Compact blocks (compressed for light clients)
- Merklized headers chain
