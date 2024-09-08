#!/usr/bin/env bash

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
alias dev="cd /c/development"

# Alias that will display all listening ports and the services associated with them
alias ports="netstat -tulanp"

# Aliases to remove files or directories Safely the `-i` flag makes the commands 'interactive', prompting the user before overwriting or deleting files.
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"

# show system uptime (how long your system has been running in a more readable format)
alias uptime="uptime -p"

# Securely Delete Files
# The `shred` command overwrites files multiple times before deleting them, making them difficult to recover
alias shred="shred -u"


