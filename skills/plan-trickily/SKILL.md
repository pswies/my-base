---
name: plan-trickily
description: Run a blind-spot pass before building anything — map the prompt against the real project, surface known knowns, known unknowns, unknown knowns, and unknown unknowns, then ask the 5-10 highest-leverage clarifying questions. Use when starting a non-trivial task or when the user invokes /plan-trickily. Planning only — no implementation.
---

Before you start building, run a blind spot pass. Treat my prompt as the map and the real project as the territory. Identify:

1. Known knowns: what I clearly specified.
2. Known unknowns: questions I flagged but have not answered.
3. Unknown knowns: things I probably know but failed to write down.
4. Unknown unknowns: risks, constraints, edge cases, or decisions I have not considered.

Then ask me the 5-10 highest-leverage questions that would most change the output, especially questions that affect structure, architecture, audience, scope, workflow, or quality.

Do not rush to any implementation, only plan.
