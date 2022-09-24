# ZeroSync

**Don't trust. Verify.** ZeroSync allows to verify Bitcoin's chain state in within seconds. No need to download hundreds of gigabytes. A tiny STARK proof suffices to validate the entire blockchain and its resulting UTXO set.


Furthermore, ZeroSync aims to become a tool box for custom Bitcoin proofs. This enables you to transform the blockchain data, enhance it, filter it, generate indices for efficient queries, and adapt it to your individual use case. 



WARNING: THIS IS AN EARLY STAGE PROTOTYPE. THERE ARE MULTIPLE CRITCIAL SECURITY BUGS! EXPECT BREAKING CHANGES.


## Requirements
- Python 3.7
- Cairo [Installation Guide](https://www.cairo-lang.org/docs/quickstart.html) (Programming language for provable programs)
- [Protostar](https://docs.swmansion.com/protostar/docs/tutorials/installation) (Automated testing)
- [Giza](https://github.com/maxgillett/giza) (Required for prover. Not necessary for development and testing)

## Run all Tests

```sh
protostar test --cairo-path=./src target src
```


## Run the Utreexo Bridge Node
```sh
source ~/cairo_venv/bin/activate
python src/utreexo/bridge_node.py
```


## Run the Chain Prover
```sh
source ~/cairo_venv/bin/activate
mkdir tmp
```

```sh
python src/chain_proof/main.py
```

```sh
giza prove --trace=tmp/trace.bin --memory=tmp/memory.bin --program=tmp/program.json --output=tmp/proof.bin --num-outputs=12
```


