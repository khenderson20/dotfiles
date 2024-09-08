#!/usr/bin/env bash

# Display a welcome message
echo "Welcome, $USERNAME! Today is $(date)."

# Source .bashrc from .bash_profile
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# increase bash history size
export HISTSIZE=5000
export HISTFILESIZE=10000

# Avoid duplicate entries and eremove duplicates
export HISTCONTROL=ignoredups:erasedups

# Add timestamps to history entries
export HISTTIMEFORMAT='%F %T '

# Append to history file, rather than overwrite it
shopt -s histappend

# After each command append to the history file
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

# Set the default editor
export EDITOR=vim

# Set the language and locale
export LANG=en_US.UTF-8
cat << "EOF"
               _    .  ,   .           .
           *  / \_ *  / \_      _  *        *   /\'__        *
             /    \  /    \,   ((        .    _/  /  \  *'.
        .   /\/\  /\/ :' __ \_  `          _^/  ^/    `--.
           /    \/  \  _/  \-'\      *    /.' ^_   \_   .'\  *
     *  /\  .-   `. \/     \ /==~=-=~=-=-;.  _/ \ -. `_/   \
       /  `-.__ ^   / .-'.--\ =-=~_=-=~=^/  _ `--./ .-'  `-
      /        `.  / /       `.~-^=-=~=^=.-'      '-._ `._
EOF
