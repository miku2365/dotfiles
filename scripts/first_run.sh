#!/bin/bash

# 设置 XDG 标准目录变量并使用 typeset -x 导出为环境变量
typeset -x XDG_CONFIG_HOME="$HOME/.config"
typeset -x XDG_DATA_HOME="$HOME/.local/share"
typeset -x XDG_CACHE_HOME="$HOME/.cache"
typeset -x XDG_RUNTIME_DIR="/run/user/$(id -u)"
typeset -x XDG_STATE_HOME="$HOME/.local/state"

# 创建必要的目录
mkdir -p "$XDG_CONFIG_HOME"
mkdir -p "$XDG_DATA_HOME"
mkdir -p "$XDG_CACHE_HOME"
mkdir -p "$XDG_RUNTIME_DIR"
mkdir -p "$XDG_STATE_HOME"

# 设置 Bash
HISTFILE="${XDG_STATE_HOME}/bash/history"
mkdir -p "$(dirname "$HISTFILE")"
cat << 'EOF' >> ~/.bashrc

# 设置 XDG 标准目录变量并使用 typeset -x 导出为环境变量
typeset -x XDG_CONFIG_HOME="$HOME/.config"
typeset -x XDG_DATA_HOME="$HOME/.local/share"
typeset -x XDG_CACHE_HOME="$HOME/.cache"
typeset -x XDG_RUNTIME_DIR="/run/user/$(id -u)"
typeset -x XDG_STATE_HOME="$HOME/.local/state"

# 设置 Bash
shopt -s histappend
shopt -s histverify
HISTFILE="${XDG_STATE_HOME}/bash/history"
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
linecount=\$(wc -l < ${HISTFILE})
if ((\$linecount > \$max_lines)); then
  echo -e "\e[31m[WARN] \e[33mArchiving History Files\e[0m"
  prune_lines=\$((\$linecount - \$max_lines))
  head -\$prune_lines ${HISTFILE} >> ${HISTFILE}.archive \
    && sed -e "1,\$prune_lines"d  ${HISTFILE} > ${HISTFILE}.tmp\$ \
    && mv ${HISTFILE}.tmp\$ ${HISTFILE}
fi


EOF

# 系统检测
echo "检测系统版本..."
if grep -q "Debian" /etc/os-release; then
    VERSION=$(grep VERSION_ID /etc/os-release | cut -d '"' -f 2)
    if [[ "$VERSION" == "12" ]]; then
        echo "检测到 Debian 12"

        # 安装必要的软件包
        echo "更新 APT 包列表..."
        sudo apt update

        echo "安装 fish 和 cloudflared..."
        sudo apt install fish curl -y
        curl -fsSL --location --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
        sudo dpkg -i cloudflared.deb
        sudo apt-get install -f -y  # 解决依赖关系
    else
        echo "不支持的 Debian 版本: $VERSION"
        exit 1
    fi
else
    echo "不支持的操作系统。此脚本仅适用于 Debian 12。"
    exit 1
fi

# 安装软件
echo "安装 APT 软件包..."
sudo apt install -y gawk

# 其他软件安装（根据需要添加）
# 例如：
# sudo apt install -y vim git

echo "脚本执行完成。"
