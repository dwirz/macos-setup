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

At the end it **runs `zsh -c 'source ~/.zshrc'`** to validate the shell config (bash cannot load Oh My Zsh; a non-zero exit there is non-fatal) and prints a **one-line pointer** to the [manual steps after setup](#manual-steps-after-setup) section below.

## Manual steps after setup

Complete these in System Settings or apps as needed after `./setup.sh` finishes.

**Terminal (repo root):** the same pointer `setup.sh` prints:

```bash
echo "Post-setup checklist: ${PWD}/README.md#manual-steps-after-setup"
```

### Screen Recording permissions

- Open **System Settings → Privacy & Security → Screen Recording**
- Enable for Raycast and the browsers you use

### Night Shift

- Open **System Settings → Displays → Night Shift**
- Configure schedule and color temperature

### Raycast Clipboard History

- Open Raycast **Preferences → Extensions**
- Enable **Clipboard History**
- Optional: assign a hotkey or alias

### U.S. with German Umlauts keyboard layout

- Open **System Settings → Keyboard → Input Sources**
- Add **U.S. with German Umlauts**

### Wallpaper and lock screen

- If the desktop picture did not apply: **System Settings → Privacy & Security → Automation** — allow your terminal app to control System Events.
- If lock screen art did not apply: open **System Settings → Wallpaper** or **Lock Screen** once, then run `./scripts/apply-wallpaper-lockscreen-screensaver.sh`

### NetBird (browser login)

- If setup did not start the daemon:

  ```bash
  sudo netbird service install --management-url https://netbird.smarties.app && sudo netbird service start
  ```

- Connect and sign in (opens the browser):

  ```bash
  netbird up --management-url https://netbird.smarties.app
  ```

- Admin UI (optional): https://netbird.smarties.app/

### Browser extensions (Chrome and Arc)

- Fully quit and reopen Chrome and Arc so Web Store extensions install from the manifests written by setup.
- Local extension **GitLab MR Page Shortcuts**: open `chrome://extensions` (or Arc’s extensions page), enable **Developer mode**, **Load unpacked** → `configs/chrome-extensions/gitlab-merge-request` (under this repo’s root)

## Customizing

- **Apps and CLI tools**: edit [`Brewfile`](Brewfile), then run `brew bundle` (no need to re-run all of `setup.sh`).
- **Shell**: edit files under [`configs/oh-my-zsh/`](configs/oh-my-zsh/); they are symlinked into `~/.oh-my-zsh/custom/`, so changes apply after opening a new shell or `source ~/.zshrc`.
- **Themes / editors**: adjust files in `configs/` and re-copy paths as needed, or change the copy step in [`scripts/setup-50-safe-chain-and-app-configs.sh`](scripts/setup-50-safe-chain-and-app-configs.sh) if you want different destinations.
- **Browser extension lists**: edit extension IDs in [`scripts/install-chrome-extensions.sh`](scripts/install-chrome-extensions.sh). To skip the automated manifest step during `./setup.sh`, run `SKIP_BROWSER_EXTENSIONS=1 ./setup.sh`.

### If you fork this repo

[`configs/cursor.code-profile`](configs/cursor.code-profile) is tailored to this author’s machine. Replace **hardcoded paths** before using it elsewhere.

## Re-running safely

Re-running `./setup.sh` may **overwrite** symlinks and some copied files, re-apply `defaults`, and repeat installers that are idempotent (Homebrew, Oh My Zsh). Review [`setup.sh`](setup.sh) and the numbered [`scripts/setup-*.sh`](scripts/) steps before relying on it on a machine you already use daily.

## License

See [`LICENSE`](LICENSE).
