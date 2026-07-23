# Writing comments, docs, and issues

How to write the prose around code: source comments, reference documentation, and issue plans. The
through-line: write for a future reader who has none of your present context — not the git history,
not the conversation you just had, not the investigation you just ran.

## Code comments

**Code comments must be timeless.** A comment explains what the code does and why, for whoever reads it next — it is not a changelog, a record of a discussion, or a note about the development plan. Every comment must make sense to a future reader with no knowledge of how the code was built. Do **not** reference issues/PRs, migrations, development phases, or any other one-time context: no "moved out of the config (#13)", "used to be two functions", "renamed from X", "per the discussion", "as of this PR", "no longer / previously", and no development-phase or plan labels like "Stage 2", "step 0", "the next stage", "for now". Describe the current state and its rationale as if the code had always been this way. (Change history belongs in version control and the PR; roadmap and plan structure belong in issues or docs — not in the source.)

**Comments answer "what and why," never "why not X."** A comment must be justifiable from the code in front of the reader — not from a decision you just made or an investigation you just ran. Don't explain what the code deliberately *doesn't* do, don't contrast it with an alternative you considered, and don't pre-empt a question that only arises from your own recent context. "we use X instead of Y", "note: not the Z path", "this doesn't touch the cache" — all banned: the reader isn't asking, and naming the road not taken just makes them wonder about it. If choosing X over Y genuinely needs recording, that goes in the PR or a design doc, not the source. **Test: if you hadn't just researched this, would you still write the comment?** If it only exists to settle something you just learned, cut it.

## Documentation (reference material)

Reference documentation is a **static, decontextualized manual** — a growing body of *durable* understanding of what a system is, how it's built, and how to operate it safely. It is **not** a journal of recent work.

Every addition should pass this test: *would someone joining six months from now find it useful and unconfusing, with no other context?*

Concretely:

- **Capture facts and shapes, not events.** "Component A polls component B (not the other way round)" belongs here. "We restarted A on the 28th" does not.
- **No incident narration.** No "today's outage", "this week's recovery", "the time when X happened". If an incident *teaches* a durable fact (a failure mode, a gotcha, a recovery procedure), extract the fact; leave the narrative behind.
- **No PR / task / sprint context.** No "ahead of the migration", "for the upcoming release", "as of this PR". If a state is temporary, it doesn't belong here.
- **No relative time references.** Use absolute dates if a date is essential; usually it isn't.
- **Procedures are "why and what"; the exact commands live in a runnable artifact.** A subject doc explains why a procedure exists and what it does; the literal step-by-step (a script, a runbook command block, a tool/skill) lives separately and the doc links to it rather than duplicating it.

Where incident-flavored content *does* belong: a separate incidents / post-mortems area — write-ups, raw recovery transcripts, logs captured during an outage, and similar extended artifacts. Date-prefix them (`YYYY-MM-DD-<slug>`) or give each incident its own subdirectory. Quoted source citations inside a reference doc are fine when they ground a claim.

If a document is someone's personal journal or running log, treat it as theirs: don't repurpose it as a tracking log for your own work, and don't write to it unless it's yours to write.

When extracting from transcripts, reports, or write-ups: pull the durable fact, drop the speaker / date / scene-setting, and place it where a future reader would expect to find it. The chronological artifact, if worth keeping at all, goes in the incidents area — not in the reference manual.

**Adding knowledge:** find the doc the fact belongs in and add it inline. If nothing fits, that's a signal to create the right subject doc — not to drop a loose "notes" or "misc" file at the root.

## Issues (planning work)

Planning an issue means **editing that same issue** to carry the implementation detail — the issue body *is* the plan, not a pointer to one. Before writing the plan, do enough research and ask enough questions that implementation can proceed smoothly and unequivocally, with no open decisions left for the implementer to guess at.

**Issue plans are edited in place, with no historic debate.** When a plan changes, rewrite the text so the final plan is the only thing to read — never "we used to plan X but after decision Y we want Z". A reader arriving at the issue should see one coherent plan, not a negotiation transcript. (The tracker keeps the edit history; discussion belongs in the comment thread.)

It is preferred to have the issue description divided into two sections: "Goal" (short, mostly not changed during planning) and "Implementation" (as detailed as required, here the planning work shines).
