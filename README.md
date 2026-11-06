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

## Doctor: check, repair, clean up

On a Mac that is already set up, use [`doctor.sh`](doctor.sh) instead of re-running `setup.sh`. It compares the machine with this repo and is safe to run any time:

```bash
./doctor.sh                  # check only, changes nothing
./doctor.sh --fix            # also repair what is missing or broken
./doctor.sh --cleanup        # also remove leftovers of tools this repo dropped (asks per item)
./doctor.sh --fix --cleanup --yes   # both, without asking
```

| Area | Checks | `--fix` / `--cleanup` |
|------|--------|-----------------------|
| Leftovers | Headroom, the old OpenScreen venv and non-Homebrew `Openscreen.app`, Cursor, Loom, `pure`/`zsh-async`/`libmagic`, `pipx`/`python@3.13` (only when unused), Node versions inside Homebrew's nvm folder, old fzf files, stale browser-extension manifests | `--cleanup` removes them (apps go to the Trash) |
| Homebrew | Command Line Tools, Homebrew, missing Brewfile entries, deprecated/disabled entries, packages installed outside the Brewfile | `--fix` runs `brew bundle install --no-upgrade`; untracked packages are only listed |
| Shell | Oh My Zsh, `~/.zshrc` and custom-file symlinks, Powerlevel10k link, `~/.p10k.zsh`, uncommitted writes into the repo's shell configs, `~/.zshrc` load errors, fzf version | `--fix` installs and re-links; a customized `~/.p10k.zsh` is never overwritten |
| Node | LTS installed in `~/.nvm`, nvm default `lts/*` | `--fix` installs LTS and sets the default |
| SSH, Safe Chain, NetBird | `IgnoreUnknown UseKeychain` in the managed SSH block, Safe Chain, NetBird daemon, `NETBIRD_EXPOSE_PIN` in `~/.env` | `--fix` patches the SSH block and installs Safe Chain |
| Extras | Chrome/Arc extension manifests, keyboard layout, tmbliss LaunchAgent, Git identity | `--fix` writes manifests, installs the layout, loads the LaunchAgent |

Interactive steps (SSH key, tmbliss schedule, macOS defaults) are not re-run; the doctor prints the script to run instead. Exit code is `0` when nothing is left to do.

## What `setup.sh` does (overview)

[`setup.sh`](setup.sh) is a thin orchestrator: it **sources** numbered steps under [`scripts/`](scripts/) in order (`setup-00-lib.sh` helpers, then `setup-10-*.sh` … `setup-70-*.sh`). Edit those files to change behavior for a given phase.

| Step | What happens |
|------|----------------|
| Xcode CLT | Ensures command-line tools are installed |
| Homebrew | Installs Homebrew and runs `brew bundle` from [`Brewfile`](Brewfile) (CLI packages and cask apps). A failing cask is reported but does not stop the setup. |
| Oh My Zsh | Installs Oh My Zsh, **symlinks** `~/.zshrc` to [`configs/.zshrc-custom`](configs/.zshrc-custom) (an existing regular `~/.zshrc` is moved to `~/.zshrc.backup-<timestamp>`) and files from [`configs/oh-my-zsh/`](configs/oh-my-zsh/) into `~/.oh-my-zsh/custom/` |
| fzf | Key bindings and completion load from `~/.zshrc` via `source <(fzf --zsh)`; no install script is run (it would append to the symlinked `~/.zshrc`) |
| Shell plugins | **autojump** is enabled in the Oh My Zsh `plugins` list in [`configs/.zshrc-custom`](configs/.zshrc-custom); the `autojump` formula is in [`Brewfile`](Brewfile) |
| Profile | [`scripts/setup-dev-profile.sh`](scripts/setup-dev-profile.sh): nvm LTS Node in `~/.nvm` (default alias `lts/*`), global npm author fields, optional `npm adduser`, global Git user and a `lg` log alias |
| SSH | [`scripts/setup-ssh.sh`](scripts/setup-ssh.sh): interactive SSH key setup (GitHub-oriented flow) |
| Safe Chain | Installs [Safe Chain](https://github.com/AikidoSec/safe-chain) with a **pinned version and checksum** (see `install_safe_chain` in [`scripts/setup-50-safe-chain-and-app-configs.sh`](scripts/setup-50-safe-chain-and-app-configs.sh) to upgrade) |
| Config files | Copies the Warp theme and [Powerlevel10k](https://github.com/romkatv/powerlevel10k) config from `configs/` (an existing, different `~/.p10k.zsh` is backed up first). |
| Browser extensions | [`scripts/install-chrome-extensions.sh`](scripts/install-chrome-extensions.sh) via [`scripts/setup-52-chrome-extensions.sh`](scripts/setup-52-chrome-extensions.sh): writes **External Extensions** JSON for **Google Chrome** and **Arc** (Web Store IDs in the script). Set `SKIP_BROWSER_EXTENSIONS=1` before `./setup.sh` to skip. |
| macOS | [`scripts/macos-settings.sh`](scripts/macos-settings.sh) as your user (it asks for `sudo` only for the computer name and `remove_media`): grouped **defaults** (see `--help`). In a normal terminal you are **prompted per section**; `--all` and non-interactive runs apply every section **except the destructive `remove_media`**, which runs only when chosen at the prompt or named in `--sections`. From `setup.sh`, set `MACOS_SETTINGS_ALL=1` to skip prompts, or `MACOS_SETTINGS_SECTIONS=appearance,dock,finder` (example) for a fixed subset. |

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

### NetBird expose PIN

- `bird-link-pin` reads the PIN from `NETBIRD_EXPOSE_PIN`. Add `NETBIRD_EXPOSE_PIN=<pin>` to `~/.env` (loaded by `~/.zshrc`, not part of this repo).

### Browser extensions (Chrome and Arc)

- Fully quit and reopen Chrome and Arc so Web Store extensions install from the manifests written by setup.
- Local extension **GitLab MR Page Shortcuts**: open `chrome://extensions` (or Arc’s extensions page), enable **Developer mode**, **Load unpacked** → `configs/chrome-extensions/gitlab-merge-request` (under this repo’s root)

## Customizing

- **Apps and CLI tools**: edit [`Brewfile`](Brewfile), then run `brew bundle` (no need to re-run all of `setup.sh`).
- **Shell**: edit files under [`configs/oh-my-zsh/`](configs/oh-my-zsh/); they are symlinked into `~/.oh-my-zsh/custom/`, so changes apply after opening a new shell or `source ~/.zshrc`.
- **Themes / editors**: adjust files in `configs/` and re-copy paths as needed, or change the copy step in [`scripts/setup-50-safe-chain-and-app-configs.sh`](scripts/setup-50-safe-chain-and-app-configs.sh) if you want different destinations.
- **Browser extension lists**: edit extension IDs in [`scripts/install-chrome-extensions.sh`](scripts/install-chrome-extensions.sh). To skip the automated manifest step during `./setup.sh`, run `SKIP_BROWSER_EXTENSIONS=1 ./setup.sh`.

## Re-running safely

Re-running `./setup.sh` may **overwrite** symlinks and some copied files (a regular `~/.zshrc` and a changed `~/.p10k.zsh` are backed up first), re-apply `defaults`, and repeat installers that are idempotent (Homebrew, Oh My Zsh). Review [`setup.sh`](setup.sh) and the numbered [`scripts/setup-*.sh`](scripts/) steps before relying on it on a machine you already use daily. For an existing machine, prefer [`./doctor.sh`](#doctor-check-repair-clean-up).

## License

See [`LICENSE`](LICENSE).
