---
name: project-review
description: Full-codebase review of a git branch (main by default), not just a diff. Use whenever the user asks to review the whole project, audit the codebase, review main or another branch, do a repo-wide quality/security pass, or asks "review everything", "audit this repo", "how healthy is this codebase" — even if they don't say "skill". Do NOT use for reviewing uncommitted changes or a PR diff; the bundled /code-review command covers that.
---

# Project Review

Reviews the entire codebase of a given ref (default: `main`) and reports validated, high-signal findings with file:line references. Adapted from Anthropic's public `/code-review` plugin (multi-agent review + validation + confidence filtering), rescoped to a whole tree and optimized for cost: deterministic tools first, risk-weighted depth, one merged review agent per module, tiered models, batched validation, hard budgets.

There is a single review mode. Do not offer effort tiers to the user. Depth varies internally by *risk tier of the code*, never by a user-selected quality level.

## Arguments

Free-text. Interpret as:
- A branch/tag/SHA → the ref to review. Default `main`; fall back to `master`, then `git symbolic-ref refs/remotes/origin/HEAD`.
- Path(s) → restrict review to those subtrees.
- Anything else ("focus on security", "ignore tests") → focus/exclusion instructions layered on the standard process.

## Model tiering (pinned — do not improvise)

- **fast** (Haiku-class): triage scoring, CLAUDE.md compliance checks, module interface summaries.
- **mid** (Sonnet-class): standard-tier module review, batched validation of Medium/Nit findings.
- **strong** (Opus-class): deep review of high-risk modules, batched validation of Critical/High candidates, architecture synthesis.

When spawning a subagent, always pass the model explicitly. If the environment cannot pin models, state so in the report header.

## Hard budgets (fail loudly, never silently degrade)

- ≤ 20 review agents, ≤ 10 validation agents, ≤ 1 architecture agent per run.
- ≤ 30 candidate findings enter validation: all Critical/High, then Medium by confidence; the remainder are reported as "unvalidated observations" in an appendix, clearly labeled.
- If the inventory exceeds ~150k source lines or module count would exceed the agent cap, STOP before spawning agents, show the user the estimated scale and the top-risk subtrees, and ask whether to scope down or proceed.
- If any budget is hit mid-run, say so explicitly in the report; do not quietly shrink coverage.

## Step 1: Materialize the ref (read-only)

Never check out in place; the user may have uncommitted work.

```bash
git rev-parse --verify <ref>                      # fail fast, clear message
REVIEW_DIR=$(mktemp -d)/review
git worktree add --detach "$REVIEW_DIR" <ref>
SHA=$(git -C "$REVIEW_DIR" rev-parse --short HEAD)
```

All reading happens in `$REVIEW_DIR`. Always clean up, even on failure: `git worktree remove --force "$REVIEW_DIR"`. If worktrees are unavailable, fall back to `git ls-tree -r <ref>` + `git show <ref>:<path>`.

## Step 2: Inventory

1. `git -C "$REVIEW_DIR" ls-files`; exclude lockfiles, generated code, vendored deps (`vendor/`, `node_modules/`, `third_party/`), build output, binaries, snapshots/fixtures.
2. Collect every `CLAUDE.md`; each governs only its subtree.
3. Read entry points and configs yourself (README, main/index, CI config, dependency manifests) → one-paragraph system model passed to every agent.

## Step 3: Deterministic pre-scan (before any LLM review)

Run whatever applies and is installed; skip silently what isn't, but list what ran in the report:

- Linters/type-checkers per ecosystem (`ruff`/`mypy`, `eslint`/`tsc --noEmit`, `go vet`, `cargo clippy`, ...).
- `semgrep --config auto` if available.
- Secret scan: `gitleaks detect --source "$REVIEW_DIR"` or a grep-based fallback for key/token patterns.
- Dependency audit: `npm audit` / `pip-audit` / `cargo audit` / `osv-scanner` as applicable.
- Dependency graph for the architecture agent: `madge --json` (JS/TS), `pydeps --show-deps` (Python), `go mod graph`, or an import-grep fallback producing an edge list.

