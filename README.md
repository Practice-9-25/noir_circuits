## CIRCUITS

## Off-chain Key generation `js/X25519-generateKeys.js`

This script demonstrates a secure **note creation and verification flow** between two parties, **Alice** and **Bob**, using:

- **X25519 Elliptic Curve Diffie-Hellman (ECDH)** for secure key exchange.  
- **HKDF-SHA256** for deriving independent secrets from the shared key.  
- **Poseidon2 Hash** (ZK-friendly) for generating commitments suitable for use in **zero-knowledge proofs (ZKPs)**.  

It provides a building block for privacy-preserving protocols such as shielded transactions or anonymous notes.

---

##  Core Cryptographic Primitives

1. **X25519 Key Exchange**  
   - Allows Alice and Bob to derive the same shared secret securely.  
   - Based on elliptic curve scalar multiplication.  

2. **HKDF-SHA256**  
   - Expands the shared secret into multiple independent keys.  
   - Ensures forward secrecy and prevents key reuse.  

3. **Poseidon2 Hash Function**  
   - A ZK-friendly hash function optimized for SNARK/STARK proving systems.  
   - Used here to generate the **public commitment** from private values.  

---

##  Function Breakdown

### 1. `hkdfSha256(secret, info, length = 32)`

Derives secure output keys from the shared secret using **HKDF with SHA-256**.  

**Steps**:
- **Extract**: Create a pseudorandom key (PRK) from the shared secret.  
- **Expand**: Use HMAC-SHA256 with context (`info`) to derive distinct outputs.  
- **Output**: Return fixed-length key material.  

In this script:
- `info = "string1"` → produces the **Secret**.  
- `info = "string2"` → produces the **Nullifier**.  

---

### 2. `poseidonHashBytes(...buffers)`

Computes a Poseidon2 hash over byte inputs.  

**Formula**:  

```
Commitment = Poseidon2Hash(Secret, Nullifier)
 ```

This produces a ZK-friendly **commitment** that Alice can publish publicly.  

---

## Alice’s Note Creation (`aliceCreatesNote`)

Alice generates a commitment that Bob can later verify.  

| Step | Description | Formula |
|------|-------------|---------|
| 1. Ephemeral Keypair | Alice creates an ephemeral X25519 keypair (R_priv, R_pub)$. | R_{pub} is shared publicly. |
| 2. Shared Secret | Compute shared key with Bob’s public key. | SharedKey = X25519(R_priv, Bob_pub) |
| 3. Derive Keys | Use HKDF to derive: Secret + Nullifier. | Secret = HKDF(SharedKey, "string1"), Nullifier = HKDF(SharedKey, "string2") |
| 4. Commitment | Hash both values with Poseidon2. | Commitment = Poseidon2(Secret, Nullifier) |

**Alice Publishes On-Chain**:  
- `Commitment`  
- `R_pub_hex` (her ephemeral public key in hex).  

---

##  Bob’s Derivation (`bobDerivesSecret`)

Bob reconstructs the same values using Alice’s ephemeral public key.  

| Step | Description | Formula |
|------|-------------|---------|
| 1. Shared Secret | Bob computes the same shared key. | SharedKey = X25519(Bob_{priv}, R_{pub}) |
| 2. Re-Derive Keys | Apply HKDF with same context strings. | Secret = HKDF(SharedKey, "string1") , Nullifier = HKDF(SharedKey, "string2") |
| 3. Commitment Check | Bob recomputes the commitment. | CommitmentCheck = Poseidon2(Secret, Nullifier) |

**Validation**:  
If `CommitmentCheck == Commitment`, Bob confirms Alice’s note is valid.  

**Bob’s Private Output**:  
- `Secret` (hex)  
- `Nullifier` (hex)  
- `CommitmentCheck`  

---


## Run the script:

```bash
node js/X25519-generateKeys.js
```

## Integration with Circuits

Once Alice and Bob establish the shared values, we move to the **Zero-Knowledge Proof (ZKP) circuit**. The purpose of this circuit is to allow a prover (e.g., Alice or Bob) to demonstrate knowledge of valid values without revealing them publicly.

### Circuit Workflow

1. **Private Inputs**  
   - `Secret`: Derived from the shared key using HKDF.  
   - `Nullifier`: Also derived from the shared key but with a different HKDF context string.  

   These values remain hidden and are never revealed outside the circuit.

2. **Public Inputs**  
   - `Commitment`: A Poseidon hash published on-chain by Alice.  
   - Other possible public inputs, such as Merkle paths or nullifier hashes, can be included for scalability or uniqueness in larger systems.

3. **Recomputation Inside the Circuit**  
   - The circuit takes the private `Secret` and `Nullifier`, runs the same **Poseidon hash**, and generates an internal commitment.  
   - Formula:  Commitment_circuit = Poseidon2Hash(Secret, Nullifier)
    

4. **Assertion (Constraint Check)**  
   - The circuit enforces a constraint that the internally computed commitment must equal the **public Commitment input**:  
     Commitment_circuit == Commitment_public 

   If this holds, the `proof is valid`.
   also proving they are the intended receipient and indeed have associated private key of the commitement for which the alive made. 

---

### Why This Matters

- **Privacy**: The prover never exposes the `Secret` or `Nullifier` outside the proof.  
- **Integrity**: The verifier can be sure that the prover indeed knows the valid preimage (secret values) for the published commitment.  
- **On-chain Verification**: A smart contrac ( Verifier.sol ) can accept the proof and verify it against the stored commitment. This enables private ownership proofs, note-spending systems, and anonymous transfers.  
