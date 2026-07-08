#!/usr/bin/env bash
# Claude Code status line: model name, followed by uniform "label [bar] NN%"
# segments — context usage, Claude.ai 5-hour / 7-day rate-limit usage, and
# (when available) extra-usage spend-limit usage — all color-coded
# green/yellow/red by usage level.

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "unknown"')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

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

RESET='\033[0m'
DIM='\033[2m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
CYAN='\033[36m'

repeat() {
  local char="$1" count="$2" out="" i
  for ((i = 0; i < count; i++)); do
    out+="$char"
  done
  printf '%s' "$out"
}

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

# Render one "label [bar] NN% (extra)" segment, color-coded green/yellow/red
# by usage level (same thresholds for every metric: context, 5h, 7d, spend).
# The trailing "(extra)" is only appended when a third argument is given.
# Prints nothing if no percentage was given.
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
  local filled=$((pct_int / 10))
  local empty=$((10 - filled))
  local fill_str empty_str
  fill_str=$(repeat "█" "$filled")
  empty_str=$(repeat "░" "$empty")
  printf "${DIM}%s${RESET} ${color}[%s%s]${RESET} %d%%" "$label" "$fill_str" "$empty_str" "$pct_int"
  [ -n "$extra" ] && printf " ${DIM}(%s)${RESET}" "$extra"
}

# Uniform metric segments: context, 5h rate limit, 7d rate limit. Rate-limit
# segments are omitted entirely when their data isn't present yet.
segments=()

ctx_tokens_display=$(format_tokens "$ctx_tokens")
ctx_str=$(render_metric "ctx" "$used_pct" "$ctx_tokens_display")
[ -z "$ctx_str" ] && ctx_str=$(printf "${DIM}ctx [..........] n/a${RESET}")
segments+=("$ctx_str")

five_str=$(render_metric "5h" "$five")
[ -n "$five_str" ] && segments+=("$five_str")

week_str=$(render_metric "7d" "$week")
[ -n "$week_str" ] && segments+=("$week_str")

# Extra-usage spend-limit usage, appended as its own uniform-format segment
# when present: prefer a $used/$limit pair, fall back to a bare percentage.
if [ -n "$spend_usd" ] && [ -n "$spend_limit_usd" ]; then
  segments+=("$(printf "${DIM}spend${RESET} ${CYAN}\$%.2f/\$%.2f${RESET}" "$spend_usd" "$spend_limit_usd")")
elif [ -n "$spend_pct" ]; then
  spend_str=$(render_metric "spend" "$spend_pct")
  [ -n "$spend_str" ] && segments+=("$spend_str")
fi

out=$(printf "${DIM}%s${RESET}" "$model")
for seg in "${segments[@]}"; do
  out="${out}$(printf " ${DIM}|${RESET} %s" "$seg")"
done

printf "%s" "$out"
