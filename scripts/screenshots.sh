#!/bin/sh
# Renders the README screenshots from starship.toml into screenshots/. Runbook: docs/SETUP.md
# The displayed path is a label starship renders as is, substituting its leading ~ itself.
# shellcheck disable=SC2088
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT=$ROOT/screenshots
PREFIX=starship-theme-brei0x-
FAMILY="JetBrainsMono Nerd Font" # not the Mono variant: its icons are shrunk to one cell
COLUMNS=96
WORK=$(mktemp -d)
trap 'chmod -R u+w "$WORK"; rm -rf "$WORK"' EXIT

for tool in starship resvg python3; do
  command -v "$tool" > /dev/null || { echo "$tool is required, see docs/SETUP.md" >&2; exit 1; }
done
resvg --list-fonts 2> /dev/null | grep -c "$FAMILY" > /dev/null || { echo "font not installed: $FAMILY" >&2; exit 1; }

# Fixtures: a home-like folder, a Terraform repo one commit ahead with every git_status flag,
# a Node + Python project and a read-only folder.
mkdir -p "$WORK/home" "$WORK/api" "$WORK/locked"
: > "$WORK/api/package.json"
: > "$WORK/api/pyproject.toml"
chmod 555 "$WORK/locked"
git init -q --bare -b main "$WORK/remote.git"
git clone -q "$WORK/remote.git" "$WORK/starship" 2> /dev/null # empty-repository warning
(
  cd "$WORK/starship"
  git config user.name screenshots && git config user.email screenshots@localhost && git config commit.gpgsign false
  echo 'resource "null_resource" "demo" {}' > main.tf
  git add main.tf && git commit -qm "feat: initial resource" && git push -q origin main
  echo '# ahead' >> main.tf && git commit -qam "docs: comment" # ahead by one
  echo '# modified' >> main.tf                               # modified
  : > variables.tf && git add variables.tf                    # staged
  : > outputs.tf                                              # untracked
)

# prompt <path> <displayed path> [starship prompt flags...]
prompt() {
  path=$1 shown=$2
  shift 2
  STARSHIP_SHELL="${VI_SHELL:-}" STARSHIP_CONFIG="$ROOT/starship.toml" \
    starship prompt -w $COLUMNS --path="$path" -P "$shown" "$@" 2> /dev/null \
    | sed "s/$(printf '\033')\[J//g; /^[[:space:]]*$/d; s/$(hostname)/hostname.net/g" # fish prepends a clear-screen
}

# render <name>: ANSI on stdin -> screenshots/<prefix><name>.png
render() {
  python3 "$ROOT/scripts/prompt-svg.py" --font "$FAMILY" > "$WORK/$1.svg"
  resvg --zoom 2 "$WORK/$1.svg" "$OUT/$PREFIX$1.png"
  echo "$OUT/$PREFIX$1.png"
}

mkdir -p "$OUT"
{
  prompt "$WORK/home" "~"; echo "cd Developer/starship"
  prompt "$WORK/starship" "~/Developer/starship"; echo "terraform plan"
  prompt "$WORK/starship" "~/Developer/starship" -d 65000; echo "false"
  prompt "$WORK/starship" "~/Developer/starship" -s 1; echo
} | render preview
prompt "$WORK/home" "~" | render home
prompt "$WORK/starship" "~/Developer/starship" | render git
prompt "$WORK/api" "~/Developer/api" | render languages
SSH_CONNECTION="10.0.0.2 51234 10.0.0.1 22" prompt "$WORK/home" "~" | render ssh
prompt "$WORK/locked" "/etc" | render read-only
prompt "$WORK/home" "~" -d 65000 -s 1 | render duration-error
VI_SHELL=fish prompt "$WORK/home" "~" -k default | render vim # keymaps need a vi-capable shell; fish adds no wrappers
