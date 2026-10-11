# dotfiles

Shell, editor, git, SSH and GPG settings that work on **Windows, macOS and Linux**.

The installer puts small *stub* files where each tool looks for its config.
Each stub loads the real file from this repo, so after installing, you just
edit files here (and `git pull` on other machines) — no copying.

## Install

Needs [PowerShell 7](https://aka.ms/powershell) (`pwsh`) and git.

```sh
git clone git@github.com:khenderson20/dotfiles.git ~/development/dotfiles   # Windows: C:\development\dotfiles
cd ~/development/dotfiles
./install.ps1 -WhatIf   # preview: lists every file it would change
./install.ps1           # apply (macOS/Linux without pwsh: ./install.sh tells you how to get it)
```

Re-running is safe. Any file it replaces is saved first to
`~/.dotfiles-backup/<timestamp>/`.

## What's here

| Folder | Used by | Notes |
|---|---|---|
| `powershell/profile.ps1` | PowerShell 7, all OSes | Windows-only parts (`vsdev`, Chocolatey, winget, `Update-Path`) are behind `$IsWindows` |
| `powershell/Modules/` | PowerShell | Added to `PSModulePath`, so modules here autoload (e.g. `Show-Calendar`) |
| `shell/` | bash and zsh | Shared aliases, functions and environment, with per-OS branches |
| `bash/`, `zsh/` | bash (Git Bash, Linux), zsh (macOS default) | History settings, then load `shell/` |
| `vim/.vimrc` | vim | |
| `git/` | git | `gitconfig` everywhere, plus `gitconfig.windows` or `gitconfig.unix` |
| `ssh/` | OpenSSH | Shared hosts (GitHub via the GPG auth key) and that key's **public** half. Copied into `~/.ssh` (ssh rejects config files others can write), so re-run the installer after editing |
| `gnupg/` | gpg-agent | Cache times, SSH support, which key ssh may use |
| `windows/.wslconfig` | WSL 2 | Windows only |
| `packages/` | — | **Local only (git-ignored):** installed-app lists, kept out of this public repo (see below) |

### Shortcuts the profiles add

- `dev` — go to your development folder (`$DEV_HOME`; defaults to `C:\development` on Windows, `~/development` elsewhere)
- `mkcd <dir>`, `..`, `...`, `which <cmd>`, `z <dir>` (zoxide), `y` (yazi)
- PowerShell on Windows: `vsdev` (MSVC/CMake/Ninja on PATH), `ci`/`cu`/`cun` (choco), `Update-Path`

### Machine-specific settings

Keep these out of the repo, in files the configs load if present:

- PowerShell: `~/.profile.local.ps1`
- bash / zsh: `~/.bashrc.local`, `~/.zshrc.local`
- git: `~/.gitconfig` itself (e.g. credential helper, a work email via `includeIf`)
- ssh: `~/.ssh/config` below the `Include` line

## New machine checklist

1. Install git, PowerShell 7 and GnuPG (Windows: Gpg4win; macOS: `brew install gnupg pinentry-mac`).
2. **Import your GPG secret key** from your offline backup — it is deliberately *not* in this repo:
   `gpg --import <backup>.asc`, then `gpg --edit-key 01EEDF3610103724 trust` (ultimate).
   Without it, commit signing and SSH to GitHub won't work.
3. Clone this repo and run `./install.ps1`.
4. Windows: reinstall apps if you want them. The lists in `packages/` are
   git-ignored, so they aren't on GitHub; copy them over from your private
   backup (or the old machine) first, then:
   `winget import packages/winget.json`, `scoop import packages/scoop.json`,
   `choco install packages/choco.config`.
   To refresh the lists: `winget export -o packages/winget.json`, `scoop export > packages/scoop.json`, `choco export packages/choco.config`.
5. Test: `ssh -T git@github.com` should greet you by username.
