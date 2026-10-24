# Setup

Commands and runbooks. The README only says what the project is and how to install the theme.

## Validate the theme

```bash
taplo check starship.toml && taplo fmt --check starship.toml
STARSHIP_CONFIG=./starship.toml starship print-config --default false
```

`brew install taplo starship` on macOS. CI runs the same checks plus `lychee` on every Markdown link.

## Regenerate the screenshots

```bash
sh scripts/screenshots.sh
```

Writes `screenshots/starship-theme-brei0x-*.png` (117 columns, about 2230 px wide at 2x) from
`starship.toml`: one `preview` sequence and one image per state (`home`, `git`, `languages`, `ssh`,
`read-only`, `duration-error`, `vim`). Every state is rendered by `starship prompt` against temporary fixtures, so no real shell, repository or
server is involved: the git state is a scratch repository one commit ahead with modified, staged and
untracked files, the SSH state sets `SSH_CONNECTION`, the hostname is rewritten to `hostname.net`.

`scripts/prompt-svg.py` turns the ANSI output into an SVG the way a terminal draws it, one cell per code
point with the backgrounds sized on the powerline glyph box, and `resvg` rasterizes it with the installed
font. `freeze` and the other screenshot tools lay text out proportionally, which misplaces the colored
segments. Requirements, macOS:

```bash
brew install starship resvg
brew install --cask font-jetbrains-mono-nerd-font
```

The font must be the plain `JetBrainsMono Nerd Font`, not the `Mono` variant whose icons are shrunk
to one cell. Every glyph in `starship.toml` must exist in it, or resvg warns and falls back to a
system font.

Not reproducible this way, so not captured: the root user (uid 0). Time and memory values change on
every run, so a regeneration always produces a diff.

## Release

Every push to `main` with a green CI is tagged and released by `tekalib/.workflows` `release.yml`: the
next version comes from the Conventional Commits since the last tag (`feat` minor, `fix` and the rest
patch, `!` major). Dependabot patch and minor bumps merge on their own through the
`tekalib-automation` App, which needs `AUTOMATION_APP_KEY` as an Actions and a Dependabot secret.
