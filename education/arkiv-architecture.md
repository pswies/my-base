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
* [ ] Canonical/deterministic serialization (e.g. SSZ) as a determinism requirement
* [ ] The two problems every chain solves: ordering (consensus) vs data availability

---

### 2. State, hashing & commitments

* [ ] Cryptographic hashes & collision resistance
* [ ] Merkle trees; state roots as commitments
* [ ] Merkle proofs / witnesses (membership)
* [ ] Non-membership proofs; sparse Merkle trees (SMT)
* [ ] MPT (Ethereum / keccak) vs SMT — what is swappable, what is baked in
* [ ] State commitments vs output/receipts commitments (committed tx log → tamper-evident *outcomes*, not just state)

---

### 3. Trust models & verification

* [ ] The trust-model vocabulary: 0-of-N (verify yourself), 1-of-N (one honest party), 1-of-1 (trust the operator), M-of-N, stake-majority (N/2-of-N)
* [ ] Tamper-evident vs tamper-proof
* [ ] Verification vs enforcement — you can *detect* cheating without being able to *prevent* it (the spine of the V1 trust story)

---

### 4. Gas, metering & fees

* [ ] Why metering exists (halting bound, DoS resistance)
* [ ] Gas → token conversion (the two coordinate systems: work units vs price)
* [ ] EIP-1559 base-fee dynamics (congestion pricing)
* [ ] Multitoken gas: GLM default + ETH/stablecoins; fee-*token* choice as an envelope-layer concern
* [ ] Intrinsic / per-byte cost for opaque payloads (closing the "free DoS lane")

---

## 🟡 INTERMEDIATE LEVEL

### 5. Rollups & the layer tower

* [ ] Why L2 exists: the data-availability cost of L1
* [ ] Rollup model: post data + state commitment; the derivation pipeline
* [ ] Rollup vs validium vs sidechain (the precise taxonomy)
* [ ] "Settles to / anchors to / parent chain" — and the layer-relative `--l1` gotcha

---

### 6. Data availability

* [ ] Integrity vs availability vs permanence (three distinct guarantees)
* [ ] L1 calldata and blobs (EIP-4844); blob expiry
* [ ] alt-DA: external DA networks, committees; content-addressing
* [ ] Arweave & bundlers; pay-once permanence economics
* [ ] DA write-time gating: bundler receipt, max-archival-window backstop; on-chain attestation (DA committee / DA-bridge)
* [ ] Arkiv LDA: architecture, trust model, R2 + Hetzner mirror (cross-ref the KB)

---

### 7. Optimistic rollups & fault proofs

* [ ] The optimistic assumption + dispute window (why 7-day withdrawals)
* [ ] Interactive bisection: narrowing to one disputed step
* [ ] FPVM; Kona; the 1-of-N trust model (one honest challenger)
* [ ] Why EVM-shaped fault proofs don't cover a non-EVM engine

---

### 8. Sequencing, finality, reorgs & propagation

* [ ] Centralized sequencer; who holds ordering authority
* [ ] Force inclusion / censorship resistance (secondary channels)
* [ ] Finality heads: unsafe / safe / finalized; Casper FFG (justified vs finalized)
* [ ] Reorgs; the "read at the safe head" rule for downstream consumers
* [ ] Justified-displacement reorg; the safe-vs-finalized residual risk
* [ ] Block propagation: sequencer feed (fan-out problem) vs p2p gossip; the `latest` (unsafe) vs `safe` two-speed read split

---

### 9. Node sync & weak subjectivity

* [ ] Sync strategies: genesis replay vs snap-sync vs trusted checkpoint
* [ ] Weak subjectivity; how L2-anchoring closes the weak-subjectivity gap for a sovereign chain
* [ ] Sync SLAs (initial sync < 2 days; fast re-sync; rebuild-from-empty option)

---

### 10. Bridges

* [ ] The conservation invariant; lock-and-mint / burn-and-release
* [ ] Trust models and why bridges are the most-exploited component
* [ ] Withdrawal authority: operator signature → Merkle proof
* [ ] Risk-reduction designs: GLM-only, non-transferable credit, deposit-only shells (no honeypot)

---

### 11. OP Stack, concretely

* [ ] op-node / op-geth / op-batcher / op-proposer / op-conductor roles (see `op-stack.md`)
* [ ] Derivation, batches, channels, the sequence window
* [ ] Precompiles & the "engine seam": hosting a custom engine inside an EVM client (op-reth today)
* [ ] Where Arkiv's V0 sits and what it inherits "for free" (and what it doesn't)

