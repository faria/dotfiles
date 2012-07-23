# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# -----------------------------------------------------------------------------
# Detect platform
# http://stackoverflow.com/questions/394230/detect-os-from-a-bash-script

platform='unknown'
unamestr=$(uname)
if [[ "$unamestr" == "Linux" ]]; then
    platform='linux'
elif [[ "$unamestr" == "Darwin" ]]; then
    platform="macosx"
fi

# -----------------------------------------------------------------------------

# Prompt settings.
# http://en.wikipedia.org/wiki/ANSI_escape_code#Colors

# Display current git branch in bash prompt
# http://asemanfar.com/Current-Git-Branch-in-Bash-Prompt
# http://betterexplained.com/articles/aha-moments-when-learning-git/
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}
#export PS1="\[\033[00m\]\u@\h\[\033[01;34m\] \W \[\033[31m\]\$(parse_git_branch) \[\033[00m\]$\[\033[00m\] "
#export PS1="\[\033[00m\]\u@\h\[\033[01;34m\]:\w\[\033[31m\]\$(parse_git_branch)\[\033[00m\]$\[\033[00m\] "
export PS1="\[\033[32m\]\u@\h\[\033[01;34m\]:\w\[\033[31m\]\$(parse_git_branch)\[\033[00m\]$\[\033[00m\] "

# alternatively, use a simple but informative prompt
#export PS1='\h:\W \u\$ '
#export PS1='\u@\h:\w\$ '

# a few alternate prompts
#PS1_SHOW_PWD="cd \w\n\u@\h:\W\$ "

# number of trailing components to retain when expanding \w and \W
export PROMPT_DIRTRIM=2


# -----------------------------------------------------------------------------
# History settings

# Erase duplicate lines from history, and don't save commands
# which start with a space. See bash(1) for more options.
export HISTCONTROL=erasedups:ignorespace

# ignore some boring stuff. The " *" bit ignores all command lines
# starting with whitespace, useful to selectively avoid the history
export HISTIGNORE="ls:cd:cd ..:..*: *"

# ignore these while tab-completing
export FIGNORE="CVS:.svn:.git"

# Append to history file instead of overwriting it
shopt -s histappend

# -----------------------------------------------------------------------------
# Shell options

# Check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Don't use Ctrl-D to exit
set -o ignoreeof

# Some more shell options - see bash(1)
shopt -s cdspell dotglob nocaseglob no_empty_cmd_completion

# Use vi-style command line editing
#set -o vi

# -----------------------------------------------------------------------------
# Misc functions and aliases

# switch into dirname containing file
cdf   () { cd    "$(dirname "$(locate "$1" | head -n 1)")"; }
pushf () { pushd "$(dirname "$(locate "$1" | head -n 1)")"; }

# mkdir and cd if successful
function mkcd
{
    mkdir -p "$@" && builtin cd "$@"
}

# Tip #769 - .. revisited
# http://www.shell-fu.org/lister.php?id=769
function .. ()
{
    local arg=${1:-1};
    local dir=""
    while [ $arg -gt 0 ]; do
        dir="../$dir"
        arg=$(($arg - 1));
    done
    cd $dir >& /dev/null
}
function ... ()
{
    if [ -z "$1" ]; then
        return
    fi
    local maxlvl=16
    local dir=$1
    while [ $maxlvl -gt 0 ]; do
        dir="../$dir"
        maxlvl=$(($maxlvl - 1));
        if [ -d "$dir" ]; then
            cd $dir >& /dev/null
        fi
    done
}

if [[ $platform == "macosx" ]]; then
    # http://news.ycombinator.com/item?id=1157864
    spotlightfile()
    {
        # use spotlight to search for a file
        mdfind "kMDItemDisplayName == '$@'wc";
    }
    spotlightcontent()
    {
        # use spotlight to search file contents
        mdfind -interpret "$@";
    }
    pdfman()
    {
        # display a man page in Preview
        man -t $1 | open -a /Applications/Preview.app -f
    }