Rules: tool findings go straight into the report (tagged `[static]`, no LLM validation needed for mechanical ones); review agents are told what the tools already cover and must NOT re-derive those classes of issues — they look only for what static analysis structurally cannot find (logic, semantics, intent, cross-file behavior). Tool output also seeds triage (files with hits gain risk).

## Step 4: Risk triage (fast model + git data)

Compute per-file signals cheaply:

```bash
git -C "$REVIEW_DIR" log --since="12 months ago" --format= --name-only | sort | uniq -c | sort -rn   # churn
```

Then one **fast** agent scores files/directories 0–10 using: churn; path/name heuristics (auth, crypto, payment, session, upload, deserialization, SQL, exec/shell, network handlers, permission checks, entry points); pre-scan hits; fan-in from the dependency graph. Output: ranked list with tier assignment.

- **Tier A (high risk)**: deep review, strong model. Target the top ~20–30% of source lines.
- **Tier B (standard)**: normal review, mid model.
- **Tier C (low risk — generated-adjacent, stable leaf utilities, pure config)**: skim only — the triage agent itself notes anything glaring; no dedicated agent.

Include the tier map in the final report so the user can contest the allocation.

## Step 5: Module review — one merged agent per module

Partition Tier A/B files into modules (top-level dirs, second level for monorepos; ~50 files / ~10k lines per module as a guide; merge tiny, split huge). For each module spawn **one** agent (model per tier) that covers bugs AND security in a single read:

- Logic errors, broken edge cases, races, resource leaks, incorrect error handling.
- Injection, authn/authz gaps, secrets, unsafe deserialization, path traversal, SSRF, insecure defaults.
- CLAUDE.md adherence for rules in scope (fast model may handle compliance-only sweeps of Tier C subtrees if CLAUDE.md files exist there).

Each agent ALSO returns a structured module summary for Step 6: public interface, key invariants/assumptions, outbound dependencies, error-handling and naming conventions observed.

Do not flag: lint-silenced issues; generic "add tests/docs" advice unless a CLAUDE.md requires it; style preferences not backed by CLAUDE.md or a dominant codebase convention; anything covered by the static tools; anything without a specific file:line.

## Step 6: Architecture pass (one strong agent, structured input only)

Input: the dependency graph from Step 3 + the module summaries from Step 5 + the system model. NOT raw code (it may request specific files, capped at 10). It looks for: duplicated logic across modules, circular or inverted dependencies, inconsistent error-handling/API conventions, config sprawl, missing seams for testing, mismatches between a module's stated invariants and its callers' assumptions.

## Step 7: Batched validation

Group candidate findings **by file**, not one agent per finding. Each validation agent gets a file (plus minimal surrounding context) and all findings against it, and must confirm or reject each:

- Bugs: the failure path is reachable and the behavior is actually wrong.
- Security: input is attacker-influenced or the misconfiguration is live, not test-only.
- Compliance: the cited CLAUDE.md rule is in scope and genuinely violated.

Critical/High batches → strong model. Medium → mid model. Nits are not validated; cap at 5 in the report. Score 0–100; discard < 80. Deduplicate same-root-cause findings into one entry listing all occurrences.

## Step 8: Report

Terminal output (write `PROJECT-REVIEW.md` only if asked):

```
# Project review: <ref> @ <sha>  (<N> files reviewed / <M> excluded / tiers A:<a> B:<b> C:<c>)
Static tools run: <list>   Models: <tier map>   Budgets hit: <none | which>

<3-sentence system summary and overall assessment>

## Critical  ## High  ## Medium  ## Nits (max 5, + count)
## [static] tool findings (summarized, deduplicated)
## Appendix: unvalidated observations (if validation budget was hit)
## Not covered: <excluded paths, Tier C skim scope, anything skipped>
```

Each finding: `path:line — description. Why: <category/rule>. Fix: <one concrete suggestion>.` If zero validated findings, say so with the categories checked — never manufacture findings.

## Notes

- Read-only: never modify files; fixes are a separate, explicit follow-up request.
- Small repos (< ~20k source lines): skip subagents entirely — do Steps 1–3, then review the tree yourself in one sequential pass with the same rules, validate your own Critical/High findings by re-reading before reporting.
