#!/usr/bin/env bash
# update-all.sh — update software across every channel on this Mac.
#
# Run daily by the launchd agent ~/Library/LaunchAgents/com.pswies.update-all.plist
# (opens a Terminal window so sudo/cask prompts are visible).
#
# Each channel is independent and guarded by `command -v`, so missing tools are
# skipped rather than failing the run. Re-discover what you have with:
#   brew leaves; brew list --cask; npm ls -g --depth=0; uv tool list; ls ~/.cargo/bin ~/go/bin

set -uo pipefail   # NOT -e: one channel failing must not abort the rest

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }

step "Homebrew — formulae + ALL casks (incl. self-updating ones)"
brew update
brew upgrade --yes
brew upgrade --cask --greedy --yes   # the part the old brew-only job missed
brew cleanup -s

step "Mac App Store (mas)"
if command -v mas >/dev/null 2>&1; then mas upgrade; else
  echo "mas not installed — 'brew install mas' to manage App Store apps from CLI"
fi

step "macOS system updates (may prompt for sudo; add --restart to auto-reboot)"
softwareupdate -ia

step "npm global packages (nvm-active node)"
command -v npm >/dev/null 2>&1 && npm update -g

step "uv tools"
command -v uv >/dev/null 2>&1 && uv tool upgrade --all

step "Rust toolchain + cargo-installed binaries"
command -v rustup >/dev/null 2>&1 && rustup update
# cargo-install-update comes from: cargo install cargo-update
command -v cargo-install-update >/dev/null 2>&1 && cargo install-update -a

step "Go-installed binaries"
# gup comes from: go install github.com/nao1215/gup@latest
command -v gup >/dev/null 2>&1 && gup update

step "conda (miniforge) packages"
command -v conda >/dev/null 2>&1 && conda update --all -y

step "Done. GUI apps with built-in updaters (browsers, Slack, Cursor, …) self-update;"
echo    "    adopt them into Homebrew (see notes) to bring them under this script too."