fi

# http://news.ycombinator.com/item?id=1157864
google()
{
    python -c "import sys, webbrowser, urllib;   webbrowser.open('http://www.google.com/search?' + urllib.urlencode({'q': ' '.join(sys.argv[1:]) }))" $@
}

# make less more friendly for non-text input files, see lesspipe(1)
if [ -x /usr/bin/lesspipe ]; then
    eval "$(SHELL=/bin/sh /usr/bin/lesspipe)"
elif [ -x /usr/local/bin/lesspipe.sh ]; then
    eval "$(SHELL=/bin/sh /usr/local/bin/lesspipe.sh)"
fi

# http://tychoish.com/rhizome/9-awesome-ssh-tricks/
ssh-reagent()
{
    for agent in /tmp/ssh-*/agent.*; do
        export SSH_AUTH_SOCK=$agent
        if ssh-add -l 2>&1 > /dev/null; then
            echo "Found working SSH Agent:"
            ssh-add -l
            return
        fi
    done
    echo 'Cannot find ssh agent - maybe you should reconnect and forward it?'
}

# pwd in the title bar
# http://www.blog.montgomerie.net/pwd-in-the-title-bar-or-a-regex-adventure-in-bash
function directory_to_titlebar
{
    # The maximum length we want (seems to fit nicely in a default length
    # Terminal title bar).
    local pwd_length=42

    # Get the current working directory. We'll format it in $dir.
    local dir="$PWD"

    # Substitute a leading path that's in $HOME for "~"
    if [[ "$HOME" == ${dir:0:${#HOME}} ]]; then
        dir="~${dir:${#HOME}}"
    fi

    # Append a trailing slash if it's not there already.
    if [[ ${dir:${#dir}-1} != "/" ]]; then
        dir="$dir/"
    fi

    # Truncate if we're too long.
    # We preserve the leading '/' or '~/', and substitute ellipses
    # for some directories in the middle.
    if [[ "$dir" =~ (~){0,1}/.*(.{${pwd_length}}) ]]; then
        local tilde=${BASH_REMATCH[1]}
        local directory=${BASH_REMATCH[2]}

        # At this point $directory is the truncated end-section of the
        # path. We will now make it only contain full directory names
        # (e.g., "ibrary/Mail" -> "/Mail").
        if [[ "$directory" =~ [^/]*(.*) ]]; then
            directory=${BASH_REMATCH[1]}
        fi

        # Can't work out if it's possible to use the Unicode ellipsis,
        # '…' (Unicode 2026). Directly embedding it in the string does
        # not seem to work, and \u escape sequences ('\u2026') are not
        # expanded.
        #printf -v dir "$tilde/\u2026$s", $directory
        dir="$tilde/...$directory"
    fi

    # Don't embed $dir directly in printf's first argument, because it's
    # possible it could contain printf escape sequences.
    printf "\033]0;%s\007" "$dir"
}
case "$TERM" in
    xterm*) export PROMPT_COMMAND="directory_to_titlebar; $PROMPT_COMMAND" ;;
esac


# -----------------------------------------------------------------------------

# Enable programmable completion features

if [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
elif [ -f /usr/local/etc/bash_completion ]; then
    source /usr/local/etc/bash_completion
fi
if [ -f ~/.bash_completion ]; then
    source ~/.bash_completion
fi

# Alias definitions.
# You may want to put your alias definitions in a separate file like
# ~/.bash_aliases, instead of adding them to this file directly.
if [ -f ~/.bash_aliases ]; then
    source ~/.bash_aliases
fi

# Local bashrc file.
# Use this for machine-specific initializations (e.g., sourcing virtualenvwrapper.sh)
if [ -f ~/.bashrc_local ]; then
    source ~/.bashrc_local
fi

# -----------------------------------------------------------------------------
# vim: set ft=sh
