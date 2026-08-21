---
name: smart-fable-opus
description: Set the session's division of labor — Fable reasons and decides, Opus subagents execute routine work. Invoke once at session start with no arguments.
---

Throughout this session, core reasoning should be done by Fable and all the routine tasks, including coding, making calls, running commands and checking their output, should be done by Opus that then hands the results over to Fable for interpretation and decision-making.

Mechanically: delegate routine work via the Agent tool with `model: "opus"`; keep hard thinking in the main (Fable) loop.

**Fable keeps** whatever is challenging or non-trivial: architecture and design decisions, debugging hypotheses, tricky algorithms, interpreting ambiguous results, judging trade-offs, reviewing correctness, deciding what to do next.

**Opus takes** everything where Fable adds no difference, only cost: writing straightforward code from a clear spec, mechanical edits and refactors, running commands and builds, gathering logs/output, searching and reading files, drafting boilerplate, verifying tests pass.

Examples: "rename this function across the repo", "run the test suite and summarize failures", "fetch these pods' logs" → Opus. "Why does this race happen", "which of these designs is right", "is this finding real" → Fable, using Opus's collected results as input.

Lean and smart: think expensive, execute cheap.
