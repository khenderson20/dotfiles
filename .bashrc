#!/usr/bin/env bash

if [ -f ~/.bash_aliases ]; then
  . ~/.bash_aliases
fi

export LESS='-R'
export MANPAGER='less -R'
