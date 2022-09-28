%builtins output pedersen range_check ecdsa bitwise ec_op

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.serialize import serialize_word

from serialize.serialize import init_reader
from crypto.sha256d.sha256d import HASH_FELT_SIZE
from block.block_header import ChainState
from block.block import State, validate_and_apply_block, read_block_validation_context
from utreexo.utreexo import UTREEXO_ROOTS_LEN
from python_utils import setup_python_defs

func main{
    output_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
    ecdsa_ptr,
    bitwise_ptr: BitwiseBuiltin*,
    ec_op_ptr,
}() {
    alloc_locals;
    setup_python_defs();

    // Read the previous state from the program input
    local block_height: felt;
    local total_work: felt;
    let (best_block_hash) = alloc();
    local difficulty: felt;
    local epoch_start_time: felt;
    let (prev_timestamps) = alloc();
    let (prev_utreexo_roots) = alloc();
    %{
        ids.block_height = program_input["block_height"] if program_input["block_height"] != -1 else PRIME - 1
        ids.total_work = program_input["total_work"]
        segments.write_arg(ids.best_block_hash, felts_from_hash( program_input["best_block_hash"]) )
        ids.difficulty = program_input["difficulty"]
        ids.epoch_start_time = program_input["epoch_start_time"]
        segments.write_arg(ids.prev_timestamps, program_input["prev_timestamps"])
        segments.write_arg(ids.prev_utreexo_roots, felts_from_hex_strings( program_input["utreexo_roots"] ) )
    %}

    let prev_chain_state = ChainState(
        block_height, total_work, best_block_hash, difficulty, epoch_start_time, prev_timestamps
    );
    let prev_state = State(prev_chain_state, prev_utreexo_roots);

    // Perform a state transition
    let (context) = read_block_validation_context(prev_state);
    let (next_state) = validate_and_apply_block{hash_ptr=pedersen_ptr}(context);

    // Print the next state
    serialize_chain_state(next_state.chain_state);
    serialize_array(next_state.utreexo_roots, UTREEXO_ROOTS_LEN);

    // TODO: validate the previous chain proof
    return ();
}

func serialize_chain_state{output_ptr: felt*}(chain_state: ChainState) {
    serialize_word(chain_state.block_height);
    serialize_array(chain_state.best_block_hash, HASH_FELT_SIZE);
    serialize_word(chain_state.total_work);
    serialize_word(chain_state.difficulty);
    serialize_array(chain_state.prev_timestamps, 11);
    serialize_word(chain_state.epoch_start_time);
    return ();
}

func serialize_array{output_ptr: felt*}(array: felt*, array_len) {
    if (array_len == 0) {
        return ();
    }
    serialize_word([array]);
    serialize_array(array + 1, array_len - 1);
    return ();
}

func fetch_block(block_height) -> (block_data: felt*) {
    let (block_data) = alloc();

    %{
        block_height = ids.block_height

        import urllib3
        import json
        http = urllib3.PoolManager()

        url = 'https://blockstream.info/api/block-height/' + str(block_height)
        r = http.request('GET', url)
        block_hash = str(r.data, 'utf-8')

        url = f'https://blockstream.info/api/block/{ block_hash }/raw'
        r = http.request('GET', url)

        block_hex = r.data.hex()

        from_hex(block_hex, ids.block_data)
    %}
    return (block_data,);
}