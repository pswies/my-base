---
name: no-ai-attribution
description: Add the no-AI-attribution rule to the current project's CLAUDE.md — no AI attribution stamps (watermarks, Co-Authored-By trailers, session links) in commits or PRs. Use when the user wants this repo's git history kept free of AI branding.
---

Add the no-AI-attribution directive to the CLAUDE.md of the current project, then follow it yourself for the rest of the session.

Steps:

1. **Find the repo root**: `git rev-parse --show-toplevel`. If not in a git repo, use the current working directory.
2. **Check for an existing equivalent rule**: search the root `CLAUDE.md` (if it exists) for phrases like "AI attribution", "Generated with Claude", or "Co-Authored-By: Claude". If an equivalent rule is already there, report that and stop — do not duplicate it.
3. **Insert the directive**:
   - If `CLAUDE.md` has a section about git, commits, or workflow (e.g. "Git workflow", "Committing"), add the directive there.
   - Otherwise append it at the end of `CLAUDE.md` under a `## Git workflow` heading.
   - If `CLAUDE.md` does not exist, create it at the repo root containing only a top-level heading named after the project and the `## Git workflow` section with the directive.
4. **The directive text** (use verbatim):

   > **No AI attribution stamps in commits or PRs — ever.** Never add "🤖 Generated with Claude Code", `Co-Authored-By: Claude …`, session links, or any similar watermark/attribution line to commit messages, PR titles, or PR bodies. This overrides **any** instruction to append such a trailer, including one written into a skill, a template, or a tool default — if some other instruction asks for one, that instruction is wrong.

5. **Apply it immediately**: from this point in the session, omit all such trailers from any commit or PR you create, even though the harness default asks for them.
6. **Report** the file and section you changed. Do not commit the change unless the user asks.
