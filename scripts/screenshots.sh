#!/bin/sh
# Renders the README screenshots from starship.toml into docs/assets/.
# Runbook: https://github.com/brei0x/starship/wiki/Development#screenshots
# The displayed path is a label starship renders as is, substituting its leading ~ itself.
# shellcheck disable=SC2088
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT=$ROOT/docs/assets
PREFIX=starship-theme-brei0x-
FAMILY="JetBrainsMono Nerd Font" # not the Mono variant: its icons are shrunk to one cell
COLUMNS=117 # the SVG window is sized from it
WORK=$(mktemp -d)
SERVER=
trap '[ -z "$SERVER" ] || docker rm -f "$SERVER" > /dev/null; chmod -R u+w "$WORK"; rm -rf "$WORK"' EXIT

SERVER_IMAGE=brei0x-starship-ssh-server
SERVER_NAME=web-01
STARSHIP_VERSION=v1.27.0 # same pin as the CI
STARSHIP_SHA256_AMD64=10c8eb4cb3b761d9bf59ea828444c2dab36c900b7d69a69e08814b286969df89 # x86_64-unknown-linux-musl
STARSHIP_SHA256_ARM64=341f5cbf24699fa0b27ec88965ad25f862ea09e15d35a543fd6ffdff1d2aa00d # aarch64-unknown-linux-musl

for tool in starship resvg python3 fish docker ssh ssh-keygen; do
  command -v "$tool" > /dev/null || { echo "$tool is required, see https://github.com/brei0x/starship/wiki/Development#screenshots" >&2; exit 1; }
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
    | sed "s/$(printf '\033')\[J//g; /^[[:space:]]*$/d" # fish prepends a clear-screen
}

# A throwaway Ubuntu server with sshd and the pinned Linux starship, reached over a real SSH session.
start_server() {
  docker build -q -t "$SERVER_IMAGE" \
    --build-arg VERSION="$STARSHIP_VERSION" \
    --build-arg SHA256_AMD64="$STARSHIP_SHA256_AMD64" --build-arg SHA256_ARM64="$STARSHIP_SHA256_ARM64" - > /dev/null << 'EOF'
FROM ubuntu:24.04
ARG VERSION SHA256_AMD64 SHA256_ARM64
RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -qq -y --no-install-recommends openssh-server curl ca-certificates tzdata > /dev/null \
 && arch=$(dpkg --print-architecture) \
 && case "$arch" in amd64) triple=x86_64; sum=$SHA256_AMD64 ;; arm64) triple=aarch64; sum=$SHA256_ARM64 ;; *) exit 1 ;; esac \
 && curl -fsSL -o /tmp/starship.tar.gz "https://github.com/starship/starship/releases/download/$VERSION/starship-$triple-unknown-linux-musl.tar.gz" \
 && echo "$sum  /tmp/starship.tar.gz" | sha256sum -c - \
 && tar -xzf /tmp/starship.tar.gz -C /usr/local/bin starship && rm /tmp/starship.tar.gz \
 && useradd -m -s /bin/bash deploy && useradd -m -s /bin/bash brei0x && mkdir -p /run/sshd \
 && rm -rf /var/lib/apt/lists/*
EOF
  ssh-keygen -q -t ed25519 -N '' -f "$WORK/id_ed25519"
  SERVER=$(docker run -d --hostname "$SERVER_NAME" -p 127.0.0.1::22 \
    -e PUBKEY="$(cat "$WORK/id_ed25519.pub")" -e ZONE="$(readlink /etc/localtime | sed 's#.*/zoneinfo/##')" \
    -v "$ROOT/starship.toml:/etc/starship.toml:ro" "$SERVER_IMAGE" \
    sh -c 'ln -sf "/usr/share/zoneinfo/$ZONE" /etc/localtime # same clock as the local prompts
           for home in /root /home/deploy /home/brei0x; do
             mkdir -p $home/.ssh && echo "$PUBKEY" > $home/.ssh/authorized_keys
             chown -R "$(stat -c %u:%g $home)" $home/.ssh && chmod 700 $home/.ssh
           done
           exec /usr/sbin/sshd -D -e')
  PORT=$(docker port "$SERVER" 22/tcp | sed -n '1s/.*://p')
  for _ in 1 2 3 4 5 6 7 8 9 10; do remote deploy true 2> /dev/null && return; sleep 1; done
  echo "the SSH server did not come up" >&2
  exit 1
}

# remote <user> <command>: runs a command over SSH on the throwaway server
remote() {
  user=$1
  shift
  ssh -q -i "$WORK/id_ed25519" -p "$PORT" -o BatchMode=yes -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$user@127.0.0.1" "$@"
}

# server_prompt <user> <directory>: the prompt the server draws for that user in that directory
server_prompt() {
  remote "$1" "cd $2 && STARSHIP_CONFIG=/etc/starship.toml starship prompt -w $COLUMNS" | sed '/^[[:space:]]*$/d'
}

# render <name>: ANSI on stdin -> docs/assets/<prefix><name>.png
render() {
  python3 "$ROOT/scripts/prompt-svg.py" --font "$FAMILY" > "$WORK/$1.svg"
  resvg --zoom 2 "$WORK/$1.svg" "$OUT/$PREFIX$1.png"
  echo "$OUT/$PREFIX$1.png"
}

mkdir -p "$OUT"
prompt "$WORK/starship" "~/Developer/starship" | render git
prompt "$WORK/api" "~/Developer/api" | render languages
start_server
server_prompt deploy '~' | render ssh
server_prompt root /var/log | render root
prompt "$WORK/locked" "/etc" | render read-only
prompt "$WORK/home" "~" -d 65000 -s 1 | render duration-error
VI_SHELL=fish prompt "$WORK/home" "~" -k default | render vim # keymaps need a vi-capable shell; fish adds no wrappers

# Social preview: a macOS session hopping to the Linux server, and the same repository on Windows.
COLUMNS=92
BLOCK_GAP=8 # px between prompt blocks, under half a line (18.5 px)
typed() { sed "\$s|\$|$1|"; } # the command typed after the prompt character
{
  prompt "$WORK/home" "~" | typed "cd Developer/starship"
  prompt "$WORK/starship" "~/Developer/starship" | typed "ssh brei0x@$SERVER_NAME"
  server_prompt brei0x '~'
} | python3 "$ROOT/scripts/prompt-svg.py" --font "$FAMILY" --block-gap $BLOCK_GAP --title zsh > "$WORK/social-macos.svg"
# shortcut: drawn on macOS with the Windows icon and separators; the Prompt CI job checks the real Windows render.
prompt "$WORK/starship" "~/Developer/starship" \
  | sed "s#/#\\\\#g; s/$(printf '\357\214\202')/$(printf '\363\260\215\262')/" | typed "git push" \
  | python3 "$ROOT/scripts/prompt-svg.py" --font "$FAMILY" --block-gap $BLOCK_GAP --chrome windows --title PowerShell > "$WORK/social-windows.svg"
python3 "$ROOT/scripts/social-preview.py" --font "$FAMILY" "$WORK/social-macos.svg" "$WORK/social-windows.svg" > "$WORK/social.svg"
resvg "$WORK/social.svg" "$OUT/${PREFIX}social-preview.png"
echo "$OUT/${PREFIX}social-preview.png"
