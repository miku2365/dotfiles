#!/bin/bash

dietpiEnvVersion="Automation_Custom_Script"
START_TIME=$(date +%s)

start() {
    echo "==========================================================="
    echo "                !! ATTENTION !!"
    echo "YOU ARE SETTING UP: DietPi Environment (${dietpiEnvVersion})"
    echo "==========================================================="
    echo ""
    echo -n "* The setup will begin in 5 seconds... "

    sleep 5

    echo -n "Times up! Here we start!"
    echo ""
    echo "Setting XDG standard directory variables..."
    typeset -x XDG_CONFIG_HOME="/root/.config"
    typeset -x XDG_DATA_HOME="/root/.local/share"
    typeset -x XDG_CACHE_HOME="/root/.cache"
    typeset -x XDG_RUNTIME_DIR="/run/user/$(id -u)"
    typeset -x XDG_STATE_HOME="/root/.local/state"
    echo "Create necessary directories and set permissions..."
    create_and_verify_dir() {
        local dir="$1"
        install -d -m 700 "$dir"
        if [ $? -eq 0 ]; then
            echo "Directory $dir created successfully"
        else
            echo "Failed to create directory $dir"
            exit 1
        fi
    }

    create_and_verify_dir "$XDG_CONFIG_HOME"
    create_and_verify_dir "$XDG_DATA_HOME"
    create_and_verify_dir "$XDG_CACHE_HOME"
    create_and_verify_dir "$XDG_RUNTIME_DIR"
    create_and_verify_dir "$XDG_STATE_HOME"
}

install-linux-packages() {
    echo "==========================================================="
    echo "* Install following packages:"
    echo ""
    echo "  - bat"
    echo "  - cloudflared"
    echo "  - eza"
    echo "  - fd"
    echo "  - fish"
    echo "  - fzf"
    echo "  - nvim"
    echo "  - ripgrep"
    echo "-----------------------------------------------------------"

    echo "Add software source"
    source /etc/os-release
    sudo mkdir -p --mode=0755 /usr/share/keyrings
    # cloudflared
    curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg > /dev/null
    echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo tee /etc/apt/sources.list.d/cloudflared.list
    # fish
    case $VERSION_CODENAME in
      "unstable")
        echo "Detected Debian Unstable"
        echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/4/Debian_Unstable/ /' | sudo tee /etc/apt/sources.list.d/shells:fish:release:4.list
        curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:4/Debian_Unstable/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/shells_fish_release_4.gpg > /dev/null
        ;;
      "bookworm")
        echo "Detected Debian 12 (Bookworm)"
        echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/4/Debian_12/ /' | sudo tee /etc/apt/sources.list.d/shells:fish:release:4.list
        curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:4/Debian_12/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/shells_fish_release_4.gpg > /dev/null
        ;;
      "bullseye")
        echo "Detected Debian 11 (Bullseye)"
        echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/4/Debian_11/ /' | sudo tee /etc/apt/sources.list.d/shells:fish:release:4.list
        curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:4/Debian_11/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/shells_fish_release_4.gpg > /dev/null
        ;;
      *)
        echo "Unsupported Debian version: $VERSION_CODENAME"
        exit 1
        ;;
  esac
    sudo apt-get update && sudo apt-get install -y cloudflared fish unar

    install-packages-github() {
        local name="$1"
        local version="$2"
        local arch="$3"
        local url_template="$4"
        local command="$5"
        local file_type="$6"
        local post_install_command="$7"
        local deb_url="${url_template//\{VERSION\}/$version}"
        deb_url="${deb_url//\{ARCH\}/$arch}"
        local temp_dir="/tmp/${name}_${version}_${arch}"
        local deb_file="${temp_dir}/${name}_${version}_${arch}.${file_type}"

        echo "Download $name..."
        mkdir -p "$temp_dir"
        curl -sL "$deb_url" -o "$deb_file"

        if [ "$file_type" == "deb" ]; then
            echo "Install $name..."
            sudo dpkg -i "$deb_file" || sudo apt-get install -f -y
    elif     [ "$file_type" == "tar.gz" ]; then
            echo "Extracting $name..."
            unar "$deb_file" -o "$temp_dir"
            echo "Copying $name to /usr/local/bin..."
            #sudo cp "${temp_dir}/${name}" /usr/local/bin/
            sudo fd -t x "${name}" "${temp_dir}" -x cp {} /usr/local/bin/
            sudo chmod +x /usr/local/bin/"$name"
    else
            echo "Unsupported file type: $file_type"
            rm -rf "$temp_dir"
    fi

        if command -v "$command" &> /dev/null; then
            echo "$name Installation successfully! Version:$($command --version)"
    else
            echo "$name Installation failed, please check for error message."
            rm -rf "$temp_dir"
    fi

        if [ -n "$post_install_command" ]; then
            echo "Running post-install command: $post_install_command"
            eval "$post_install_command"
    fi

        rm -rf "$temp_dir"
  }

    # fd
    install-packages-github \
        "fd" \
        "10.2.0" \
        "arm64" \
        "https://github.com/sharkdp/fd/releases/download/v{VERSION}/fd_{VERSION}_{ARCH}.deb" \
        "fd" \
        "deb"

    # bat
    install-packages-github \
        "bat" \
        "0.25.0" \
        "arm64" \
        "https://github.com/sharkdp/bat/releases/download/v{VERSION}/bat_{VERSION}_{ARCH}.deb" \
        "bat" \
        "deb"

    # fzf
    install-packages-github \
        "fzf" \
        "0.61.1" \
        "linux_arm64" \
        "https://github.com/junegunn/fzf/releases/download/v{VERSION}/fzf-{VERSION}-{ARCH}.tar.gz" \
        "fzf" \
        "tar.gz"

    # eza
    install-packages-github \
        "eza" \
        "0.21.0" \
        "aarch64-unknown-linux-gnu" \
        "https://github.com/eza-community/eza/releases/download/v{VERSION}/eza_{ARCH}.tar.gz" \
        "eza" \
        "tar.gz" \
        "mkdir -p /tmp/eza_complete && curl -sL 'https://github.com/eza-community/eza/releases/download/v0.21.0/completions-0.21.0.tar.gz' | sudo tar -xz -C /tmp/eza_complete"

    # ripgrep
    install-packages-github \
        "rg" \
        "14.1.1" \
        "aarch64-unknown-linux-gnu" \
        "https://github.com/BurntSushi/ripgrep/releases/download/{VERSION}/ripgrep-{VERSION}-{ARCH}.tar.gz" \
        "rg" \
        "tar.gz" \
        "mkdir -p /tmp/rg_complete && fd -t f "rg.fish" "/tmp/" -x cp {} /tmp/rg_complete/"

    # nvim
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.tar.gz
    sudo unar nvim-linux-arm64.tar.gz -o /opt
}

