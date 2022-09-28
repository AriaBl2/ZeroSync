// Serialization and Validation of Bitcoin Block Headers
//
// See also:
// - Reference: https://developer.bitcoin.org/reference/block_chain.html#block-headers
// - Bitcoin Core: https://github.com/bitcoin/bitcoin/blob/7fcf53f7b4524572d1d0c9a5fdc388e87eb02416/src/primitives/block.h#L22

from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.math import assert_le, unsigned_div_rem, assert_le_felt, split_felt
from starkware.cairo.common.pow import pow
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_neg,
    uint256_add,
    uint256_sub,
    uint256_unsigned_div_rem,
)

from serialize.serialize import (
    Reader,
    read_uint32,
    read_hash,
    UINT32_SIZE,
    BYTE,
    init_reader,
    read_bytes,
)
from crypto.sha256d.sha256d import sha256d_felt_sized, assert_hashes_equal

// The size of a block header is 80 bytes
const BLOCK_HEADER_SIZE = 80;
// The size of a block header encoded as an array of Uint32 is 20 felts
const BLOCK_HEADER_FELT_SIZE = BLOCK_HEADER_SIZE / UINT32_SIZE;

// Definition of a Bitcoin block header
//
// See also:
// - https://developer.bitcoin.org/reference/block_chain.html#block-headers
struct BlockHeader {
    // The block version number indicates which set of block validation rules to follow
    version: felt,

    // The hash of the previous block in the chain
    prev_block_hash: felt*,

    // The Merkle root hash of all transactions in this block
    merkle_root_hash: felt*,

    // The timestamp of this block header
    time: felt,

    // The target for the proof-of-work in compact encoding
    bits: felt,

    // The lucky nonce which solves the proof-of-work
    nonce: felt,
}

// Read a BlockHeader from a Uint32 array
func read_block_header{reader: Reader, range_check_ptr}() -> (result: BlockHeader) {
    alloc_locals;

    let (version) = read_uint32();
    let (prev_block_hash) = read_hash();
    let (merkle_root_hash) = read_hash();
    let (time) = read_uint32();
    let (bits) = read_uint32();
    let (nonce) = read_uint32();

    return (BlockHeader(
        version, prev_block_hash, merkle_root_hash, time, bits, nonce),);
}


// A summary of the current state of a block chain
struct ChainState {
    // The number of blocks in the longest chain
    block_height: felt,

    // The total amount of work in the longest chain
    total_work: felt,

    // The block_hash of the current chain tip
    best_block_hash: felt*,

    // The required difficulty for targets in this epoch
    difficulty: felt,

    // The start time used to recalibrate the difficulty
    // after an epoch of about 2 weeks (exactly 2016 blocks)
    epoch_start_time: felt,

    // The timestamps of the 11 most recent blocks
    prev_timestamps: felt*,
}

// The validation context for block headers
struct BlockHeaderValidationContext {

    // The block header parsed into a struct
    // TODO: should be a pointer
    block_header: BlockHeader,

    // The hash of this block header
    block_hash: felt*,

    // The target for the proof-of-work
    // ASSUMPTION: Target is smaller than 2**246. Might overflow otherwise
    target: felt,

    // The previous state that is updated by this block
    prev_chain_state: ChainState,

    // The block height of this block header
    block_height: felt,
}


func fetch_block_header(block_height) -> (raw_block_header: felt*) {
    let (raw_block_header) = alloc();

    %{
        block_height = ids.block_height

        import urllib3
        import json
        http = urllib3.PoolManager()

        url = 'https://blockstream.info/api/block-height/' + str(block_height)
        r = http.request('GET', url)
        block_hash = str(r.data, 'utf-8')

        url = 'https://blockstream.info/api/block/' + block_hash + '/header'
        r = http.request('GET', url)
        block_hex = r.data.decode('utf-8')

        from_hex(block_hex, ids.raw_block_header)
    %}
    return (raw_block_header,);
}

