# ~/.bash_aliases: This file is meant to be sourced from ~/.bashrc

###############################################################################
# Commonly used aliases

alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -ip'
alias df='df -h'
alias less='less -r'
alias vm='vim -X'
alias x='exit'

###############################################################################
# Other useful aliases

# ruby interpreter
alias irb='irb --readline -r irb/completion'

# print a list of all open files
alias list-open-files="lsof | awk '!/^\$/ && /\// { print \$9 }' | sort -u"

###############################################################################
# Platform-specific aliases

if [[ $platform == 'linux' ]]; then

    # Linux aliases

    alias ls='ls --color -F'

elif [[ $platform == 'macosx' ]]; then

    # Mac OS X aliases

    alias ls='ls -GF'
    alias ldd='otool -L'
    alias units='gunits -v'
    alias tree='tree -CF'
    alias md5sum='md5 -r'

    # this alias requires "brew install launch"
    alias l='launch'

fi

###############################################################################
# vim: ft=sh
