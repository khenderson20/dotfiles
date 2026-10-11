#!/usr/bin/env bash
# Interactive bash settings. ~/.bashrc is a stub (made by install.ps1 /
# install.sh) that sets $DOTFILES and sources this file.

# Nothing to do for non-interactive shells (scp, rsync, scripts)
case $- in *i*) ;; *) return ;; esac

DOTFILES="${DOTFILES:-$HOME/development/dotfiles}"

# increase bash history size
export HISTSIZE=5000
export HISTFILESIZE=10000

# Avoid duplicate entries and remove duplicates
export HISTCONTROL=ignoredups:erasedups

# Add timestamps to history entries
export HISTTIMEFORMAT='%F %T '

# Append to history file, rather than overwrite it
shopt -s histappend

# After each command append to the history file
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# Shared aliases, functions and environment (aliases first: it sets $_os)
for f in aliases functions env; do
  [ -f "$DOTFILES/shell/$f.sh" ] && . "$DOTFILES/shell/$f.sh"
done

# Machine-specific additions (not in the repo)
[ -f "$HOME/.bashrc.local" ] && . "$HOME/.bashrc.local"