clone-repo() {
    echo "-----------------------------------------------------------"
    echo "* Cloning dotfiles Repo from GitHub.com"
    echo "-----------------------------------------------------------"
    git clone https://github.com/miku2365/dotfiles.git /root/dotfiles
}

setup-bash() {
    echo "==========================================================="
    echo "                      Bash Setup"
    echo "-----------------------------------------------------------"
    export XDG_DATA_HOME="/root/.local/share"
    HISTFILE="${XDG_DATA_HOME}/bash/history"
    echo "HISTFILE path: $HISTFILE"
    DIRNAME=$(dirname "$HISTFILE")
    echo "Directory path: $DIRNAME"
    # Create directory and verify
    mkdir -p "$DIRNAME"
    if [ $? -eq 0 ]; then
        echo "Directory $DIRNAME created successfully"
    else
        echo "Failed to create directory $DIRNAME"
        exit 1
    fi
    # Create file and verify
    touch "$HISTFILE"
    if [ $? -eq 0 ]; then
        echo "File $HISTFILE created successfully"
    else
        echo "Failed to create file $HISTFILE"
        exit 1
    fi
    # Set permissions and verify
    chmod 600 "$HISTFILE"
    if [ $? -eq 0 ]; then
        echo "Permissions for file $HISTFILE set successfully"
    else
        echo "Failed to set permissions for file $HISTFILE"
        exit 1
    fi
    cat << 'EOF' >> /root/.bashrc

# 设置 XDG 标准目录变量并使用 typeset -x 导出为环境变量
typeset -x XDG_CONFIG_HOME="$HOME/.config"
typeset -x XDG_DATA_HOME="$HOME/.local/share"
typeset -x XDG_CACHE_HOME="$HOME/.cache"
typeset -x XDG_RUNTIME_DIR="/run/user/$(id -u)"
typeset -x XDG_STATE_HOME="$HOME/.local/state"

# 设置 Bash
shopt -s histappend
shopt -s histverify
HISTFILE="${XDG_DATA_HOME}/bash/history"
# 无限记录
HISTFILESIZE=400000000
HISTSIZE=50000
# 连续重复/忽略空格
HISTCONTROL=ignoreboth
# 自动保存
PROMPT_COMMAND="history -a"

# 压缩历史记录文件
awk 'NR==FNR && !/^#/{lines[$0]=FNR;next} lines[$0]==FNR' "$HISTFILE" "$HISTFILE" > "$HISTFILE.compressed" && mv "$HISTFILE.compressed" "$HISTFILE"

# 存档历史记录
umask 077
max_lines=5000
linecount=$(wc -l < "$HISTFILE")
if (( linecount > max_lines )); then
  echo -e "\e[31m[WARN] \e[33mArchiving History Files\e[0m"
  prune_lines=$(( linecount - max_lines ))
  head -"$prune_lines" "$HISTFILE" >> "${HISTFILE}.archive" \
    && sed -e "1,${prune_lines}d" "$HISTFILE" > "${HISTFILE}.tmp" \
    && mv "${HISTFILE}.tmp" "$HISTFILE"
fi

EOF
}

