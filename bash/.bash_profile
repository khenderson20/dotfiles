#!/usr/bin/env bash
# Login shells (Git Bash, macOS Terminal, ssh logins) load this; it just
# pulls in ~/.bashrc and shows the welcome banner in interactive shells.

if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

case $- in *i*) ;; *) return ;; esac

# Display a welcome message
echo "Welcome, ${USERNAME:-$USER}! Today is $(date)."
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
