#! /bin/bash

# GIT completion/PS1
# Add the '$(__git_ps1)$(__dv_svn_ps1)' just before final '\$' of PS1
[ -e /etc/bash_completion.d/git-prompt ] && . /etc/bash_completion.d/git-prompt
[ -e /usr/share/bash-completion/completions/git ] && . /usr/share/bash-completion/completions/git
