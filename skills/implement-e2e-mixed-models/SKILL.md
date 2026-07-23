---
name: implement-e2e-mixed-models
description: End-to-end task implementation with mixed models — deep interactive planning, plan written into a GitHub issue (or a local plan file when issues are unavailable) and checked off as work lands, explicit user "go", then Opus implements while Fable reviews and runs ops, looping until the reviewer approves everything and CI plus all other checks are green, ending with a PR handed to the user for approval. Use when the user asks to implement a task end-to-end with this workflow.
---

# Implement end-to-end with mixed models

A full task lifecycle with a strict division of labor:

- **Fable (the main session — you)**: deep planning, writing the plan issue, code review, and all ops (git, `gh`, CI monitoring, running tests, deployments-adjacent commands).
- **Opus (subagents via the Agent tool, `model: "opus"`)**: all implementation — writing and editing the code.

Never write implementation code yourself in this workflow; delegate it to Opus. Never delegate review or ops to Opus; keep those in the main session.

## Phase 1 — Deep planning (interactive)

Interview the user relentlessly about every aspect of this plan until you reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one by one. Ask about requirements, edge cases, user experience, data models, and failure modes. Do not write a plan document or code until the user says you are aligned.

Ground the interview in the real codebase: read the relevant code (or fan out Explore agents) between question rounds so your questions are informed, not generic. Keep iterating question rounds until no open decisions remain that an implementer would have to guess at.

## Phase 2 — Plan document

Once aligned, write the full implementation plan down. Pick the medium by context:

- **GitHub issue (preferred)** — when the work is clearly happening in a GitHub repo and you can create issues there (verify with a quick `gh issue list` or `gh repo view`; a permission error or missing remote means you can't). Create one with `gh issue create`, or edit the task's existing issue in place — the issue body **is** the plan, not a pointer to one.
- **Local plan file (fallback)** — when the repo isn't on GitHub, issues are disabled, `gh` isn't authenticated, or issue creation fails for any reason. Write the plan to a Markdown file in the repo/working directory (e.g. `PLAN-<slug>.md` at the root, or wherever the repo keeps such docs). Tell the user which file and why the fallback was used.

Either way, the plan must be complete enough that implementation can proceed smoothly and unequivocally: files to touch, interfaces, data shapes, test plan, rollout/verification steps, and explicit resolutions of everything decided in Phase 1. Structure the work items as a Markdown task list (`- [ ]`) so progress can be checked off as items land. If the plan changes later, rewrite the body in place so it reads as one coherent plan — no negotiation transcript.

## Phase 3 — Checkpoint: wait for explicit "go"

Show the user the plan location (issue link or file path) and a short summary, then **stop**. Do not begin implementation until the user gives an explicit go-ahead ("go", "proceed", or equivalent). Answering questions or amending the plan does not count as a go.

## Phase 4 — Implementation by Opus

On "go":

1. Prepare the branch yourself (pull main first, then cut a branch) — branch prep is ops, so it stays with you.
2. Spawn an Opus implementer: `Agent` with `model: "opus"`, pointing it at the plan document and the branch. The prompt must include the plan location (issue number/URL or file path), the branch name, the repo conventions that apply (comment rules, style), and the instruction to implement the plan exactly and run the relevant tests locally before finishing.
3. Keep the implementer's ID — later fix rounds go to the **same agent** via `SendMessage` so it retains context, rather than spawning fresh agents.
4. For large plans, you may split independent work items across parallel Opus agents (worktree isolation if they'd conflict), but one agent per coherent change is the default.

## Phase 5 — Review/fix loop (Fable reviews, Opus fixes)

Loop until clean:

1. **Review** the diff yourself, thoroughly: correctness against the plan document, edge cases, tests, style and comment-policy compliance, security where relevant. Be adversarial — approve nothing you haven't verified.
2. **Run every check available**: the full local test suite, linters, type checks, builds, and any integration/e2e suites the repo has. Then commit/push and watch CI (`gh pr checks --watch` or `gh run watch`).
3. If the review finds issues **or** any check is red: send the findings to the Opus implementer via `SendMessage` (precise file:line findings, not vague direction), let it fix, then re-review and re-run checks. You commit/push its results — git stays in your hands.
4. **Check off progress in the plan document** as items are realized and verified — tick the `- [x]` boxes in the issue body (`gh issue edit`) or the plan file. Only check an item after it has passed your review, not merely after Opus reports it done. The plan document should always reflect the true state of the work.
5. Repeat until the review passes with **zero** remaining findings **and** CI plus all local checks are green. No "minor issues left as follow-up" — everything is fixed or explicitly waived by the user.

## Phase 6 — Hand over the PR

Open the PR (`gh pr create`) with a body that references the plan document (issue link, or file path for a local plan) and summarizes what was built and how it was verified (checks run, CI status). Then hand the PR URL to the user for approval and **stop** — never merge it yourself.
