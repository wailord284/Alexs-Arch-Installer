##Some variables to help keep files out of ~
[[ -f ~/.bashrc ]] && . ~/.bashrc

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

export GTK2_RC_FILES="${XDG_CONFIG_HOME}/gtk-2.0/gtkrc"
export GNUPGHOME="${XDG_DATA_HOME}/gnupg"
export INPUTRC="${XDG_CONFIG_HOME}/readline/inputrc"
export LESSHISTFILE="${XDG_CACHE_HOME}/less/history"
export LESSKEY="${XDG_CONFIG_HOME}/less/lesskey"
export npm_config_cache="${XDG_CACHE_HOME}/npm"
export SCREENRC="${XDG_CONFIG_HOME}/screen/screenrc"
export CARGO_HOME="${XDG_CACHE_HOME}/cargo"
export GIMP2_DIRECTORY="${XDG_CONFIG_HOME}/gimp"
