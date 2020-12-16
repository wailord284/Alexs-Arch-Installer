#Alexs custom bash stuff
# ~/.bashrc
# If not running interactively, don't do anything
[[ $- != *i* ]] && return
cat /usr/share/pokeshell/$(($RANDOM % 151 + 1)).pokemon
#Colors for ls
. /usr/share/LS_COLORS/dircolors.sh
#Do not save cmds with " " in front or duplicate commands run after eachother
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
#Add date formatting to .bash_history
export HISTTIMEFORMAT="%h %d %H:%M:%S "
#Alias stuff
alias ls='ls --color=auto --group-directories-first'
alias ip='ip -c'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
export VISUAL="gedit"
export BROWSER="librewolf"
export EDITOR="nano"
export SUDO_EDITOR="nano"
shopt -s autocd
shopt -s checkwinsize
shopt -s cdspell
shopt -s dirspell
shopt -s histappend
#Personal pacman/yay commands
alias ys='yay'
alias ydd='yay -Rdd'
alias yrc='yay -Rnsc'
alias yr='yay -Rns'
alias yss='yay -Ss'
alias yq='yay -Qm'
alias yi='yay -S'
alias yin='yay -S --noconfirm'
alias pss='sudo pacman -Ss'
alias ycc='yay -Scc'
alias ysn='yay -Syua --noconfirm'
alias orphan='sudo pacman -Rns $(pacman -Qtdq)'
#Other alias commands
alias entropy='cat /proc/sys/kernel/random/entropy_avail'
alias cpuwatch='watch grep \"cpu MHz\" /proc/cpuinfo'
alias syncwatch='watch -d grep -e Dirty: -e Writeback: /proc/meminfo'
alias carp='sudo ip -s -s neigh flush all'
alias cpr='rsync -ah --info=progress2'
alias mousefix='sudo modprobe -r psmouse && sudo modprobe psmouse'
alias ipinfo='curl ipinfo.io'
alias cls='clear'
alias dl='youtube-dl -x --format m4a --youtube-skip-dash-manifest --audio-quality 1 --prefer-ffmpeg --embed-thumbnail -ci -o "%(title)s-%(id)s.%(ext)s"'
alias update-mirror="sudo reflector -f 10 --verbose --latest 20 --protocol https --country US --save /etc/pacman.d/mirrorlist"
#https://askubuntu.com/questions/627621/no-object-for-d-bus-interface-when-mounting-with-nautilus/1128845
alias dbusfix='systemctl --user restart gvfs-udisks2-volume-monitor'
alias update-grub='sudo grub-mkconfig -o /boot/grub/grub.cfg'

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

#Smile or Frown based on exit status in the PS1 prompt
BRED='\[\e[1;31m\]'
BGRED='\[\e[41m\]'
BGREEN='\[\e[1;32m\]'
BGWHITE='\[\e[1;37m\]'
BCYAN='\[\e[1;36m\]'
BMAGENTA='\[\e[1;35m\]'
PROMPT_COMMAND=exitstatus
exitstatus() {
if [ "$?" -eq "0" ]; then
	SC="${BGREEN}:)"
else
	SC="${BRED}:("
fi
#${directory}
PS1="${BGWHITE}[\A][\u${BGWHITE}@${BGREEN}\h ${BGWHITE}\W${BGWHITE}] ${SC}${BGWHITE} "
}