// Read a block header and its validation context from a reader and a previous validation context
func read_block_header_validation_context{
    range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(prev_chain_state: ChainState) -> (context: BlockHeaderValidationContext) {
    alloc_locals;

    // Retrieve the block header from a hint
    let (raw_block_header) = fetch_block_header(prev_chain_state.block_height + 1);
    let (reader) = init_reader(raw_block_header);


    let (block_header) = read_block_header{reader=reader}();

    let (target) = bits_to_target(block_header.bits);

    let (block_hash) = sha256d_felt_sized(raw_block_header, BLOCK_HEADER_FELT_SIZE);

    let block_height = prev_chain_state.block_height + 1;

    return (
        BlockHeaderValidationContext(
            block_header,
            block_hash,
            target,
            prev_chain_state,
            block_height
        ),
    );
}

// Calculate target from bits
//
// See also:
// - https://developer.bitcoin.org/reference/block_chain.html#target-nbits
func bits_to_target{range_check_ptr}(bits) -> (target: felt) {
    alloc_locals;
    // Ensure that the max target is not exceeded (0x1d00FFFF)
    assert_le(bits, 0x1d00FFFF);

    // Decode the 4 bytes of `bits` into exponent and significand.
    // There's 1 byte for the exponent followed by 3 bytes for the significand
    let (exponent, significand) = unsigned_div_rem(bits, BYTE ** 3);

    // The target is the `significand` shifted `exponent` times to the left
    let (shift_left) = pow(BYTE, exponent - 3);
    return (significand * shift_left,);
}

// Validate a block header, apply it to the previous state
// and return the next state
func validate_and_apply_block_header{range_check_ptr}(context: BlockHeaderValidationContext) -> (
    next_state: ChainState
) {
    alloc_locals;
    // Validate previous block hash
    validate_prev_block_hash(context);

    // Validate the proof-of-work
    validate_proof_of_work(context);

    // Validate the difficulty of the proof-of-work
    validate_target(context);

    // Validate the block's timestamp
    validate_timestamp(context);

    // Apply this block to the previous state
    // and return the next state
    let (next_state) = apply_block_header(context);

    return (next_state,);
}

// Validate that a block header correctly extends the current chain
func validate_prev_block_hash(context: BlockHeaderValidationContext) {
    assert_hashes_equal(
        context.prev_chain_state.best_block_hash, context.block_header.prev_block_hash
    );
    return ();
}

// Validate a block header's proof-of-work matches its target.
// Expects that the 4 most significant bytes of `block_hash` are zero.
func validate_proof_of_work{range_check_ptr}(context: BlockHeaderValidationContext) {
    // Swap the endianess in the uint32 chunks of the hash
    let (reader) = init_reader(context.block_hash);
    let (hash) = read_bytes{reader=reader}(32);

    // Validate that the hash's most significant uint32 chunk is zero
    // This guarantees that the hash fits into a felt.
    assert 0 = hash[7];

    // Sum up the other 7 uint32 chunks of the hash into 1 felt
    const BASE = 2 ** 32;
    let hash_felt = hash[0] * BASE ** 0 +
        hash[1] * BASE ** 1 +
        hash[2] * BASE ** 2 +
        hash[3] * BASE ** 3 +
        hash[4] * BASE ** 4 +
        hash[5] * BASE ** 5 +
        hash[6] * BASE ** 6;

    // Validate that the hash is smaller than the target
    assert_le_felt(hash_felt, context.target);
    return ();
}

// Validate that the proof-of-work target is sufficiently difficult
//
// See also:
// - https://github.com/bitcoin/bitcoin/blob/7fcf53f7b4524572d1d0c9a5fdc388e87eb02416/src/pow.cpp#L13
func validate_target(context: BlockHeaderValidationContext) {
    // TODO: implement me
    return ();
}

// Validate that the timestamp of a block header is strictly greater than the median time
// of the 11 most recent blocks.
//
// See also:
// - https://developer.bitcoin.org/reference/block_chain.html#block-headers
// - https://github.com/bitcoin/bitcoin/blob/36c83b40bd68a993ab6459cb0d5d2c8ce4541147/src/chain.h#L290
func validate_timestamp{range_check_ptr}(context: BlockHeaderValidationContext) {
    alloc_locals;

    let prev_timestamps = context.prev_chain_state.prev_timestamps;
    // TODO: validate median
    // Step 1: Let Python sort the array and compute a permutation (array of indexes)
    // Step 2: Use that permutation to create a sorted array of pointers in Cairo
    // Step 3: Prove sortedness of the sorted array in linear time
    // Step 4: Read the median from the sorted array

    local median_time;
    %{
        timestamps = []
        for i in range(11):
            timestamp = memory[ids.prev_timestamps + i]
            timestamps.append(timestamp)
        timestamps.sort()
        ids.median_time = timestamps[5]
    %}

    assert_le(median_time, context.block_header.time);
    return ();
}


// Compute the total work invested into the longest chain
//
func compute_total_work{range_check_ptr}(context: BlockHeaderValidationContext) -> (work: felt) {
    let (work_in_block) = compute_work_from_target(context.target);
    return (context.prev_chain_state.total_work + work_in_block,);
}

// Convert a target into units of work.
// Work is the expected number of hashes required to hit a target.
//
// See also:
// - https://bitcoin.stackexchange.com/questions/936/how-does-a-client-decide-which-is-the-longest-block-chain-if-there-is-a-fork/939#939
// - https://github.com/bitcoin/bitcoin/blob/v0.16.2/src/chain.cpp#L121
// - https://github.com/bitcoin/bitcoin/blob/v0.16.2/src/validation.cpp#L3713
//
func compute_work_from_target{range_check_ptr}(target) -> (work: felt) {
    // TODO: Check all boundaries. This is just a dummy implementation
    // TODO: Write tests for compute_work_from_target
    let (hi, lo) = split_felt(target);
    let target256 = Uint256(lo, hi);
    let (neg_target256) = uint256_neg(target256);
    let (not_target256) = uint256_sub(neg_target256, Uint256(1, 0));
    let (div, _) = uint256_unsigned_div_rem(not_target256, target256);
    let (result, _) = uint256_add(div, Uint256(1, 0));
    return (result.low + result.high * 2 ** 128,);
}

// Apply a block header to a previous chain state to obtain the next chain state
//
func apply_block_header{range_check_ptr}(context: BlockHeaderValidationContext) -> (
    next_state: ChainState
) {
    alloc_locals;

    let (prev_timestamps) = next_prev_timestamps(context);
    let (total_work) = compute_total_work(context);

    // TODO: Recalibrate the difficulty after about 2 weeks of blocks
    // Exactly when context.block_height % 2016 == 0
    let (_, is_not_recalibrate) = unsigned_div_rem(context.block_height, 2016);
    if (is_not_recalibrate == 0) {
        tempvar epoch_start_time = context.block_header.time;
    } else {
        tempvar epoch_start_time = context.prev_chain_state.epoch_start_time;
    }

    return (
        ChainState(
            context.block_height,
            total_work,
            context.block_hash,
            context.prev_chain_state.difficulty,
            epoch_start_time,
            prev_timestamps
        ),
    );
}

// Compute the 11 most recent timestamps for the next state
//
func next_prev_timestamps(context: BlockHeaderValidationContext) -> (timestamps: felt*) {
    // Copy the timestamp of the most recent block
    alloc_locals;
    let (timestamps) = alloc();
    assert timestamps[0] = context.block_header.time;

    // Copy the 10 most recent timestamps from the previous state
    let prev_timestamps = context.prev_chain_state.prev_timestamps;
    memcpy(timestamps + 1, prev_timestamps, 10);
    return (timestamps,);
}