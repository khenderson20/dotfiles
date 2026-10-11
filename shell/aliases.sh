# Aliases shared by bash and zsh (Git Bash on Windows, Linux, macOS).
# Sourced by bash/.bashrc and zsh/.zshrc; not meant to be run directly.

# Detect the platform once
case "$(uname -s)" in
  Darwin)               _os=mac ;;
  Linux)                _os=linux ;;
  MINGW*|MSYS*|CYGWIN*) _os=windows ;;
  *)                    _os=other ;;
esac

# Alias to list files in the long format, including hidden files, and appends a symbol to indicate the type of file (e.g., '/' for directories, '*' for executables).
alias ll="ls -alF"

# Alias to list all files, including hidden ones (those starting with a dot), but without the detailed information that `ll` provides.
alias la="ls -A"

# Alias to list files in a column format, appending a symbol to indicate the type of file, without showing hidden files.
alias l="ls -CF"

# Alias to find files or directories by name within the current directory and its subdirectories.
# Example usage: `ffind filename` will search for `filename` in the current directory and its subdirectories.
alias ffind="find . -name"

# Alias to make `grep` output more readable by highlighting matching text with color.
alias grep="grep --color=auto"

# Alias to quickly check your external IP address by querying the `ifconfig.me` service.
alias myip="curl ifconfig.me"

# Alias that will move to development directory for me
# ($DEV_HOME, else C:\development on Windows, else ~/development)
if [ -z "$DEV_HOME" ]; then
  if [ "$_os" = windows ] && [ -d /c/development ]; then DEV_HOME=/c/development
  else DEV_HOME="$HOME/development"; fi
fi
export DEV_HOME
alias dev='cd "$DEV_HOME"'

# Alias that will display all listening ports and the services associated with them
case "$_os" in
  linux)   alias ports="ss -tulpn 2>/dev/null || netstat -tulanp" ;;
  mac)     alias ports="lsof -iTCP -sTCP:LISTEN -n -P" ;;
  windows) alias ports="netstat -ano | grep LISTENING" ;;
esac

# Aliases to remove files or directories Safely the `-i` flag makes the commands 'interactive', prompting the user before overwriting or deleting files.
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"

# show system uptime (how long your system has been running in a more readable format)
# (-p is Linux-only; macOS and Git Bash use plain uptime)
[ "$_os" = linux ] && alias uptime="uptime -p"

# Securely Delete Files
# The `shred` command overwrites files multiple times before deleting them, making them difficult to recover
# (GNU coreutils only; on macOS, `brew install coreutils` provides gshred)
if command -v shred >/dev/null 2>&1; then
  alias shred="shred -u"
elif command -v gshred >/dev/null 2>&1; then
  alias shred="gshred -u"
fi
