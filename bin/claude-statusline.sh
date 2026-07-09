#!/usr/bin/env bash
# Claude Code status line: model name, followed by uniform "label NN%"
# segments — context usage, Claude.ai 5-hour / 7-day rate-limit usage, and
# (when available) extra-usage spend-limit usage — with each percentage
# number color-coded green/yellow/red by usage level.

input=$(cat)

RESET='\033[0m'
DIM='\033[2m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
CYAN='\033[36m'
# Mid-green (256-color, noticeably darker than the standard-green used on
# percentage values) for the structural elements: metric labels
# (ctx/5h/7d/spend), the model family name, and the directory/project name.
# Separators and parenthetical extras (token count, countdown, date) stay
# dim; percentage value colors (GREEN/YELLOW/RED below) are unchanged.
LABEL='\033[1;38;5;28m'

# Model family only (first word of the display name), e.g. "Fable 5" ->
# "Fable", "Opus 4.8 (1M context)" -> "Opus".
model=$(echo "$input" | jq -r '(.model.display_name // "unknown") | split(" ")[0]')

# Current directory, basename only. Omitted when workspace.current_dir isn't
# present in the payload.
cwd_path=$(echo "$input" | jq -r '.workspace.current_dir // empty')
dir_str=""
if [ -n "$cwd_path" ]; then
  dir_name=$(basename "$cwd_path")
  dir_str=$(printf "${LABEL}%s${RESET}" "$dir_name")
fi

used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# Time until the 5-hour rate-limit window resets, compact-formatted as
# "XhYYm" (>=1h) or "XXm" (<1h). Hidden when resets_at is absent; a past
# timestamp is clamped to 0 rather than shown as negative.
five_resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
five_reset_str=""
if [ -n "$five_resets_at" ]; then
  five_remaining=$(( five_resets_at - $(date +%s) ))
  [ "$five_remaining" -lt 0 ] && five_remaining=0
  five_hours=$(( five_remaining / 3600 ))
  five_minutes=$(( (five_remaining % 3600) / 60 ))
  if [ "$five_hours" -ge 1 ]; then
    five_reset_str=$(printf "%dh%02dm" "$five_hours" "$five_minutes")
  else
    five_reset_str=$(printf "%dm" "$five_minutes")
  fi
fi

# Date the 7-day rate-limit window ends, e.g. "Jul 14". Hidden when
# resets_at is absent. Tries BSD `date -r` (macOS) first, falls back to
# GNU `date -d` for portability.
week_resets_at=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
week_reset_str=""
if [ -n "$week_resets_at" ]; then
  week_reset_str=$(date -r "$week_resets_at" "+%b %-d" 2>/dev/null || date -d "@$week_resets_at" "+%b %-d" 2>/dev/null)
fi

# Token count backing the ctx percentage, for display alongside it (e.g.
# "42% (85k)"). Prefer the payload's own running total; if that's absent
# but we still have a percentage and the window size, derive it. Omitted
# entirely (graceful fallback) when none of that is available.
ctx_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty' 2>/dev/null)
if [ -z "$ctx_tokens" ] && [ -n "$used_pct" ]; then
  ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty' 2>/dev/null)
  if [ -n "$ctx_size" ]; then
    ctx_tokens=$(awk -v p="$used_pct" -v s="$ctx_size" 'BEGIN { printf "%d", (p / 100) * s }')
  fi
fi

# Pay-as-you-go / extra-usage spend-limit data — NOT the per-session cost
# estimate (that's usage already covered by the subscription plan, not real
# money, and is deliberately excluded here). Extra-usage billing fields
# aren't part of the stable statusLine schema yet, so probe a handful of
# plausible spend-limit locations and take the first hit; stays blank (and
# hidden) until Claude Code actually exposes one of these.
spend_pct=$(echo "$input" | jq -r '
  (.rate_limits.extra_usage.used_percentage
    // .rate_limits.spend_limit.used_percentage
    // .usage.spend_limit.used_percentage
    // .spend_limit.used_percentage)
  // empty' 2>/dev/null)
spend_usd=$(echo "$input" | jq -r '
  (.rate_limits.extra_usage.used_usd
    // .rate_limits.spend_limit.used_usd
    // .usage.spend_limit.used_usd
    // .spend_limit.used_usd)
  // empty' 2>/dev/null)
spend_limit_usd=$(echo "$input" | jq -r '
  (.rate_limits.extra_usage.limit_usd
    // .rate_limits.spend_limit.limit_usd
    // .usage.spend_limit.limit_usd
    // .spend_limit.limit_usd)
  // empty' 2>/dev/null)

# Compact-format a raw token count: "85k"/"123k" above 1000, the raw number
# below. Prints nothing if given an empty value.
format_tokens() {
  local n="$1"
  [ -z "$n" ] && return
  if [ "$n" -ge 1000 ]; then
    awk -v n="$n" 'BEGIN { printf "%dk", int((n / 1000) + 0.5) }'
  else
    printf '%d' "$n"
  fi
}

# Render one "label NN% (extra)" segment: the label is mid-green (the
# structural element of the segment), the percentage number is color-coded
# green/yellow/red by usage level (same thresholds for every metric:
# context, 5h, 7d, spend), and the trailing "(extra)" — only appended when
# a third argument is given — stays dim. Prints nothing if no percentage
# was given.
render_metric() {
  local label="$1" pct="$2" extra="$3"
  [ -z "$pct" ] && return
  local pct_int
  pct_int=$(printf '%.0f' "$pct")
  [ "$pct_int" -gt 100 ] && pct_int=100
  [ "$pct_int" -lt 0 ] && pct_int=0
  local color
  if [ "$pct_int" -ge 80 ]; then
    color="$RED"
  elif [ "$pct_int" -ge 50 ]; then
    color="$YELLOW"
  else
    color="$GREEN"
  fi
  printf "${LABEL}%s${RESET} ${color}%d%%${RESET}" "$label" "$pct_int"
  [ -n "$extra" ] && printf " ${DIM}(%s)${RESET}" "$extra"
}

# Uniform metric segments: context, 5h rate limit, 7d rate limit. Rate-limit
# segments are omitted entirely when their data isn't present yet.
segments=()

[ -n "$dir_str" ] && segments+=("$dir_str")

ctx_tokens_display=$(format_tokens "$ctx_tokens")
ctx_str=$(render_metric "ctx" "$used_pct" "$ctx_tokens_display")
[ -z "$ctx_str" ] && ctx_str=$(printf "${LABEL}ctx${RESET} ${DIM}n/a${RESET}")
segments+=("$ctx_str")

five_str=$(render_metric "5h" "$five" "$five_reset_str")
[ -n "$five_str" ] && segments+=("$five_str")

week_str=$(render_metric "7d" "$week" "$week_reset_str")
[ -n "$week_str" ] && segments+=("$week_str")

# Extra-usage spend-limit usage, appended as its own uniform-format segment
# when present: prefer a $used/$limit pair, fall back to a bare percentage.
if [ -n "$spend_usd" ] && [ -n "$spend_limit_usd" ]; then
  segments+=("$(printf "${LABEL}spend${RESET} ${CYAN}\$%.2f/\$%.2f${RESET}" "$spend_usd" "$spend_limit_usd")")
elif [ -n "$spend_pct" ]; then
  spend_str=$(render_metric "spend" "$spend_pct")
  [ -n "$spend_str" ] && segments+=("$spend_str")
fi

out=$(printf "${LABEL}%s${RESET}" "$model")
for seg in "${segments[@]}"; do
  out="${out}$(printf " ${DIM}|${RESET} %s" "$seg")"
done

printf "%s" "$out"
