mod tests {
    use serde::{Deserialize, Serialize};
    use std::fs::File;
    use std::io::{BufReader, Read};

    use winter_air::DefaultEvaluationFrame;
    use winter_crypto::{hashers::Blake2s_256, RandomCoin};
    use winter_utils::{Deserializable, Serializable, SliceReader};
    use winterfell::{Air, AuxTraceRandElements, StarkProof, VerifierChannel, VerifierError};

    use giza_air::{ProcessorAir, PublicInputs};
    use giza_core::Felt;

    // TODO: Use workspace so we can share code with parser package, and not duplicate here.
    // We can also convert these tests to exported Python-callable functions, that return
    // "ground truth" values for use in Protostar tests.
    #[derive(Serialize, Deserialize)]
    struct BinaryProofData {
        input_bytes: Vec<u8>,
        proof_bytes: Vec<u8>,
    }

    impl BinaryProofData {
        fn from_file(file_path: &String) -> BinaryProofData {
            let file = File::open(file_path).unwrap();
            let mut data = Vec::new();
            BufReader::new(file)
                .read_to_end(&mut data)
                .expect("Unable to read data");
            bincode::deserialize(&data).unwrap()
        }
    }

    #[test]
    fn draw_felt() {
        // TODO
    }

    #[test]
    fn draw_integers() {
        // TODO
    }

    #[test]
    fn draw_ood_point_z() -> Result<(), VerifierError> {
        let path = String::from("tests/stark_proofs/fibonacci.bin");

        let data = BinaryProofData::from_file(&path);
        let proof = StarkProof::from_bytes(&data.proof_bytes).unwrap();
        let pub_inputs =
            PublicInputs::read_from(&mut SliceReader::new(&data.input_bytes[..])).unwrap();

        let mut public_coin_seed = Vec::new();
        pub_inputs.write_into(&mut public_coin_seed);

        let air = ProcessorAir::new(proof.get_trace_info(), pub_inputs, proof.options().clone());

        let mut public_coin = RandomCoin::<Felt, Blake2s_256<Felt>>::new(&public_coin_seed);
        let channel = VerifierChannel::<
            Felt,
            Blake2s_256<Felt>,
            DefaultEvaluationFrame<Felt>,
            DefaultEvaluationFrame<Felt>,
        >::new(&air, proof)?;

        let trace_commitments = channel.read_trace_commitments();

        // reseed the coin with the commitment to the main trace segment
        public_coin.reseed(trace_commitments[0]);

        // process auxiliary trace segments (if any), to build a set of random elements for each segment
        let mut aux_trace_rand_elements = AuxTraceRandElements::<Felt>::new();
        for (i, commitment) in trace_commitments.iter().skip(1).enumerate() {
            let rand_elements = air
                .get_aux_trace_segment_random_elements(i, &mut public_coin)
                .map_err(|_| VerifierError::RandomCoinError)?;
            aux_trace_rand_elements.add_segment_elements(rand_elements);
            public_coin.reseed(*commitment);
        }

        // build random coefficients for the composition polynomial
        let _constraint_coeffs = air
            .get_constraint_composition_coefficients::<Felt, Blake2s_256<Felt>>(&mut public_coin)
            .map_err(|_| VerifierError::RandomCoinError)?;

        // 2 ----- constraint commitment --------------------------------------------------------------
        // read the commitment to evaluations of the constraint composition polynomial over the LDE
        // domain sent by the prover, use it to update the public coin, and draw an out-of-domain point
        // z from the coin; in the interactive version of the protocol, the verifier sends this point z
        // to the prover, and the prover evaluates trace and constraint composition polynomials at z,
        // and sends the results back to the verifier.
        let constraint_commitment = channel.read_constraint_commitment();
        public_coin.reseed(constraint_commitment);
        let z = public_coin
            .draw::<Felt>()
            .map_err(|_| VerifierError::RandomCoinError)?;

        println!("{}", z.to_raw());

        Ok(())
    }
}