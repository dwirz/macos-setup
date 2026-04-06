# macos-setup

Personal **macOS bootstrap** for a new machine: installs CLI tools and apps, wires up zsh (Oh My Zsh, Powerlevel10k, custom snippets), applies developer defaults (Node via nvm, Git, npm), copies editor/terminal configs, tweaks system preferences, and runs a few security-oriented helpers.

## Prerequisites

- **macOS** (Apple Silicon or Intel)
- **Network** access (Homebrew, GitHub, etc.)
- **Administrator** password when prompted (for `defaults` and similar changes)

## Quick start

1. Clone this repository and open a terminal in its root directory.

2. Run the main script:

   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

3. If **Xcode Command Line Tools** are missing, the script opens Apple’s installer. Finish that install, then run `./setup.sh` again.

The script is **interactive** in places: it asks for your name, email, domain, and computer name, runs SSH key setup, and may prompt for npm login.

## What `setup.sh` does (overview)

[`setup.sh`](setup.sh) is a thin orchestrator: it **sources** numbered steps under [`scripts/`](scripts/) in order (`setup-00-lib.sh` helpers, then `setup-10-*.sh` … `setup-70-*.sh`). Edit those files to change behavior for a given phase.

| Step | What happens |
|------|----------------|
| Xcode CLT | Ensures command-line tools are installed |
| Homebrew | Installs Homebrew and runs `brew bundle` from [`Brewfile`](Brewfile) (CLI packages and cask apps) |
| Oh My Zsh | Installs Oh My Zsh and **symlinks** files from [`configs/oh-my-zsh/`](configs/oh-my-zsh/) into `~/.oh-my-zsh/custom/` |
| OpenScreen | Runs [`scripts/install-openscreen.sh`](scripts/install-openscreen.sh) if present |
| fzf | Runs Homebrew’s fzf install script (`--all`) when available |
| Shell plugins | **autojump** is enabled in [`configs/oh-my-zsh/custom_startup.zsh`](configs/oh-my-zsh/custom_startup.zsh); the `autojump` formula is in [`Brewfile`](Brewfile) |
| Profile | [`scripts/setup-dev-profile.sh`](scripts/setup-dev-profile.sh): nvm LTS Node, global npm author fields, optional `npm adduser`, global Git user and a `lg` log alias |
| SSH | [`scripts/setup-ssh.sh`](scripts/setup-ssh.sh): interactive SSH key setup (GitHub-oriented flow) |
| Safe Chain | Installs [Safe Chain](https://github.com/AikidoSec/safe-chain) with a **pinned version and checksum** (see `install_safe_chain` in [`scripts/setup-50-safe-chain-and-app-configs.sh`](scripts/setup-50-safe-chain-and-app-configs.sh) to upgrade) |
| Config files | Copies Cursor profile, Warp theme, and [Powerlevel10k](https://github.com/romkatv/powerlevel10k) config from `configs/` |
| Browser extensions | [`scripts/install-chrome-extensions.sh`](scripts/install-chrome-extensions.sh) via [`scripts/setup-52-chrome-extensions.sh`](scripts/setup-52-chrome-extensions.sh): writes **External Extensions** JSON for **Google Chrome** and **Arc** (Web Store IDs in the script). Set `SKIP_BROWSER_EXTENSIONS=1` before `./setup.sh` to skip. |
| macOS | [`scripts/macos-settings.sh`](scripts/macos-settings.sh) with `sudo`: grouped **defaults** (see `--help`). In a normal terminal you are **prompted per section**; non-interactive runs apply **all** sections. From `setup.sh`, set `MACOS_SETTINGS_ALL=1` to skip prompts, or `MACOS_SETTINGS_SECTIONS=appearance,dock,finder` (example) for a fixed subset. |

At the end it **runs `zsh -c 'source ~/.zshrc'`** to validate the shell config (bash cannot load Oh My Zsh; a non-zero exit there is non-fatal) and prints **manual follow-ups** (Screen Recording for Raycast/browsers, Night Shift, Raycast Clipboard History, browser extension restart and unpacked GitLab extension).

## Customizing

- **Apps and CLI tools**: edit [`Brewfile`](Brewfile), then run `brew bundle` (no need to re-run all of `setup.sh`).
- **Shell**: edit files under [`configs/oh-my-zsh/`](configs/oh-my-zsh/); they are symlinked into `~/.oh-my-zsh/custom/`, so changes apply after opening a new shell or `source ~/.zshrc`.
- **Themes / editors**: adjust files in `configs/` and re-copy paths as needed, or change the copy step in [`scripts/setup-50-safe-chain-and-app-configs.sh`](scripts/setup-50-safe-chain-and-app-configs.sh) if you want different destinations.
- **Browser extension lists**: edit extension IDs in [`scripts/install-chrome-extensions.sh`](scripts/install-chrome-extensions.sh). To skip the automated manifest step during `./setup.sh`, run `SKIP_BROWSER_EXTENSIONS=1 ./setup.sh`.

### If you fork this repo

[`configs/oh-my-zsh/custom_startup.zsh`](configs/oh-my-zsh/custom_startup.zsh) is tailored to this author’s machine. Replace **hardcoded paths** before using it elsewhere:

- **`NVM_DIR`** and **`ZSH`** use `/Users/dwirz/...` — switch to `$HOME` (e.g. `export NVM_DIR="$HOME/.nvm"`, `export ZSH="$HOME/.oh-my-zsh"`).
- **Homebrew** runs `eval "$(/opt/homebrew/bin/brew shellenv)"` (Apple Silicon default). On Intel Macs, Homebrew lives under `/usr/local`; use `eval "$(brew shellenv)"` after `brew` is on your `PATH`, or mirror the pattern in [`scripts/setup-00-lib.sh`](scripts/setup-00-lib.sh) (`ensure_brew_shellenv`).
- **SSH** uses `ssh-add` with **`~/.ssh/id_rsa`**; if you use another key (for example the `github` key from [`scripts/setup-ssh.sh`](scripts/setup-ssh.sh)), point `ssh-add` at that path or rely on your SSH config.

## Re-running safely

Re-running `./setup.sh` may **overwrite** symlinks and some copied files, re-apply `defaults`, and repeat installers that are idempotent (Homebrew, Oh My Zsh). Review [`setup.sh`](setup.sh) and the numbered [`scripts/setup-*.sh`](scripts/) steps before relying on it on a machine you already use daily.

## License

See [`LICENSE`](LICENSE).
