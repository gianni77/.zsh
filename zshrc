#!/bin/zsh

#export PATH="$HOME/.bin:$PATH"
source $HOME/.zsh/zshenv

SYSTEM_DEPENDENT="$HOME/.zsh/$(uname).zshrc"
HOST_DEPENDENT="$HOME/.zsh/$HOST.zshrc"

if [[ -a $SYSTEM_DEPENDENT ]]; then
    source $SYSTEM_DEPENDENT
fi

if [[ -a $HOST_DEPENDENT ]]; then
    source $HOST_DEPENDENT
fi

##>> Editor
# Emacs & emacsclient invocation
# Usually editorG is called prior to an invokation of editor
#editor() {
#    _editor $@
#}

#editorG() {
#    _editorG $@
#}

#export EDITOR=editor
#export EDITORG=editorG

###>> Aliases
alias sudo='sudo '

# Platform specific aliases
#alias sys=
#alias sysi=
#alias syss=
#alias sysp=
#alias sysS=
#alias tmp=

alias mc='LC_ALL=en_US.utf8 LANG=en_UK.utf8 mc'

alias ll='ls -lha'
alias l='ls -lh'

alias cdd='cd $HOME/data/Documents'
alias cdp='cd $HOME/data/projects'
alias p='print -l'
alias pp='p $path'

# editor
alias e='$EDITOR'

alias s='git'
alias ss='s status'
alias sc='s commit -a -m '
alias sp='s push origin'

##>> Shell customization
# shell history
# taken from: http://en.gentoo-wiki.com/wiki/Zsh
export HISTSIZE=1000
export SAVEHIST=1000 # only saved after logout
export HISTFILE=$HOME/.zshhist
setopt \
    inc_append_history \
    hist_save_no_dups \
    hist_reduce_blanks \
    hist_ignore_all_dups

setopt \
  autocd \
  extendedglob \
  extendedhistory \
  nomatch \
  promptsubst \
  completealiases

# Use vi like for command line 
bindkey -v

# Make jj instead of esc go into normal-mode
bindkey -M viins 'jj' vi-cmd-mode

bindkey "^r" history-incremental-search-backward
# Moving around
#bindkey "^L" forward-char
#bindkey "^H" backward-char
#bindkey "^W" forward-word
#bindkey "^B" backward-word

# Killing
#bindkey "^D" kill-char
#bindkey "^X" kill-char
#bindkey "^X" backward-kill-char
#bindkey "^K" kill-word
#bindkey "^D" backward-kill-word
#bindkey "^L" kill-whole-line

# change $fpath before calling compinit
fpath=($HOME/.zsh/functions $fpath)
autoload -Uz compinit
autoload -Uz complist
autoload -Uz zutil
compinit

##>> Colordiff
# alias colordiff if it's on the path
hash colordiff 2>/dev/null >/dev/null && alias diff='colordiff'

##>> Prompt
# credits:
# - http://aperiodic.net/phil/prompt/
#     very thorough explanation of most of the things happening in
#     precmd, preexec, and setprompt. Thanks for putting that page
#     online.
# - Merci gäu dän


if (( $+commands[git] ))
then
  git="$commands[git]"
else
  git="/usr/bin/git"
fi

git_branch() {
  echo $($git symbolic-ref HEAD 2>/dev/null | awk -F/ {'print $NF'})
}

git_dirty() {
  st=$($git status 2>/dev/null | tail -n 1)
  if [[ $st == "" ]]
  then
    echo ""
  else
    if [[ "$st" =~ ^nothing ]]
    then
      echo "%{$reset_color%} on %{$fg_bold[green]%}$(git_prompt_info)%{$reset_color%}"
    else
      echo "%{$reset_color%} on %{$fg_bold[red]%}$(git_prompt_info)%{$reset_color%}"
    fi
  fi
}

git_prompt_info () {
 ref=$($git symbolic-ref HEAD 2>/dev/null) || return
# echo "(%{\e[0;33m%}${ref#refs/heads/}%{\e[0m%})"
 echo "${ref#refs/heads/}"
}

