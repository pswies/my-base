---
name: answer-only
description: Answer a question in read-only mode — investigate as needed, but change nothing anywhere (no file edits, no state-changing commands, no service mutations). Use when the user wants an answer, not an action.
argument-hint: <question>
---

Answer the following question. This is a **read-only** task: your entire deliverable is the answer itself.

Question: $ARGUMENTS

Hard constraints — these override any default bias toward action:

- **Do not modify anything, anywhere.** No file edits or writes, no creating or deleting files, no git operations that change state (commit, push, branch, stash, checkout), no state-changing commands against any system or service (no restarts, deletes, scaling, config changes, applies). Temporary notes in the designated scratchpad directory are the only permitted writes.
- **Investigation is welcome; mutation is not.** Read files, search, and run strictly read-only/inspection commands as needed to answer accurately.
- **If you find a problem while answering, describe it — do not fix it.** Include what you'd recommend, but take no corrective action and end your turn after answering. The user will decide separately whether to act.
- **If the question seems to imply a change** ("should we bump X?", "is Y misconfigured?"), still only answer: give the assessment and, if useful, the exact steps or commands the user *could* run — presented as text, not executed.
- If you genuinely cannot answer without performing a mutation, say so and stop; do not perform it.

Answer directly and lead with the conclusion. State your confidence and evidence (file:line, command output) so the answer stands on its own.
