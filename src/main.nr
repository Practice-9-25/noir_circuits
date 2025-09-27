use poseidon::poseidon2::Poseidon2;
global TREE_DEPTH_MAX: u32 = 16;

fn recompute_root(
    mut current: Field,
    siblings: [Field; TREE_DEPTH_MAX],
    indices: [Field; TREE_DEPTH_MAX],
    actual_depth: Field,
) -> Field {
    for i in 0..TREE_DEPTH_MAX {
        if i < actual_depth as u32 {
            if indices[i] == 1 {
                current = Poseidon2::hash([siblings[i], current], 2);
            } else {
                current = Poseidon2::hash([current, siblings[i]], 2);
            }
        }
    }
    current
}

fn main(
    // Public inputs
    public_merkle_root: pub Field,
    public_nullifier: pub Field,
    public_recipient: pub Field,
    // Private inputs (witness values)
    note_amount: Field, 
    note_owner_pubkey: Field,
    note_owner_privkey: Field,
    note_nonce: Field,
    merkle_path: [Field; TREE_DEPTH_MAX],
    merkle_path_indices: [Field; TREE_DEPTH_MAX],
    actual_tree_depth: Field,
) {
    let computed_commitment = Poseidon2::hash([note_amount, note_owner_pubkey, note_nonce], 3);

    let computed_nullifier = Poseidon2::hash([note_owner_privkey, note_nonce], 2);

    assert(computed_nullifier == public_nullifier, "Nullifier mismatch");

    let derived_pub = Poseidon2::hash([note_owner_privkey], 1);

    assert(derived_pub == note_owner_pubkey, "Invalid pubkey-privkey pair");


    // let recomputed_root = compute_merkle_root(computed_commitment, leaf_index, merkle_path);
    let recomputed_root: Field = recompute_root(
        computed_commitment,
        merkle_path,
        merkle_path_indices,
        actual_tree_depth,
    );

    assert(recomputed_root == public_merkle_root, "Merkle root mismatch");
}

// #[test]
// fn test_valid_nullifier_and_merkle_root_depth2() {

//     let privkey = 5;
//     let pubkey = poseidon1([privkey]);
//     let amount = 1;
//     let nonce = 7;

//     let commitment = poseidon3([amount, pubkey, nonce]);

//     let nullifier = poseidon2([privkey, nonce]);

//     let sibling = 0; // ZERO leaf
//     let root = poseidon2([commitment, sibling]); // leaf layer
//     let root = poseidon2([root, 0]); // top layer

//     // path: sibling=0, indices=false
//     let path = [sibling, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
//     let indices = [
//         false, false, false, false, false, false, false, false, false, false, false, false, false,
//         false, false, false,
//     ];

//     main(
//         root,
//         nullifier,
//         999,
//         amount,
//         pubkey,
//         privkey,
//         nonce,
//         path,
//         indices,
//         0,
//         2,
//     );
// }

// #[test(should_fail)]
// fn test_invalid_nullifier() {
//     let privkey = 5;
//     let pubkey = poseidon1([privkey]);
//     let amount = 1;
//     let nonce = 7;

//     let commitment = poseidon3([amount, pubkey, nonce]);

//     // Wrong nullifier: use wrong privkey
//     let nullifier = poseidon2([42, nonce]);

//     let sibling = 0;
//     let root = poseidon2([commitment, sibling]);
//     let root = poseidon2([root, 0]);

//     let path = [sibling, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
//     let indices = [
//         false, false, false, false, false, false, false, false, false, false, false, false, false,
//         false, false, false,
//     ];

//     // should fail due to nullifier mismatch
//     main(
//         root,
//         nullifier,
//         999,
//         amount,
//         pubkey,
//         privkey,
//         nonce,
//         path,
//         indices,
//         0,
//         2,
//     );
// }

// #[test(should_fail)]
// fn test_invalid_pubkey() {
//     let privkey = 5;
//     let pubkey = 123; // wrong pubkey
//     let amount = 1;
//     let nonce = 7;

