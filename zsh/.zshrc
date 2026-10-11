# Interactive zsh settings (macOS default shell). ~/.zshrc is a stub that
# sets $DOTFILES and sources this file.

DOTFILES="${DOTFILES:-$HOME/development/dotfiles}"

# History: large, shared between sessions, no duplicates, timestamped
HISTFILE="$HOME/.zsh_history"
HISTSIZE=5000
SAVEHIST=10000
setopt APPEND_HISTORY INC_APPEND_HISTORY HIST_IGNORE_ALL_DUPS EXTENDED_HISTORY

autoload -Uz compinit && compinit

# Shared aliases, functions and environment (aliases first: it sets $_os)
for f in aliases functions env; do
  [ -f "$DOTFILES/shell/$f.sh" ] && . "$DOTFILES/shell/$f.sh"
done

# Machine-specific additions (not in the repo)
[ -f "$HOME/.zshrc.local" ] && . "$HOME/.zshrc.local"
