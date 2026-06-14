# Arkiv Architecture & Web3 Protocol Design — Learning Roadmap

Goal: go from "I understand how a blockchain works and what the EVM is" to being a
serious — ideally leading — voice in Arkiv architecture discussions (DA, consensus,
proofs, the V1/V2/V3 decision). Ordered as a learning-dependency tree: each level
assumes the ones above it. Complements `op-stack.md` (which covers the ops/dev path);
this file is the protocol-design / cryptography / architecture path.

---

## 🟢 BASIC LEVEL

### 1. The state-machine model

* [ ] Blockchain as a replicated deterministic state machine
* [ ] State transition function (STF); determinism → replayability
* [ ] Why determinism is a hard constraint (no wall-clock, no floats, no hashmap iteration order)
* [ ] The two problems every chain solves: ordering (consensus) vs data availability

---

### 2. State, hashing & commitments

* [ ] Cryptographic hashes & collision resistance
* [ ] Merkle trees; state roots as commitments
* [ ] Merkle proofs / witnesses (membership)
* [ ] Non-membership proofs; sparse Merkle trees (SMT)
* [ ] MPT (Ethereum / keccak) vs SMT — what is swappable, what is baked in

---

### 3. Gas, metering & fees

* [ ] Why metering exists (halting bound, DoS resistance)
* [ ] Gas → token conversion (the two coordinate systems: work units vs price)
* [ ] EIP-1559 base-fee dynamics (congestion pricing)

---

## 🟡 INTERMEDIATE LEVEL

### 4. Rollups & the layer tower

* [ ] Why L2 exists: the data-availability cost of L1
* [ ] Rollup model: post data + state commitment; the derivation pipeline
* [ ] Rollup vs validium vs sidechain (the precise taxonomy)
* [ ] "Settles to / anchors to / parent chain" — and the layer-relative `--l1` gotcha

---

### 5. Data availability

* [ ] Integrity vs availability vs permanence (three distinct guarantees)
* [ ] L1 calldata and blobs (EIP-4844); blob expiry
* [ ] alt-DA: external DA networks, committees; content-addressing
* [ ] Arweave & bundlers; pay-once permanence economics
* [ ] Arkiv LDA: architecture, trust model, R2 + Hetzner mirror (cross-ref the KB)

---

### 6. Optimistic rollups & fault proofs

* [ ] The optimistic assumption + dispute window (why 7-day withdrawals)
* [ ] Interactive bisection: narrowing to one disputed step
* [ ] FPVM; Kona; the 1-of-N trust model (one honest challenger)
* [ ] Why EVM-shaped fault proofs don't cover a non-EVM engine

---

### 7. Sequencing, finality & reorgs

* [ ] Centralized sequencer; who holds ordering authority
* [ ] Force inclusion / censorship resistance (secondary channels)
* [ ] Finality heads: unsafe / safe / finalized; Casper FFG (justified vs finalized)
* [ ] Reorgs; the "read at the safe head" rule for downstream consumers

---

### 8. Bridges

* [ ] The conservation invariant; lock-and-mint / burn-and-release
* [ ] Trust models and why bridges are the most-exploited component
* [ ] Withdrawal authority: operator signature → Merkle proof
* [ ] Risk-reduction designs: GLM-only, non-transferable credit, deposit-only shells

---

### 9. OP Stack, concretely

* [ ] op-node / op-geth / op-batcher / op-proposer / op-conductor roles (see `op-stack.md`)
* [ ] Derivation, batches, channels, the sequence window
* [ ] Where Arkiv's V0 sits and what it inherits "for free" (and what it doesn't)

---

## 🔴 ADVANCED LEVEL

### 10. Consensus theory

* [ ] Safety vs liveness; FLP impossibility (intuition only)
* [ ] CFT (Raft): leader/followers, quorum, automatic failover
* [ ] BFT (Tendermint / CometBFT, HotStuff): the ⅓ Byzantine bound, slashing
* [ ] Why single-operator V1 → Raft is the *correct* model, not the cheap one
* [ ] Raft-as-chain-consensus failure modes vs plain etcd (the op-conductor reality)

