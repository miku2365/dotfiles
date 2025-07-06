###### .dotfiles/fishrc ######

# vi:ft=fish
set DISABLE_FZF_AUTO_COMPLETION true
export TERM="xterm-256color"
export EDITOR="nvim"

# PATH settings
set -x GOPATH "$XDG_DATA_HOME/go"
set -x FLYCTL_INSTALL "$XDG_DATA_HOME/fly"
set -x LESSHISTFILE "$XDG_STATE_HOME/less/history"
set -x PYTHONHISTORY "$XDG_STATE_HOME/python_history"
set PATH /usr/local/go/bin $HOME/.local/bin $FLYCTL_INSTALL/bin $GOPATH/bin $HOME/.dotfiles/bin $PATH
# node
set -U nvm_default_version v23
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export NPM_CONFIG_INIT_MODULE="$XDG_CONFIG_HOME/npm/config/npm-init.js"
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"
export NPM_CONFIG_TMP="$XDG_RUNTIME_DIR/npm"
# GPG Key
export GPG_TTY=$(tty)
# Other
set -x BAT_THEME "Dracula"

# Aliases
alias vim='nvim'
alias afind='ack -il'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias gc1='git clone --recursive --depth=1'
alias globurl='noglob urlglobber '
alias grep='grep --color=auto'
alias md='mkdir -p'
alias rd=rmdir
alias rm='rm -i'
alias adb-i="adb connect 127.0.0.1:6532"
alias run='ranger'
alias warp-i='curl https://www.cloudflare.com/cdn-cgi/trace'
######
# nali
if command -v nali -q
    function nali_cmd
      command $argv | nali
    end
    alias ping='nali_cmd ping'
    alias dig='nali_cmd dig'
    alias nslookup='nali_cmd nslookup'
    alias tracepath='nali_cmd tracepath'
    alias traceroute='nali_cmd traceroute'
end
# eza
if command -v eza -q
    set -x DISABLE_LS_COLORS
    set -e LS_BIN_FILE
    for i in /bin/ls $PREFIX/bin/ls /usr/bin/ls /usr/local/bin/ls
        if test -x $i
            set LS_BIN_FILE $i
            break
        end
    end
    if test -z $LS_BIN_FILE
        set LS_BIN_FILE (command whereis ls 2>/dev/null | awk '{print $2}')
    end
    alias lls $LS_BIN_FILE
    alias ls 'eza --color=auto --icons'
    alias l 'eza -lbah --icons'
    alias la 'eza -labgh --icons'
    alias ll 'eza -lbg --icons'
    alias lsa 'eza -lbagR --icons'
    alias lst 'eza -Tabgh --icons -I "node_modules|.deploy_git|.git|.npm|.npm|.cache|.zinit|.pyenv" -L 3'
else
    alias ls 'ls --color=auto'
    alias lst 'tree -pCsh'
    alias l 'ls -lah'
    alias la 'ls -lAh'
    alias ll 'ls -lh'
    alias lsa 'ls -lah'
end
######
# bat
function set_bat_paper_variable
    set -l CAT_BIN_FILE
    for i in /bin/cat $PREFIX/bin/cat /usr/bin/cat /usr/local/bin/cat
        if test -x $i
            set CAT_BIN_FILE $i
            break
        end
    end
    if test -z $CAT_BIN_FILE
        set CAT_BIN_FILE (command whereis cat 2>/dev/null | awk '{print $2}')
    end
    alias lcat $CAT_BIN_FILE
    set -g BAT_PAGER "less -m -RFQ"
end
for i in bat 
    if command -v $i -q
        alias cat "$i -pp"
        set_bat_paper_variable
        break
    end
end

###### .config/fish/config.fish ######
if status is-interactive
    # Commands to run in interactive sessions can go here
end

# starship 主题
starship init fish | source
