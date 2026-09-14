---
name: timer-chain
description: Defer a task by a total wait time using a chain of background timers, each capped at 25 minutes, then run the task when the last timer fires. Use whenever the user wants to wait a total duration (e.g. "wait 2 hours then deploy", "in 90 minutes run the tests") and then have something executed — especially because a single long `sleep` gets killed, so the wait must be split into short segments that survive.
---

# timer-chain

Wait a **total** duration and then execute a **task**, by chaining several short background timers instead of one long sleep. A single long `sleep` in this environment tends to be **killed** before it finishes; segments of **≤ 25 minutes** survive reliably (empirically a 30-minute segment completed but a 40-minute one was killed — so 25 min is the safe cap). This skill splits the total wait into ≤25-minute segments, runs them back-to-back, and executes the task only after the final segment completes.

## Inputs (from the invocation, or ask if missing)

- **Total wait time** — e.g. "70 minutes", "2 hours", "90m".
- **Task to run at the end** — a verbatim description or a slash command (e.g. "run the browser-download test", "/deploy"). Keep it exactly as given; it is executed only when the chain finishes.

If either is missing, ask for it before arming anything.

## Procedure

1. **Split the total into segments of ≤ 25 minutes (1500 s).**
   - `n = ceil(total_minutes / 25)`.
   - Distribute evenly so no segment exceeds 25 min (e.g. 70 min → `[25, 25, 20]` or an even `[24, 23, 23]`). The segment seconds must sum to the total.

2. **Persist chain state to a file** in your scratchpad directory (e.g. `timer-chain-state.json`) so the chain survives context summarization, `--resume`, or a lost in-context memory. Store:
   ```json
   {"segments_remaining": [1500, 1500, 1200], "completed": [], "task": "<verbatim task>", "note": "70 min total, 3 segments"}
   ```

3. **Arm the first segment**: run `sleep <seconds>` (the first value, ≤1500) with the **Bash tool and `run_in_background: true`**. A background sleep re-invokes you when it exits — that is the chain's clock. Never use a foreground sleep, and never a single sleep longer than 1500 s.

4. **Announce** briefly: `Timer 1/n (X min) armed — <task> runs after the chain (total T).`

5. **On each background-timer completion notification** (you are re-invoked when a `sleep` exits):
   - Read the state file. If the notification is a **normal completion**: move the just-finished segment from `segments_remaining` to `completed`, rewrite the state file.
   - **If `segments_remaining` is now non-empty** → arm the next segment (`sleep <next>`, ≤1500, in the background), announce `Timer k/n (X min) armed — …`, and end the turn.
   - **If `segments_remaining` is empty** → the full wait has elapsed: **execute the task now** (exactly as specified), then delete the state file and report the result.

6. **If a timer notification reports `killed` (not completed)** — the segment did not finish. Do **not** advance the chain. Re-arm **that same segment** (or its remaining time) as a fresh background `sleep`, note the retry, and continue. Because segments are ≤25 min, kills should be rare; this just makes them self-healing.

## Rules

- **Every segment ≤ 25 minutes (1500 s).** This is the whole point — it's what avoids the kill.
- **Only the final segment triggers the task.** Intermediate completions just arm the next timer.
- **Keep the task text verbatim** across the whole chain (it lives in the state file); do not paraphrase or act on it early.
- Do not busy-wait, poll, or run other work to "pass the time" — the background sleep re-invokes you; just end each turn after arming the next segment.
- The state file is the source of truth for how many segments remain and what the task is, so the chain is resumable even if the conversation is summarized between timers.
