#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Links this dotfiles repo into the current machine (Windows, macOS, Linux).

.DESCRIPTION
  Safe to re-run. Nothing in the repo is copied over your files blindly:
  every file it replaces is first saved to ~/.dotfiles-backup/<timestamp>/.

  - PowerShell, bash, zsh, vim: small stub files at the usual locations
    that load the real config from this repo, so edits here apply at once.
  - git:   ~/.gitconfig includes git/gitconfig + the OS-specific file; keys
           those files define are removed from ~/.gitconfig.
  - ssh:   ssh/config is copied to ~/.ssh/dotfiles.config, which ~/.ssh/config
           includes at the top; public key files are copied to ~/.ssh.
  - gnupg: gpg-agent.conf is generated for this OS; missing sshcontrol
           lines are added. (Your secret keys are never in this repo.)
  - Windows: .wslconfig.

.EXAMPLE
  ./install.ps1 -WhatIf     # show what would change
  ./install.ps1             # apply
#>
[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'
$Repo = $PSScriptRoot
$RepoFwd = $Repo -replace '\\', '/'
$BackupDir = Join-Path $HOME ".dotfiles-backup/$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$os = if ($IsWindows) { 'windows' } elseif ($IsMacOS) { 'mac' } else { 'linux' }
# Path the repo has inside bash (Git Bash on Windows: C:\x -> /c/x)
$RepoPosix = if ($IsWindows) { $RepoFwd -replace '^([A-Za-z]):', { '/' + $_.Groups[1].Value.ToLower() } } else { $Repo }

Write-Host "dotfiles: $Repo  ($os)" -ForegroundColor Cyan

function Backup-File([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $null = New-Item -ItemType Directory -Force $BackupDir
    $dest = Join-Path $BackupDir ((Resolve-Path -LiteralPath $Path).Path -replace '[:\\/]+', '_').TrimStart('_')
    Copy-Item -LiteralPath $Path $dest
    Write-Host "  backed up $Path" -ForegroundColor DarkGray
}

# Writes $Content to $Path (LF line endings, UTF-8 no BOM) unless it's already identical.
# -Private: owner-only permissions on macOS/Linux (for ~/.ssh and ~/.gnupg files).
function Set-ManagedFile([string]$Path, [string]$Content, [switch]$Private) {
    $Content = $Content -replace "`r`n", "`n"
    if ((Test-Path -LiteralPath $Path) -and ((Get-Content -Raw -LiteralPath $Path) -replace "`r`n", "`n") -eq $Content) {
        Write-Host "  ok        $Path" -ForegroundColor DarkGray
        return
    }
    if ($PSCmdlet.ShouldProcess($Path, 'write')) {
        Backup-File $Path
        try {
            $null = New-Item -ItemType Directory -Force (Split-Path $Path)
            [IO.File]::WriteAllText($Path, $Content, [Text.UTF8Encoding]::new($false))
            Write-Host "  wrote     $Path" -ForegroundColor Green
            if (-not $IsWindows -and $Private) { chmod 600 $Path }
        } catch [UnauthorizedAccessException] {
            # Usually Windows Defender's Controlled Folder Access guarding Documents
            Write-Host "  BLOCKED   $Path" -ForegroundColor Red
            $script:Blocked += [pscustomobject]@{ Path = $Path; Content = $Content }
        }
    }
}
$script:Blocked = @()

# ~/.ssh and ~/.gnupg should be owner-only on macOS/Linux: gpg warns about an
# unsafe homedir on every command otherwise, and ssh refuses config and key
# files other users can write. (On Windows they inherit the profile's ACL.)
function New-PrivateDir([string]$Path) {
    if ($IsWindows -or $WhatIfPreference) { return }
    $null = New-Item -ItemType Directory -Force $Path
    chmod 700 $Path
}

# --- PowerShell -----------------------------------------------------------
Write-Host 'PowerShell'
Set-ManagedFile $PROFILE.CurrentUserCurrentHost @"
# Managed by $RepoFwd/install.ps1 - edit the repo's powershell/profile.ps1 instead.
. '$RepoFwd/powershell/profile.ps1'

"@

# --- bash / zsh / vim -----------------------------------------------------
Write-Host 'Shells and vim'
Set-ManagedFile (Join-Path $HOME '.bashrc') @"
# Managed by dotfiles install - edit `$DOTFILES/bash/.bashrc instead.
export DOTFILES='$RepoPosix'
. "`$DOTFILES/bash/.bashrc"

"@
Set-ManagedFile (Join-Path $HOME '.bash_profile') @"
# Managed by dotfiles install - edit `$DOTFILES/bash/.bash_profile instead.
export DOTFILES='$RepoPosix'
. "`$DOTFILES/bash/.bash_profile"

"@
if ($IsMacOS -or (Get-Command zsh -ErrorAction SilentlyContinue)) {
    Set-ManagedFile (Join-Path $HOME '.zshrc') @"
# Managed by dotfiles install - edit `$DOTFILES/zsh/.zshrc instead.
export DOTFILES='$RepoPosix'
. "`$DOTFILES/zsh/.zshrc"

"@
}
Set-ManagedFile (Join-Path $HOME '.vimrc') @"
" Managed by dotfiles install - edit the repo's vim/.vimrc instead.
source $RepoFwd/vim/.vimrc

"@

# --- git ------------------------------------------------------------------
Write-Host 'git'
if (Get-Command git -ErrorAction SilentlyContinue) {
    $osGit = if ($IsWindows) { 'gitconfig.windows' } else { 'gitconfig.unix' }
    $includes = @("$RepoFwd/git/gitconfig", "$RepoFwd/git/$osGit")
    $current = @(git config --global --get-all include.path)
    $repoKeys = $includes | ForEach-Object { git config -f $_ --list --name-only } | Sort-Object -Unique
    $dupes = $repoKeys | Where-Object { git config --global --no-includes --get-all $_ 2>$null }
    if (($includes | Where-Object { $_ -notin $current }) -or $dupes) {
        if ($PSCmdlet.ShouldProcess('~/.gitconfig', "include repo files; remove keys they now provide: $($dupes -join ', ')")) {
            Backup-File (Join-Path $HOME '.gitconfig')
            foreach ($k in $dupes) { git config --global --unset-all $k }
            foreach ($inc in $includes | Where-Object { $_ -notin $current }) { git config --global --add include.path $inc }
            Write-Host "  updated   ~/.gitconfig" -ForegroundColor Green
        }
    } else { Write-Host '  ok        ~/.gitconfig' -ForegroundColor DarkGray }
} else { Write-Warning 'git not found; skipped' }

# --- ssh ------------------------------------------------------------------
Write-Host 'ssh'
$sshDir = Join-Path $HOME '.ssh'
New-PrivateDir $sshDir
foreach ($pub in Get-ChildItem (Join-Path $Repo 'ssh') -Filter '*.pub') {
    Set-ManagedFile (Join-Path $sshDir $pub.Name) (Get-Content -Raw $pub.FullName)
}
# Copied, not included from the repo: ssh rejects config files other users can
# write, and folders like C:\development grant that to Authenticated Users.
# Re-run install.ps1 after editing ssh/config.
Set-ManagedFile (Join-Path $sshDir 'dotfiles.config') (Get-Content -Raw (Join-Path $Repo 'ssh/config')) -Private
$sshConfig = Join-Path $sshDir 'config'
$includeLine = 'Include ~/.ssh/dotfiles.config'
$existing = if (Test-Path $sshConfig) { Get-Content -Raw $sshConfig } else { '' }
if ($existing -notmatch [regex]::Escape($includeLine)) {
    # Include must come before any Host block to apply to every host
    Set-ManagedFile $sshConfig "# Shared hosts from the dotfiles repo (first match wins, so these take priority)`n$includeLine`n`n$existing" -Private
} else { Write-Host "  ok        $sshConfig" -ForegroundColor DarkGray }

# --- gnupg ----------------------------------------------------------------
Write-Host 'gnupg'
if (Get-Command gpgconf -ErrorAction SilentlyContinue) {
    $gnupgHome = (gpgconf --list-dirs homedir) -replace '%3a', ':'
    New-PrivateDir $gnupgHome
    $agentConf = (Get-Content -Raw (Join-Path $Repo 'gnupg/gpg-agent.conf')).TrimEnd() + "`n`n"
    $agentConf += if ($IsWindows) { "enable-win32-openssh-support`n" } else { "enable-ssh-support`n" }
    if ($IsMacOS -and ($pinentry = Get-Command pinentry-mac -ErrorAction SilentlyContinue)) {
        $agentConf += "pinentry-program $($pinentry.Source)`n"
    }
    Set-ManagedFile (Join-Path $gnupgHome 'gpg-agent.conf') $agentConf -Private

    $sshcontrol = Join-Path $gnupgHome 'sshcontrol'
    $have = if (Test-Path $sshcontrol) { Get-Content $sshcontrol } else { @() }
    $want = Get-Content (Join-Path $Repo 'gnupg/sshcontrol') | Where-Object { $_ -match '^\s*!?[0-9A-F]{40}' }
    $missing = $want | Where-Object { ($_ -split '\s+')[0] -notin ($have | ForEach-Object { ($_.Trim() -split '\s+')[0] }) }
    if ($missing) {
        Set-ManagedFile $sshcontrol ((($have + $missing) -join "`n") + "`n") -Private
    } else { Write-Host "  ok        $sshcontrol" -ForegroundColor DarkGray }

    if (-not $WhatIfPreference) { gpg-connect-agent reloadagent /bye *> $null }
} else { Write-Warning 'gpgconf not found; skipped (install GnuPG / Gpg4win, then re-run)' }

# --- Windows extras -------------------------------------------------------
if ($IsWindows) {
    Write-Host 'Windows'
    Set-ManagedFile (Join-Path $HOME '.wslconfig') (Get-Content -Raw (Join-Path $Repo 'windows/.wslconfig'))
}

Write-Host "`nDone." -ForegroundColor Cyan
if (Test-Path $BackupDir) { Write-Host "Backups of replaced files: $BackupDir" }
if ($script:Blocked) {
    Write-Warning 'Some files could not be written (access denied). Create them yourself with this content:'
    foreach ($b in $script:Blocked) {
        Write-Host "`n--- $($b.Path)" -ForegroundColor Yellow
        Write-Host $b.Content
    }
    if ($IsWindows) {
        Write-Host @"
On Windows this is usually Controlled Folder Access (ransomware protection)
guarding Documents; Windows Security shows an "Unauthorized changes blocked"
notice. Saving the file from an editor such as VS Code usually works, or allow
pwsh in Windows Security > Virus & threat protection > Ransomware protection.
"@
    }
}
