# Brei0x Starship Theme

A clean and professional Starship prompt theme inspired by Powerlevel10k, featuring a two-line layout with rich information and custom color palette.

![CI](https://github.com/brei0x/starship/actions/workflows/ci.yml/badge.svg)

**Stack**: [Starship](https://starship.rs/) config (`starship.toml`) · Nerd Font glyphs · taplo, Starship and lychee checks in GitHub Actions

## Preview

![Preview](screenshots/starship-theme-brei0x-preview.png)

### Git repository
![Git](screenshots/starship-theme-brei0x-git.png)
*Branch, then modified, staged and untracked files, one commit ahead, and the Terraform version.*

### Languages
![Languages](screenshots/starship-theme-brei0x-languages.png)
*Node.js and Python detected from the project files.*

### SSH session
![SSH](screenshots/starship-theme-brei0x-ssh.png)
*The username appears over SSH (and for root), the hostname is always shown.*

### Read-only directory
![Read-only](screenshots/starship-theme-brei0x-read-only.png)
*A lock marks a directory you cannot write to.*

### Command duration
![Duration](screenshots/starship-theme-brei0x-duration-error.png)
*Execution time after a long-running command.*

### Vim normal mode
![Vim](screenshots/starship-theme-brei0x-vim.png)
*The prompt character flips when the line editor is in normal mode.*

Regenerate these images with `sh scripts/screenshots.sh`, see the [Development](../../wiki/Development#screenshots) wiki page.

## Features

- **Two-line prompt** with powerline-style segments
- **OS detection** with custom icons for 40+ operating systems
- **Git integration** showing branch name and status (ahead/behind/diverged)
- **Multi-language support** for 20+ programming languages and tools
- **System monitoring** with memory usage percentage
- **SSH hostname display** with dedicated icon
- **Command duration** tracking
- **Vim mode indicators** (normal, replace, visual)
- **Read-only directory indicator** with lock icon
- **Smart path truncation** with folder icon substitutions
- **Custom color palette** with professional, muted tones

## Documentation

Full documentation is available in the [wiki](../../wiki):

| Page | Description |
|------|-------------|
| [Installation](../../wiki/Installation) | Installation methods and shell requirements |
| [Modules](../../wiki/Modules) | All prompt modules and directory substitutions |
| [Color Palette](../../wiki/Color-Palette) | Theme colors and hex values |
| [Customization](../../wiki/Customization) | How to personalize the theme |
| [Development](../../wiki/Development) | Local checks, screenshots, releases and contribution guide |
| [Security policy](https://github.com/brei0x/starship/security/policy) | How to report a vulnerability; served by `brei0x/.github` |

## Quick start

**Requirements**: [Starship](https://starship.rs/) and a [Nerd Font](https://www.nerdfonts.com/) (recommended: FiraCode Nerd Font or JetBrainsMono Nerd Font). See the [Installation wiki page](../../wiki/Installation) for full setup instructions.

```bash
curl -o ~/.config/starship.toml https://raw.githubusercontent.com/brei0x/starship/main/starship.toml
```

## Commands

The checks CI runs on every pull request, with taplo, Starship and lychee installed (`brew install taplo starship lychee`):

```bash
taplo check starship.toml                                      # TOML syntax
taplo fmt --check starship.toml                                # Formatting (`taplo fmt starship.toml` fixes it)
STARSHIP_CONFIG=./starship.toml starship print-config --default false   # Starship parses the config
lychee '**/*.md'                                               # Links in Markdown
GH_TOKEN=$(gh auth token) pipx run zizmor==1.31.1 .github      # Workflow audit
sh scripts/screenshots.sh                                      # Regenerate the preview images
```

Pinned versions, Linux and Windows installs, and screenshot requirements: [Development](../../wiki/Development) wiki page.

## Environments

None: the theme is a single file and nothing is deployed. Every push to `main` with a green CI is tagged and released by the `release.yml` workflow of `tekalib/.workflows`, versioned from the Conventional Commits since the last tag.

## Workflow

One branch per task (`feat/…`, `fix/…`, `chore/…`), Conventional Commits, PRs target `main` and are squash-merged, so the PR title decides the next version. Before pushing:

```bash
taplo check starship.toml && taplo fmt --check starship.toml \
  && STARSHIP_CONFIG=./starship.toml starship print-config --default false >/dev/null \
  && lychee '**/*.md'
```

## License

This project is licensed under the [MIT License](LICENSE).

## Acknowledgments

Inspired by [Powerlevel10k](https://github.com/romkatv/powerlevel10k).
