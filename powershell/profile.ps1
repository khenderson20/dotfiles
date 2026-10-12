# =====================================================================
#  PowerShell 7 Profile (Windows, macOS, Linux)
#  Loaded by a one-line stub at $PROFILE that install.ps1 creates.
#  Features: dev shell (MSVC/CMake/Ninja), completions (choco, gh,
#  winget), zoxide, PSReadLine, GPG agent (signing + SSH), Yazi wrapper,
#  small helpers. Windows-only pieces are guarded by $IsWindows.
#  Kept fast: slow pieces are cached or deferred until the prompt is idle
# =====================================================================

$sw = [Diagnostics.Stopwatch]::StartNew()
# Elapsed ms after each section; a slow start (>1s) reports the worst ones
$profileMarks = [ordered]@{}
$sep = [IO.Path]::PathSeparator

# --------------------------------------------------
#  Console encoding: UTF-8 so compiler/git/tool output isn't mangled
# --------------------------------------------------
[Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.UTF8Encoding]::new($false)

# --------------------------------------------------
#  Modules kept in this repo (autoload, e.g. Show-Calendar)
# --------------------------------------------------
$repoModules = Join-Path $PSScriptRoot 'Modules'
if (($env:PSModulePath -split $sep) -notcontains $repoModules) {
    $env:PSModulePath = "$repoModules$sep$env:PSModulePath"
}

# --------------------------------------------------
#  PATH additions (session only, skipped if missing)
# --------------------------------------------------
$androidSdk = if ($IsWindows) { "$env:LOCALAPPDATA/Android/Sdk" }
              elseif ($IsMacOS) { "$HOME/Library/Android/sdk" }
              else { "$HOME/Android/Sdk" }
foreach ($dir in @(
        (Join-Path $androidSdk 'platform-tools'),
        (Join-Path $HOME '.local/bin')          # claude CLI, pipx, etc.
    )) {
    if ((Test-Path $dir) -and ($env:PATH -split $sep) -notcontains $dir) {
        $env:PATH = "$env:PATH$sep$dir"
    }
}
$profileMarks['setup'] = $sw.ElapsedMilliseconds

# --------------------------------------------------
#  PSReadLine: history-based suggestions and prefix search
# --------------------------------------------------
# (skipped when output is redirected, e.g. scripts or tools running pwsh).
# Called directly rather than checked with Get-Module -ListAvailable, which
# scans every module folder and is slow on a cold start.
if (-not [Console]::IsOutputRedirected) {
    try {
        Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView -HistoryNoDuplicates -ErrorAction Stop
        Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
        Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
        Set-PSReadLineKeyHandler -Key Tab       -Function MenuComplete
    } catch { }
}
$profileMarks['psreadline'] = $sw.ElapsedMilliseconds

# --------------------------------------------------
#  Tool init scripts, cached and regenerated only when the tool's
#  binary changes (generating them live costs 0.1-1s each per startup)
# --------------------------------------------------
$initCacheDir = if ($IsWindows) { "$env:LOCALAPPDATA/pwsh-init-cache" }
                elseif ($env:XDG_CACHE_HOME) { "$env:XDG_CACHE_HOME/pwsh-init-cache" }
                else { "$HOME/.cache/pwsh-init-cache" }

function Get-CachedInit {
    param([string]$Tool, [scriptblock]$Generate)
    $cache = Join-Path $initCacheDir "$Tool.ps1"
    # Fast path: the cache's first line records where the tool was found, so
    # a startup checks that one file instead of searching every PATH folder
    # (PATH searches are what make a cold start slow)
    if (Test-Path $cache) {
        $exePath = (Get-Content $cache -TotalCount 1) -replace '^# source: '
        if ($exePath -and (Test-Path -LiteralPath $exePath) -and
            (Get-Item -LiteralPath $exePath).LastWriteTime -le (Get-Item $cache).LastWriteTime) {
            return $cache
        }
    }
    $exe = Get-Command $Tool -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $exe) { return $null }
    $null = New-Item -ItemType Directory -Force $initCacheDir
    @("# source: $($exe.Source)") + @(& $Generate) | Out-File $cache -Encoding utf8
    $cache
}

# zoxide: "z <dir>" jumps to frequent dirs, "zi" picks with fzf
if ($init = Get-CachedInit zoxide { zoxide init powershell }) { . $init }
# GitHub CLI tab completion
if ($init = Get-CachedInit gh { gh completion -s powershell }) { . $init }
$profileMarks['zoxide + gh'] = $sw.ElapsedMilliseconds

# --------------------------------------------------
#  Small helpers
# --------------------------------------------------
function which { param([string]$Name) Get-Command $Name -All -ErrorAction SilentlyContinue | Select-Object CommandType, Name, Source }
function mkcd  { param([string]$Path) New-Item -ItemType Directory -Force $Path | Out-Null; Set-Location $Path }
function ..    { Set-Location .. }
function ...   { Set-Location ../.. }

# Development folder: $env:DEV_HOME, else C:\development or ~/development
$env:DEV_HOME = if ($env:DEV_HOME) { $env:DEV_HOME }
                elseif ($IsWindows -and (Test-Path 'C:\development')) { 'C:\development' }
                elseif (Test-Path '/mnt/c/development') { '/mnt/c/development' }   # WSL
                else { Join-Path $HOME 'development' }
