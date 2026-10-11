#!/usr/bin/env sh
# Bootstrap for macOS / Linux: runs install.ps1 with PowerShell 7.
# Usage: ./install.sh [-WhatIf]
set -e
cd "$(dirname "$0")"

if ! command -v pwsh >/dev/null 2>&1; then
  echo "PowerShell 7 (pwsh) is needed to run the installer. Install it with:"
  case "$(uname -s)" in
    Darwin) echo "  brew install --cask powershell" ;;
    *)      echo "  https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-linux"
            echo "  (or: sudo snap install powershell --classic)" ;;
  esac
  exit 1
fi

exec pwsh -NoProfile -File ./install.ps1 "$@"