setup-fish() {
    echo "==========================================================="
    echo "                      Fish Setup"
    echo "-----------------------------------------------------------"
    echo "* Installing Fish Custom Plugins & Themes:"
    echo ""
    echo "  - fzf"
    echo "  - fisher"
    echo "  - nvm"
    echo "  - sponge"
    echo "  - Starship"
    echo "  - z"
    echo "-----------------------------------------------------------"

    if command -v fish &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
        fish -c '
            curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source &&
            fisher install jorgebucaran/fisher &&
            fisher install jorgebucaran/nvm.fish &&
            fisher install jethrokuan/z &&
            fisher install meaningful-ooo/sponge &&
            fisher install PatrickF1/fzf.fish
        '

        # 向 .bashrc 追加代码，以便在 Bash 启动时自动切换到 fish
        cat << 'EOF' >> /root/.bashrc

# 通过 .bashrc 启动 fish
if [[ $(ps --no-header --pid=$PPID --format=cmd) != "fish" && -z ${BASH_EXECUTION_STRING} && ${SHLVL} == '1' ]]
then
    exec fish
fi

EOF
    cp /root/dotfiles/_fishrc/config.fish /root/.config/fish/config.fish
    cp /root/dotfiles/_fishrc/dietpi.fish /root/.config/fish/conf.d/dietpi.fish
    cp /root/dotfiles/starship/starship.toml /root/.config/
    fd -t f 'eza.fish' /tmp/eza_complete -x cp {} ~/.config/fish/completions/
    fd -t f 'rg.fish' /tmp/rg_complete -x cp {} ~/.config/fish/completions/
    rm -rf /tmp/eza_complete /tmp/rg_complete
  else
        echo "fish 未安装，跳过设置。"
  fi
}

install-nodejs() {
    install-node() {
        echo "-----------------------------------------------------------"
        echo "* Installing NodeJS latest..."
        echo "-----------------------------------------------------------"
        fish -c 'nvm install latest'
        echo "-----------------------------------------------------------"
        echo -n "* NodeJS Version: "
        fish -c 'nvm list'
  }
    install-node
}

install-nali() {
    echo "==========================================================="
    echo "                   Installing Nali                         "
    echo ""
    echo "-----------------------------------------------------------"
    /boot/dietpi/dietpi-software intall 188
    echo "-----------------------------------------------------------"
    echo "* Install Nali..."
    echo "-----------------------------------------------------------"
    export GOPATH="$XDG_DATA_HOME/go"
    export PATH="$GOPATH/bin:$PATH"
    go install github.com/zu1k/nali@latest
    echo "-----------------------------------------------------------"
    echo "* Updating Nali IP Database..."
    echo "-----------------------------------------------------------"
    sudo nali update
}

finish() {
    END_TIME=$(date +%s)
    ELAPSED_TIME=$((END_TIME - START_TIME))
    echo "==========================================================="
    echo "> DietPi Enviroment Setup finished!"
    echo "Script execution completed. Total time elapsed: $ELAPSED_TIME seconds"
    echo ""
    echo "==========================================================="
}

start
install-linux-packages
clone-repo
setup-bash
setup-fish
install-nodejs
# install-nali
finish
