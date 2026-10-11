# Functions shared by bash and zsh. Sourced by bash/.bashrc and zsh/.zshrc.

# Function to create a directory and move into it
mkcd () {
    mkdir -p "$1" && cd "$1" || return
}

# Function to find large files
find_large_files () {
    find . -type f -size +100M -exec ls -lh {} \; | awk '{ print $NF ": " $5 }'
}

# Function to extract various archive formats
extract () {
    if [ -f "$1" ]; then
        case $1 in
            *.tar.bz2)   tar xjf "$1"   ;;
            *.tar.gz)    tar xzf "$1"   ;;
            *.bz2)       bunzip2 "$1"   ;;
            *.rar)       unrar x "$1"   ;;
            *.gz)        gunzip "$1"    ;;
            *.tar)       tar xvf "$1"   ;;
            *.tbz2)      tar xjf "$1"   ;;
            *.tgz)       tar xzf "$1"   ;;
            *.zip)       unzip "$1"     ;;
            *.Z)         uncompress "$1";;
            *.7z)        7z x "$1"      ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}
