// note-derive-poseidon.js
import sodium from "libsodium-wrappers";
import crypto from "crypto";
import { poseidon2Hash } from "@zkpassport/poseidon2";

async function hkdfSha256(secret, info, length = 32) {
  const salt = Buffer.alloc(32, 0);
  const prk = crypto
    .createHmac("sha256", salt)
    .update(Buffer.from(secret))
    .digest();
  let prev = Buffer.alloc(0);
  const output = Buffer.alloc(length);
  const blocks = Math.ceil(length / 32);
  let outPos = 0;

  for (let i = 0; i < blocks; i++) {
    const hmac = crypto.createHmac("sha256", prk);
    hmac.update(prev);
    hmac.update(Buffer.from(info));
    hmac.update(Buffer.from([i + 1]));
    prev = hmac.digest();
    const take = Math.min(32, length - outPos);
    prev.copy(output, outPos, 0, take);
    outPos += take;
  }
  return output;
}

function poseidonHashBytes(...buffers) {
  const flat = buffers.map((b) => [...b].map((x) => BigInt(x))).flat();
  return poseidon2Hash(flat);
}

async function aliceCreatesNote(bobX25519Pub) {
  await sodium.ready;

  const eph = sodium.crypto_kx_keypair();
  const R_pub = Buffer.from(eph.publicKey);
  const R_priv = Buffer.from(eph.privateKey);

  const shared = sodium.crypto_scalarmult(R_priv, Buffer.from(bobX25519Pub));

  const secret = await hkdfSha256(shared, "string1", 32);
  const nullifier = await hkdfSha256(shared, "string2", 32);

  const commitment = poseidonHashBytes(secret, nullifier);

  return {
    commitment: commitment.toString(),
    R_pub_hex: Buffer.from(R_pub).toString("hex"),
  };
}

async function bobDerivesSecret(R_pub_hex, bobX25519Priv) {
  await sodium.ready;

  const R_pub = Buffer.from(R_pub_hex, "hex");
  const bobPriv = Buffer.from(bobX25519Priv, "hex");

  const shared = sodium.crypto_scalarmult(bobPriv, R_pub);

  const secret = await hkdfSha256(shared, "string1", 32);
  const nullifier = await hkdfSha256(shared, "string2", 32);

  const commitmentCheck = poseidonHashBytes(secret, nullifier);

  return {
    secret: secret.toString("hex"),
    nullifier: nullifier.toString("hex"),
    commitmentCheck: commitmentCheck.toString(),
  };
}

(async () => {
  await sodium.ready;

  const bob = sodium.crypto_kx_keypair();
  const bobPubHex = Buffer.from(bob.publicKey).toString("hex");
  const bobPrivHex = Buffer.from(bob.privateKey).toString("hex");

  const aliceNote = await aliceCreatesNote(Buffer.from(bobPubHex, "hex"));
  console.log("Alice published on chain:", aliceNote);

  const bob2 = await bobDerivesSecret(aliceNote.R_pub_hex, bobPrivHex);
  console.log("Bob derived:", bob2);
})();
