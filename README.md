<p align="center">
  <img src="screenshots/starship-theme-brei0x-social-preview.png" alt="Brei0x Starship Theme prompt in zsh and PowerShell">
</p>

# Brei0x Starship Theme

A clean and professional Starship prompt theme inspired by Powerlevel10k, featuring a two-line layout with rich information and custom color palette.

<p align="center">
  <a href="https://github.com/brei0x/starship/actions/workflows/ci.yml"><img src="https://github.com/brei0x/starship/actions/workflows/ci.yml/badge.svg?branch=main" alt="CI"></a>
  <a href="https://github.com/brei0x/starship/releases/latest"><img src="https://img.shields.io/github/v/release/brei0x/starship?sort=semver" alt="Latest release"></a>
  <a href="https://github.com/brei0x/starship/blob/main/LICENSE"><img src="https://img.shields.io/github/license/brei0x/starship" alt="License"></a>
</p>

---

**Stack**: [Starship](https://starship.rs/) config (`starship.toml`) · Nerd Font glyphs · taplo, Starship and lychee checks, and prompt tests on macOS, Linux and Windows, in GitHub Actions

## Preview

### Git repository
![Git](screenshots/starship-theme-brei0x-git.png)
*Branch, then modified, staged and untracked files, one commit ahead, and the Terraform version.*

### Languages
![Languages](screenshots/starship-theme-brei0x-languages.png)
*Node.js and Python detected from the project files.*

### SSH session
![SSH](screenshots/starship-theme-brei0x-ssh.png)
*Over SSH the username and the hostname appear (here a real session to an Ubuntu server).*

### Root
![Root](screenshots/starship-theme-brei0x-root.png)
*Root turns the username red, even without SSH. An elevated Windows shell shows `Administrator` the same way.*

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
curl -fsSL --create-dirs -o ~/.config/starship.toml https://raw.githubusercontent.com/brei0x/starship/main/starship.toml
```

## Workflow

One branch per task (`feat/…`, `fix/…`, `chore/…`), Conventional Commits, PRs target `main` and are squash-merged, so the PR title decides the next version. Before pushing:

```bash
taplo check starship.toml && taplo fmt --check starship.toml \
  && STARSHIP_CONFIG=./starship.toml starship print-config >/dev/null \
  && lychee '**/*.md'
```

## Acknowledgments

Inspired by [Powerlevel10k](https://github.com/romkatv/powerlevel10k).