---

### 11. Sovereign chains & the CL/EL split

* [ ] Consensus layer vs execution layer as separable components
* [ ] The Engine API (how a CL drives an EL)
* [ ] CometBFT + reth (BeaconKit / Berachain) — the option-(C) shape

---

### 12. ZK proofs — foundations

* [ ] Completeness, soundness, zero-knowledge (what each guarantees)
* [ ] Succinctness vs zero-knowledge — what Arkiv actually wants
* [ ] Validity proofs vs fault proofs, end to end (trust models 0-of-N vs 1-of-N)

---

### 13. ZK proofs — mechanism (intuition first, then math)

* [ ] Finite fields (modular arithmetic) — just enough intuition
* [ ] Arithmetization: turning an execution trace into constraints (R1CS / AIR)
* [ ] Polynomial commitments; checking a system by one random point (KZG)
* [ ] Proof-system landscape: Groth16 / PLONK / STARKs — trade-offs (trusted setup, proof size, prover cost)

---

### 14. ZK-friendly cryptography

* [ ] keccak vs Poseidon: in-circuit constraint cost
* [ ] SNARK-friendly hashes; why "Poseidon-class from day one"
* [ ] Commitment-scheme choice as strategic lock-in (reth's unswappable keccak MPT)

---

### 15. Provable execution

* [ ] Witness-backed execution; state access only through an abstract API
* [ ] Determinism vs provability — distinct properties, both required
* [ ] zkVMs (RISC-V guests); OP Succinct
* [ ] "The shared core": one engine → fault proofs (in FPVM) or validity proofs (in zkVM)

---

## 🟣 ARKIV ARCHITECTURE (the leading-voice layer)

### 16. The Arkiv data model & STF

* [ ] Entities, attributes, the closed operation set; the formal model
* [ ] Metering & resource accounting for database operations
* [ ] Write path vs read path; why queries stay out of consensus

---

### 17. The engine interface / EDSE

* [ ] Standard envelope, opaque payload (Ethereum-shaped outside, DB engine inside)
* [ ] The engine as the durable, host-independent invariant
* [ ] Conformance tiers: Trusted / Replay / Full
* [ ] Account-state (chain layer) vs engine-state (engine) split

---

### 18. Generation & trust roadmap

* [ ] V1 / V2 / V3: how the trust model evolves
* [ ] Forward-compatibility; tamper-evident vs tamper-proof
* [ ] Separate-chains-with-EOL vs in-place upgrades (and why expiry leases make EOL clean)
* [ ] Cross-chain references: `(chainId, entityKey)` as a value format, not a key type

---

### 19. The decision frame

* [ ] Options (A) custom / (B) OP Stack / (C) sovereign reth — the property table
* [ ] Paths to web3 properties: verifying / validating / producing / submitting
* [ ] Evidence tasks E1–E5; kill criteria; the staged synthesis path
* [ ] Operator economics, the maintenance treadmill, and "comfort lock-in"

---

## 🧠 PERFORMANCE & SYSTEM DESIGN

### Scaling & economics

* [ ] DA cost modeling at target load (commitment-gas vs storage; the 128 KB batch cap)
* [ ] Throughput ceilings; proving cost & latency as the ZK bottleneck
* [ ] Finality/latency trade-offs for downstream consumers (safe vs finalized depth)

### Architecture judgment

* [ ] Designing for "right-sized trust" per generation
* [ ] Operating it: turning SRE failure-mode knowledge into design input
  (divergence detection, DA monitoring, consensus failure surfaces)

---

## ▶️ CURRENT PROGRESS

**Completed:** Operational familiarity with the OP Stack tower (Arkiv V0 ops)
**Next:** The state-machine model (BASIC §1)
