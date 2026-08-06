#!/usr/bin/env bash
# Removes Claude/Anthropic attribution lines from commit messages:
#   - "Co-Authored-By: Claude ... <...@anthropic.com>" trailers
#     (these are what make GitHub show "pswies and claude committed")
#   - "Generated with [Claude Code]" lines
# Everything else about the history is preserved: file contents, authors,
# dates, merge structure. Only the rewritten commits get new SHAs.
#
# Usage:
#   ./strip-claude-trailers.sh <N>    # rewrite the last N commits
#   ./strip-claude-trailers.sh all    # rewrite the whole branch history
#
# After running, a backup of the old history is kept in refs/original/.
# If the branch was already pushed, follow up with:
#   git push --force-with-lease
set -euo pipefail

usage() {
  echo "usage: $0 <number-of-commits|all>" >&2
  exit 1
}

[ $# -eq 1 ] || usage
arg=$1

if ! git diff-index --quiet HEAD --; then
  echo "error: uncommitted changes in the working tree; commit or stash them first" >&2
  exit 1
fi

total=$(git rev-list --count HEAD)
if [ "$arg" = "all" ]; then
  range=HEAD
elif [[ "$arg" =~ ^[1-9][0-9]*$ ]]; then
  if [ "$arg" -ge "$total" ]; then
    range=HEAD
  else
    range="HEAD~$arg..HEAD"
  fi
else
  usage
fi

msg_filter=$(mktemp)
trap 'rm -f "$msg_filter"' EXIT
cat >"$msg_filter" <<'EOF'
grep -ivE '^[[:space:]]*co-authored-by:.*(claude|anthropic)|generated with.*claude ?code' |
awk 'NF {last = NR} {line[NR] = $0} END {for (i = 1; i <= last; i++) print line[i]}'
EOF

FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f \
  --msg-filter "sh $msg_filter" "$range"

echo
echo "Done. The old history is backed up under refs/original/."
echo "If this branch is already on a remote, update it with:"
echo "  git push --force-with-lease"