# Compute the length of git status information shown in prompt
git_prompt_size () {
 local zero='%([BSUbfksu]|([FB]|){*})' # removes escape characters
 promptgit="$(git_dirty)"
 ${#${(S%%)promptgit//$~zero/}}
}
 
unpushed () {
  $git cherry -v @{upstream} 2>/dev/null
}

git_need_push () {
  if [[ $(unpushed) == "" ]]
  then
    echo ""
  else
    echo " %{$fg_bold[red]%}!%{$reset_color%}"
  fi
}
 

# calculate cmd extends
function precmd {
 local TERMWIDTH
 (( TERMWIDTH = ${COLUMNS} - 1 ))

 # truncate the path if it's too long.
 PR_FILLBAR=""
 PR_PWDLEN=""

 # compute size of prompt and pwd

 local promptsize=${#${(%):-%n@%m }}
 local pwdsize=${#${(%):-%~}}

 local zero='%([BSUbfksu]|([FB]|){*})' # removes escape characters
 local promptgit="$(git_dirty)$(git_need_push)"
 local promptgitsize=${#${(S%%)promptgit//$~zero/}}

  if [[ "$promptsize + $pwdsize + $promptgitsize" -gt $TERMWIDTH ]]; then
     ((PR_PWDLEN=$TERMWIDTH - $promptsize))
 else
     PR_FILLBAR="\${(l.(($TERMWIDTH - ($promptsize + $pwdsize + $promptgitsize)))..${PR_HBAR}.)}"
 fi

 # print a 'bell' character:
 # In combination with 'URxvt.urgentOnBell: true' in your ~/.Xresources,
 # this will set an X11 urgent flag on the window when the prompt gets
 # redrawn. Handy to get informed about longrunning commands
 # finishishing in the foreground in not currently visible windows.
 print -n '\a'
}

# preexec is executed just after pressing enter.
# it's used to set the window title to just the command used
# preexec () {
#   local CMD=${1[(wr)^(*=*|sudo|-*)]}
#   echo -ne "\ek$CMD\e\\"
# }

# called once to initialize things.
setprompt () {
 # need this so the prompt will work.
 setopt prompt_subst

 autoload colors zsh/terminfo
 if [[ "$terminfo[colors]" -ge 8 ]]; then
   colors
 fi

 # crazy hack to get portable colorcodes
 for color in RED GREEN YELLOW BLUE MAGENTA CYAN WHITE; do
   eval PR_$color='%{$terminfo[bold]$fg[${(L)color}]%}'
   eval PR_LIGHT_$color='%{$terminfo[none]$fg[${(L)color}]%}'
       (( count = $count + 1 ))
 done
 PR_NO_COLOUR="%{$terminfo[sgr0]%}"

  # see if we can use extended characters to look nicer.
 typeset -A altchar
 set -A altchar ${(s..)terminfo[acsc]}
 PR_SET_CHARSET="%{$terminfo[enacs]%}"
 PR_SHIFT_IN="%{$terminfo[smacs]%}"
 PR_SHIFT_OUT="%{$terminfo[rmacs]%}"
 PR_HBAR=${altchar[q]:--}
 PR_ULCORNER=${altchar[l]:--}
 PR_LLCORNER=${altchar[m]:--}
 PR_LRCORNER=${altchar[j]:--}
 PR_URCORNER=${altchar[k]:--}

 # left prompt
 PROMPT='$PR_SET_CHARSET\
%(!.%SROOT%s.%n)$PR_LIGHT_YELLOW@%m\
$PR_NO_COLOUR %$PR_PWDLEN<...<$PR_YELLOW${(%):-%~}$(git_dirty)$(git_need_push)\
%<<$PR_NO_COLOUR $PR_SHIFT_IN${(e)PR_FILLBAR}$PR_SHIFT_OUT
$PR_NO_COLOUR%! %(!.$PR_RED.$PR_WHITE)%#$PR_NO_COLOUR '
 #PS1="%{$fg[red]%}%n%{$reset_color%}@%{$fg[yellow]%}%m %{$fg[green]%}%~ %{$reset_color%}%% "

 # right prompt
 RPROMPT=''

 # continuation prompt
 PS2='$PR_CYAN$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT\
$PR_BLUE$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT(\
$PR_LIGHT_GREEN%_$PR_BLUE)$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT\
$PR_CYAN$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT$PR_NO_COLOUR '
}

# Remove duplicates
typeset -U path

setprompt

# colorized stderr
# http://en.gentoo-wiki.com/wiki/Zsh
# TODO: there seme to be an error in coloring...
#exec 2>>(while read line; do
#  print '\e[91m'${(q)line}'\e[0m' > /dev/tty; print -n $'\0'; done &)
