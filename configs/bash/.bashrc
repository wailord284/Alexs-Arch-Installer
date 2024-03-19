#Alexs custom bash stuff
#If not running interactively, don't do anything
[[ $- != *i* ]] && return
#Bash completion
[ -r /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion
#Kitty shell integration
if test -n "$KITTY_INSTALLATION_DIR"; then
	export KITTY_SHELL_INTEGRATION="enabled"
	source "$KITTY_INSTALLATION_DIR/shell-integration/bash/kitty.bash"
fi
#Do not save cmds with " " in front or duplicate commands run after eachother
HISTSIZE=2500
HISTFILESIZE=10000
HISTCONTROL="erasedups:ignoreboth"
#Add date formatting to .bash_history
export HISTTIMEFORMAT="%h %d %H:%M:%S "
#Bash changes
shopt -s autocd
shopt -s checkwinsize
shopt -s cdspell
shopt -s dirspell
shopt -s histappend
shopt -s cmdhist
#Editors
export VISUAL="mousepad"
export BROWSER="firefox"
export EDITOR="nano"

#Colors
alias ls='ls --color=auto --group-directories-first'
alias ip='ip -c'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias man='tldr'
. /usr/share/LS_COLORS/dircolors.sh
/usr/bin/pokemon-colorscripts -r

#XDG stuff
alias wget='wget --hsts-file=$XDG_CACHE_HOME/wget-hsts'
alias svn='svn --config-dir $XDG_CONFIG_HOME/subversion'
alias gdb='gdb -nh -x $XDG_CONFIG_HOME/gdb/init'
alias gpg='gpg2 --homedir $XDG_DATA_HOME/gnupg'
alias gpg2='gpg2 --homedir $XDG_DATA_HOME/gnupg'
alias yarn='yarn --use-yarnrc $XDG_CONFIG_HOME/yarn/config'
alias x2goclient='x2goclient --home=$XDG_CONFIG_HOME'
alias nano='nano --rcfile ~/.config/nano/nanorc'
alias adb='HOME=$XDG_DATA_HOME/android adb'

#Personal pacman/paru commands
alias ys='trizen -Syu'
alias ydd='trizen -Rdd'
alias yrc='trizen -Rnsc'
alias yr='trizen -Rns'
alias yss='trizen -Ss'
alias yq='trizen -Qm'
alias yi='trizen -S'
alias yin='trizen -S --noconfirm'
alias ycc='trizen -Scc'
alias ysn='trizen -Syu --noconfirm'
alias pss='sudo pacman -Ss'
alias orphan='sudo pacman -Rns $(pacman -Qtdq)'

#Other alias commands
alias su='su -l'
alias cpuwatch='watch grep \"cpu MHz\" /proc/cpuinfo'
alias syncwatch='watch -d grep -e Dirty: -e Writeback: /proc/meminfo'
alias carp='sudo ip -s -s neigh flush all'
alias cpr='rsync -ah --info=progress2'
alias mousefix='sudo modprobe -r psmouse && sudo modprobe psmouse'
alias dbusfix='systemctl --user restart gvfs-udisks2-volume-monitor'
alias ipinfo='curl https://am.i.mullvad.net/ip'
alias dl='yt-dlp -x --format m4a --youtube-skip-dash-manifest --audio-quality 1 --prefer-ffmpeg --embed-thumbnail -ci -o "%(title)s-%(id)s.%(ext)s"'
alias update-mirror="sudo reflector --download-timeout 10 --connection-timeout 10 --verbose -f 10 --latest 20 --country us --protocol https --age 24 --sort rate --save /etc/pacman.d/mirrorlist"
alias update-grub='sudo grub-mkconfig -o /boot/grub/grub.cfg'
alias topproc='ps --sort -rss -eo pid,pcpu,pmem,rss,vsz,comm | head -15'
alias reboot-uefi='sudo systemctl reboot --firmware-setup'
alias man='tldr'

### ARCHIVE EXTRACTION
# usage: ex <file>
ex ()
{
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1   ;;
      *.tar.gz)    tar xzf $1   ;;
      *.bz2)       bunzip2 $1   ;;
      *.rar)       unrar x $1   ;;
      *.gz)        gunzip $1    ;;
      *.tar)       tar xf $1    ;;
      *.tbz2)      tar xjf $1   ;;
      *.tgz)       tar xzf $1   ;;
      *.zip)       unzip $1     ;;
      *.Z)         uncompress $1;;
      *.7z)        7z x $1      ;;
      *.deb)       ar x $1      ;;
      *.tar.xz)    tar xf $1    ;;
      *.tar.zst)   unzstd $1    ;;
      *)           echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

#Some colors
BRED='\[\e[1;31m\]'
BGRED='\[\e[41m\]'
BGREEN='\[\e[1;32m\]'
BGWHITE='\[\e[1;37m\]'
BCYAN='\[\e[1;36m\]'
BMAGENTA='\[\e[1;35m\]'
#Smile or Frown based on exit status in the PS1 prompt
PROMPT_COMMAND='exitstatus && echo -ne "\033]0;${USER}@${HOSTNAME}\007"' 
exitstatus() {
if [ "$?" -eq "0" ]; then
	SC="${BGREEN}:)"
else
	SC="${BRED}:("
fi
#If the user is root change prompt to be red
if [ $(id -u) -eq 0 ]; then
	PS1="${BGWHITE}[\A][\u${BGWHITE}@${BRED}\h ${BGWHITE}\W${BGWHITE}] ${SC}${BGWHITE} "
else
	PS1="${BGWHITE}[\A][\u${BGWHITE}@${BMAGENTA}\h ${BGWHITE}\W${BGWHITE}] ${SC}${BGWHITE} "
fi
}