---

## 🔴 ADVANCED LEVEL

### 12. Consensus theory

* [ ] Safety vs liveness; FLP impossibility (intuition only)
* [ ] CFT (Raft): leader/followers, quorum, automatic failover
* [ ] BFT (Tendermint / CometBFT, HotStuff): the ⅓ Byzantine bound, slashing
* [ ] Why single-operator V1 → Raft is the *correct* model, not the cheap one
* [ ] Raft-as-chain-consensus failure modes vs plain etcd (the op-conductor reality)
* [ ] The "seven consensus surfaces" framework (fork-choice, finality, reorg, cross-layer messaging, leader-failure liveness, multi-writer disambiguation, fault attribution)
* [ ] Anchoring ≠ consensus: open-auth posting + trusted-poster filter; canonicality decided one layer up

---

### 13. Sovereign chains & the CL/EL split

* [ ] Consensus layer vs execution layer as separable components
* [ ] The Engine API (how a CL drives an EL)
* [ ] CometBFT + reth (BeaconKit / Berachain) — the option-(C) shape

---

### 14. ZK proofs — foundations

* [ ] Completeness, soundness, zero-knowledge (what each guarantees)
* [ ] Succinctness vs zero-knowledge — what Arkiv actually wants
* [ ] Validity proofs vs fault proofs, end to end (trust models 0-of-N vs 1-of-N)

---

### 15. ZK proofs — mechanism (intuition first, then math)

* [ ] Finite fields (modular arithmetic) — just enough intuition
* [ ] Arithmetization: turning an execution trace into constraints (R1CS / AIR)
* [ ] Polynomial commitments; checking a system by one random point (KZG)
* [ ] Proof-system landscape: Groth16 / PLONK / STARKs — trade-offs (trusted setup, proof size, prover cost)

---

### 16. ZK-friendly cryptography

* [ ] keccak vs Poseidon: in-circuit constraint cost
* [ ] SNARK-friendly hashes; why "Poseidon-class from day one"
* [ ] Commitment-scheme choice as strategic lock-in (reth's unswappable keccak MPT)

---

### 17. Provable execution

* [ ] Witness-backed execution; state access only through an abstract API
* [ ] Determinism vs provability — distinct properties, both required
* [ ] zkVMs (RISC-V guests); OP Succinct
* [ ] "The shared core": one engine → fault proofs (in FPVM) or validity proofs (in zkVM)

---

## 🟣 ARKIV ARCHITECTURE (the leading-voice layer)

### 18. The Arkiv data model & STF

* [ ] Entities, attributes, the closed operation set; the formal model
* [ ] Metering & resource accounting for database operations
* [ ] Transaction outcome semantics: inadmissible / valid-but-failed / success; Ethereum-equivalent fee + nonce handling
* [ ] The "skip-not-halt" deviation and why the STF must be *total*
* [ ] Data lifecycle: bounded prepaid leases, expiry, the cleanup bot; storage economics (size × expiry × load)
* [ ] Write path vs read path; why queries stay out of consensus
* [ ] Query model: predicate queries over attributes; the `eth_call` virtual query contract (Arbitrum `NodeInterface` pattern)

---

### 19. Hard forks, engine versioning & replay

* [ ] Hard forks & fork schedules (activation heights)
* [ ] Engine versioning: `(engineId, version, activation height)`; implementation-swap vs engine-upgrade vs new-model
* [ ] Versioned replay: archivers replay each block under the version active at its height (every historical version must remain available)

---

### 20. The engine interface / EDSE

* [ ] Standard envelope, opaque payload (Ethereum-shaped outside, DB engine inside)
* [ ] The engine as the durable, host-independent invariant
* [ ] Conformance tiers: Trusted / Replay / Full
* [ ] Conformance suite: frozen replay corpus that gates implementation swaps
* [ ] Account-state (chain layer) vs engine-state (engine) split

---

### 21. Generation & trust roadmap

* [ ] V1 / V2 / V3: how the trust model evolves
* [ ] Forward-compatibility; tamper-evident vs tamper-proof
* [ ] Separate-chains-with-EOL vs in-place upgrades (and why expiry leases make EOL clean)
* [ ] L2Beat decentralization stages — the industry framing of the path to decentralization
* [ ] Cross-chain references: `(chainId, entityKey)` as a value format, not a key type

---

### 22. The decision frame

* [ ] Options (A) custom / (B) OP Stack / (C) sovereign reth — the property table
* [ ] Paths to web3 properties: verifying / validating / producing / submitting (and decentralized ≠ permissionless)
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