function dev { Set-Location $env:DEV_HOME }

# --------------------------------------------------
#  GPG agent: commit signing everywhere, and SSH keys for ssh.
#  macOS/Linux: point ssh at the agent's socket and pinentry at this
#  terminal. Windows needs neither (ssh uses gpg-agent's named pipe), and
#  starts the agent in the background instead (see the Windows section).
# --------------------------------------------------
if (-not $IsWindows -and (Get-Command gpg-connect-agent -ErrorAction SilentlyContinue)) {
    $env:GPG_TTY = (tty)
    $env:SSH_AUTH_SOCK = (gpgconf --list-dirs agent-ssh-socket)
    # Starts the agent if it isn't running; quiet when it already is
    gpg-connect-agent updatestartuptty /bye *> $null
    if ($LASTEXITCODE -ne 0) { Write-Warning "gpg-agent did not start" }
}
$profileMarks['gpg-agent'] = $sw.ElapsedMilliseconds

function Get-GpgKeyInfo {
    gpg --list-secret-keys --keyid-format=long
    Write-Host "`nTo configure Git with your key:" -ForegroundColor Green
    Write-Host "git config --global user.signingkey YOUR_KEY_ID" -ForegroundColor Yellow
}

# --------------------------------------------------
#  Yazi Shell Wrapper (directory persistence)
# --------------------------------------------------
function y {
    $tmp = [System.IO.Path]::GetTempFileName()
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp -Encoding UTF8
    if ($cwd -and $cwd -ne $PWD.Path) {
        Set-Location -LiteralPath ([System.IO.Path]::GetFullPath($cwd))
    }
    Remove-Item -Path $tmp -Force
}

# ==================================================
#  Windows only
# ==================================================
if ($IsWindows) {
    # Done once the prompt is idle, so they don't delay it:
    # - Chocolatey tab completion (~300ms to import)
    # - starting gpg-agent: gpg starts it on demand, but ssh.exe can't, so
    #   SSH to GitHub needs it running (~0.1s warm, much more on a cold start)
    $null = Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action {
        $chocoProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
        if (Test-Path $chocoProfile) {
            Import-Module $chocoProfile -DisableNameChecking -Global -ErrorAction SilentlyContinue
        }
        if (Get-Command gpg-connect-agent -ErrorAction SilentlyContinue) {
            gpg-connect-agent /bye *> $null
        }
    }

    # Chocolatey shortcuts (functions, since aliases can't carry arguments)
    function ci  { choco install   @args }
    function cu  { choco upgrade   @args }
    function cun { choco uninstall @args }

    # winget tab completion (built into winget, just needs registering)
    Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.UTF8Encoding]::new()
        winget complete --word="$wordToComplete" --commandline "$commandAst" --position $cursorPosition | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }

    # Reload PATH from the registry (after an installer changes it) without opening a new window
    function Update-Path {
        $env:PATH = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
    }

    # Visual Studio developer shell: puts cl, link, cmake, ninja,
    # msbuild on PATH for this session. Run "vsdev" (or "vsdev x86").
    function vsdev {
        param([ValidateSet('amd64', 'x86', 'arm64')][string]$Arch = 'amd64')
        $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
        if (-not (Test-Path $vswhere)) { Write-Warning 'vswhere.exe not found; is Visual Studio installed?'; return }
        $vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
        if (-not $vs) { Write-Warning 'No Visual Studio install with the C++ tools found'; return }
        # VS's batch scripts call vswhere by name
        $env:PATH = "$env:PATH;$(Split-Path $vswhere)"
        Import-Module "$vs\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
        Enter-VsDevShell -VsInstallPath $vs -SkipAutomaticLocation -DevCmdArguments "-arch=$Arch -host_arch=amd64" | Out-Null
        if (Get-Command cl -ErrorAction SilentlyContinue) {
            Write-Host "VS dev shell ($Arch): $(Split-Path $vs -Leaf) - cl, cmake, ninja ready" -ForegroundColor Green
        } else {
            Write-Warning 'VS dev shell setup ran but cl.exe is not on PATH'
        }
    }
}
$profileMarks['windows extras'] = $sw.ElapsedMilliseconds

# --------------------------------------------------
#  Machine-specific additions (not in the repo): ~/.profile.local.ps1
# --------------------------------------------------
$localProfile = Join-Path $HOME '.profile.local.ps1'
if (Test-Path $localProfile) { . $localProfile }
$profileMarks['rest'] = $sw.ElapsedMilliseconds

# --------------------------------------------------
#  Final Timing Output
# --------------------------------------------------
$sw.Stop()
Write-Host ("PowerShell profile loaded in {0:N2}s" -f $sw.Elapsed.TotalSeconds) -ForegroundColor Gray
if ($sw.ElapsedMilliseconds -gt 1000) {
    $prev = 0
    $sections = foreach ($name in $profileMarks.Keys) {
        [pscustomobject]@{ Name = $name; Ms = $profileMarks[$name] - $prev }
        $prev = $profileMarks[$name]
    }
    $slowest = $sections | Sort-Object Ms -Descending | Select-Object -First 3 |
        ForEach-Object { '{0} {1:N2}s' -f $_.Name, ($_.Ms / 1000) }
    Write-Host "  slowest: $($slowest -join ', ')" -ForegroundColor DarkGray
}