//     let commitment = poseidon3([amount, pubkey, nonce]);
//     let nullifier = poseidon2([privkey, nonce]);

//     let sibling = 0;
//     let root = poseidon2([commitment, sibling]);
//     let root = poseidon2([root, 0]);

//     let path = [sibling, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
//     let indices = [
//         false, false, false, false, false, false, false, false, false, false, false, false, false,
//         false, false, false,
//     ];

//     // should fail as derived_pub != pubkey
//     main(
//         root,
//         nullifier,
//         999,
//         amount,
//         pubkey,
//         privkey,
//         nonce,
//         path,
//         indices,
//         0,
//         2,
//     );
// }

// #[test(should_fail)]
// fn test_wrong_merkle_root() {
//     let privkey = 5;
//     let pubkey = poseidon1([privkey]);
//     let amount = 1;
//     let nonce = 7;

//     let commitment = poseidon3([amount, pubkey, nonce]);
//     let nullifier = poseidon2([privkey, nonce]);

//     let sibling = 0;
//     let root = poseidon2([commitment, sibling]);
//     let root = poseidon2([root, 0]);

//     let path = [sibling, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
//     let indices = [
//         false, false, false, false, false, false, false, false, false, false, false, false, false,
//         false, false, false,
//     ];

//     // given Wrong public_merkle_root
//     main(
//         root + 1,
//         nullifier,
//         999,
//         amount,
//         pubkey,
//         privkey,
//         nonce,
//         path,
//         indices,
//         0,
//         2,
//     );
// }

// #[test]
// fn test_merkle_proof_depth1_left_leaf() {
//     let leaf = 5;
//     let sibling = 10;
//     let path = [sibling, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
//     let indices = [false, false, false, false, false, false, false, false,
//                    false, false, false, false, false, false, false, false];
//     let root = poseidon2([leaf, sibling]);
//     let recomputed = recompute_root(leaf, path, indices, 1);
//     assert(root == recomputed);
// }

// #[test]
// fn test_merkle_proof_depth1_right_leaf() {
//     let leaf = 7;
//     let sibling = 3;
//     let path = [sibling, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
//     let indices = [true, false, false, false, false, false, false, false,
//                    false, false, false, false, false, false, false, false];
//     let root = poseidon2([sibling, leaf]); // sibling left, leaf right
//     let recomputed = recompute_root(leaf, path, indices, 1);
//     assert(root == recomputed);
// }

// #[test]
// fn test_merkle_proof_depth2_left_child() {
//     let leaf = 11;
//     let sib1 = 22; // sibling at depth 1
//     let sib2 = 33; // sibling at depth 2
//     let path = [sib1, sib2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
//     let indices = [false, true, false, false, false, false, false, false,
//                    false, false, false, false, false, false, false, false];
//     // depth 1: leaf left, sib1 right
//     let node1 = poseidon2([leaf, sib1]);
//     // depth 2: sib2 left, node1 right
//     let root = poseidon2([sib2, node1]);
//     let recomputed = recompute_root(leaf, path, indices, 2);
//     assert(root==recomputed);
// }

// #[test]
// fn test_merkle_proof_depth4_mixed_indices() {
//     let leaf = 99;
//     let path = [1, 2, 3, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
//     let indices = [false, true, false, true, false, false, false, false,
//                    false, false, false, false, false, false, false, false];

//     let n1 = poseidon2([leaf, 1]);   // depth 1 (leaf left, sib right)
//     let n2 = poseidon2([2, n1]);     // depth 2 (sib left, current right)
//     let n3 = poseidon2([n2, 3]);     // depth 3 (current left, sib right)
//     let root = poseidon2([4, n3]);   // depth 4 (sib left, current right)
//     let recomputed = recompute_root(leaf, path, indices, 4);
//     assert(root==recomputed);
// }
