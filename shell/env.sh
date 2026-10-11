# Environment shared by bash and zsh. Sourced by bash/.bashrc and zsh/.zshrc.

# Set the default editor
export EDITOR=vim

# Set the language and locale
export LANG=en_US.UTF-8

export LESS='-R'
export MANPAGER='less -R'

# ~/.local/bin (claude CLI, pipx, etc.)
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) [ -d "$HOME/.local/bin" ] && PATH="$PATH:$HOME/.local/bin" ;;
esac

# GPG: signing prompts in this terminal, and gpg-agent as the SSH agent.
# On Windows, ssh.exe reaches gpg-agent over a named pipe instead.
if command -v gpgconf >/dev/null 2>&1 && [ "$_os" != windows ]; then
  GPG_TTY="$(tty)"
  export GPG_TTY
  SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
  export SSH_AUTH_SOCK
  gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
fi

# zoxide ("z <dir>"), if installed
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init "$(basename "${ZSH_NAME:-bash}")")"
fi
