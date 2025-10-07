import fs from "fs";
import { IncrementalMerkleTree } from "@zk-kit/incremental-merkle-tree";
import { poseidon2Hash } from "@zkpassport/poseidon2";

async function main() {
  function poseidonHash(...inputs) {
    const flat = inputs.flat(Infinity).map((x) => BigInt(x));
    return poseidon2Hash(flat); 
  }

  function poseidonLeaf(a, b, c) {
    return poseidon2Hash([BigInt(a), BigInt(b), BigInt(c)]);
  }

  const TREE_DEPTH = 4;
  const TREE_DEPTH_MAX = 16;
  const ZERO = 0n;
  const NUM_LEAVES = 2 ** TREE_DEPTH;

  const note_amount = 1n;
  const note_nonce = 123456n;
  const note_owner_privkey = 987654321n;

  // owner pubkey (Poseidon2 with arity=1)
  const note_owner_pubkey = poseidon2Hash([note_owner_privkey]);

  console.log("test poseidon hash", poseidon2Hash([1n, 2n]).toString());
  const tree = new IncrementalMerkleTree(poseidonHash, TREE_DEPTH, ZERO, 2);

  const leaf_index = 5;
  let commitment = poseidonLeaf(note_amount, note_owner_pubkey, note_nonce);

  for (let i = 0; i < NUM_LEAVES; i++) {
    if (i === leaf_index) {
      tree.insert(commitment);
    } else {
      tree.insert(ZERO);
    }
  }

  const proof = tree.createProof(leaf_index);

  const public_nullifier = poseidon2Hash([note_owner_privkey, note_nonce]);


  const siblingsPadded = [
    ...proof.siblings.map((s) => s.toString(10)),
    ...Array(TREE_DEPTH_MAX - proof.siblings.length).fill("0"),
  ];
  const indicesPadded = [
    ...proof.pathIndices.map((b) => (b ? "1" : "0")),
    ...Array(TREE_DEPTH_MAX - proof.pathIndices.length).fill("0"),
  ];

  const tomlObj = {
    actual_tree_depth: TREE_DEPTH.toString(),
    merkle_path: siblingsPadded,
    merkle_path_indices: indicesPadded,
    note_amount: note_amount.toString(),
    note_nonce: note_nonce.toString(),
    note_owner_privkey: note_owner_privkey.toString(),
    note_owner_pubkey: note_owner_pubkey.toString(),
    public_merkle_root: tree.root.toString(),
    public_nullifier: public_nullifier.toString(),
    public_recipient: "999999",
  };

  let tomlText = "";
  for (const [k, v] of Object.entries(tomlObj)) {
    if (Array.isArray(v)) {
      if (typeof v[0] === "boolean") {
        tomlText += `${k} = [${v
          .map((x) => (x ? "1" : "0"))
          .join(", ")}]\n`;
      } else {
        tomlText += `${k} = [${v.map((x) => `"${x}"`).join(", ")}]\n`;
      }
    } else {
      tomlText += `${k} = "${v}"\n`;
    }
  }

  fs.writeFileSync("../Prover.toml", tomlText);
  console.log("Done:");
  console.log(tomlText);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
