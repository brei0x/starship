#!/bin/sh
# Smoke-tests starship.toml on the current machine: config, hostname and username rules, shell inits.
# Usage: sh scripts/test-prompt.sh [capture-dir]   (runs on macOS, Linux and Windows Git Bash)
# Runbook: https://github.com/brei0x/starship/wiki/Development#prompt-tests
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
command -v cygpath > /dev/null && ROOT=$(cygpath -m "$ROOT") # starship.exe needs a Windows path
CAPTURE=${1:-}
SSH_FAKE="10.0.0.2 51234 10.0.0.1 22"
export STARSHIP_CONFIG="$ROOT/starship.toml"
FAILED=0

pass() { echo "ok   $*"; }
fail() { echo "FAIL $*" >&2; FAILED=1; }
plain() { sed "s/$(printf '\033')\[[0-9;]*m//g"; } # strips SGR codes

# prompt [env assignments...]: the left prompt as plain text, with SSH variables cleared first
prompt() { env -u SSH_CONNECTION -u SSH_CLIENT -u SSH_TTY "$@" starship prompt -w 117 | plain; }

contains() { case $1 in *"$2"*) return 0 ;; esac; return 1; }

is_admin() {
  case $(uname -s) in
    MINGW* | MSYS* | CYGWIN*) net session > /dev/null 2>&1 ;; # starship treats an elevated token as root
    *) [ "$(id -u)" = 0 ] ;;
  esac
}

echo "starship $(starship --version | sed -n '1s/starship //p') on $(uname -s) $(uname -m)"

warnings=$(starship print-config 2>&1 > /dev/null)
[ -z "$warnings" ] && pass "config has no warnings" || fail "config warnings: $warnings"

host=$(hostname | cut -d. -f1) # trim_at = '.' keeps the first label
user=${USER:-${USERNAME:-$(id -un)}}
case $(uname -s) in MINGW* | MSYS* | CYGWIN*) is_admin && user=Administrator ;; esac # starship's name for an elevated token
local_prompt=$(prompt)
ssh_prompt=$(prompt SSH_CONNECTION="$SSH_FAKE")

contains "$local_prompt" "$host" && fail "hostname shown locally: $local_prompt" || pass "hostname hidden locally"
contains "$ssh_prompt" "$host" && pass "hostname shown over SSH" || fail "hostname missing over SSH: $ssh_prompt"
contains "$ssh_prompt" " $user " && pass "username shown over SSH" || fail "username missing over SSH: $ssh_prompt"
if is_admin; then
  contains "$local_prompt" " $user " && pass "username shown locally as root/admin" || fail "username missing as root/admin: $local_prompt"
else
  contains "$local_prompt" " $user " && fail "username shown locally: $local_prompt" || pass "username hidden locally"
fi
[ -n "$(starship module os | plain | tr -d ' ')" ] && pass "OS symbol rendered" || fail "no OS symbol"

# Each installed shell must load the init and draw the prompt character.
check_shell() {
  out=$(env -u SSH_CONNECTION "$@" 2>&1 | plain) || true
  contains "$out" "❯" && pass "$1 draws the prompt" || fail "$1 prompt: $out"
}
command -v bash > /dev/null && check_shell bash --norc --noprofile -c 'eval "$(starship init bash)"; starship_precmd; printf "%s" "$PS1"'
command -v zsh > /dev/null && check_shell zsh -f -c 'eval "$(starship init zsh)"; setopt prompt_subst; print -P "$PROMPT"'
command -v fish > /dev/null && check_shell fish --no-config -c 'starship init fish | source; fish_prompt'
command -v pwsh > /dev/null && check_shell pwsh -NoProfile -Command 'Invoke-Expression (& starship init powershell --print-full-init | Out-String); prompt'

if [ -n "$CAPTURE" ]; then
  mkdir -p "$CAPTURE"
  name=$(uname -s | tr '[:upper:]' '[:lower:]')
  env -u SSH_CONNECTION starship prompt -w 117 > "$CAPTURE/$name-local.ansi"
  SSH_CONNECTION="$SSH_FAKE" starship prompt -w 117 > "$CAPTURE/$name-ssh.ansi"
  pass "captures written to $CAPTURE"
fi

exit $FAILED
