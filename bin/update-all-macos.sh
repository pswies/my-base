#!/usr/bin/env bash
# update-all.sh — update software across every channel on this Mac.
#
# Run daily by the launchd agent ~/Library/LaunchAgents/com.pswies.update-all-macos.plist
# (opens a Terminal window so sudo/cask prompts are visible).
#
# Each channel is independent and guarded by `command -v`, so missing tools are
# skipped rather than failing the run. Re-discover what you have with:
#   brew leaves; brew list --cask; npm ls -g --depth=0; uv tool list; ls ~/.cargo/bin ~/go/bin
#   mise ls; nix profile list; code --list-extensions

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

step "mise-managed tools (node, kubectl, helm, opentofu, terragrunt, yq, …)"
command -v mise >/dev/null 2>&1 && mise upgrade --yes

step "npm global packages (mise-managed node)"
command -v npm >/dev/null 2>&1 && npm update -g

step "uv tools"
command -v uv >/dev/null 2>&1 && uv tool upgrade --all

step "Google Cloud SDK components (standalone install in /opt/google-cloud-sdk)"
# /opt/google-cloud-sdk was installed root-owned. Run ONCE: sudo chown -R "$USER" /opt/google-cloud-sdk
# (running gcloud under sudo would leave root-owned files in ~/.config/gcloud)
command -v gcloud >/dev/null 2>&1 && gcloud components update --quiet

step "Rust toolchain + cargo-installed binaries"
command -v rustup >/dev/null 2>&1 && rustup update
# cargo-install-update comes from: cargo install cargo-update
command -v cargo-install-update >/dev/null 2>&1 && cargo install-update -a

step "Go-installed binaries"
# gup comes from: go install github.com/nao1215/gup@latest
command -v gup >/dev/null 2>&1 && gup update

step "VS Code + Cursor extensions"
command -v code   >/dev/null 2>&1 && code --update-extensions
command -v cursor >/dev/null 2>&1 && cursor --update-extensions

step "Neovim plugins (lazy.nvim)"
if command -v nvim >/dev/null 2>&1 && [ -d "$HOME/.local/share/nvim/lazy" ]; then
  nvim --headless "+Lazy! sync" +qa
fi

step "nix profile"
command -v nix >/dev/null 2>&1 && nix profile upgrade --all

step "conda (miniforge) packages"
command -v conda >/dev/null 2>&1 && conda update --all -y

step "Done. GUI apps with built-in updaters (browsers, Slack, Cursor, …) self-update;"
echo    "    adopt them into Homebrew (see notes) to bring them under this script too."
