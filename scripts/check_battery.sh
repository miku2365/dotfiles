#!/bin/bash

# ==========================================
# 1. 定义常量：将颜色和图标提取出来，方便后期修改
# ==========================================
COLOR_PURPLE="\033[35m"
COLOR_GREEN="\033[32m"
COLOR_RED="\033[31m"
COLOR_RESET="\033[0m"

ICON_CHARGE=""
ICON_GOOD="󱊢"
ICON_LOW="󰂃"
ICON_ERROR="󰂏"

# ==========================================
# 2. 网络请求与异常处理
# ==========================================
# 优化点：增加 -w 1 (1秒超时)，防止 8423 端口的服务卡死导致脚本无限挂起
response=$(echo -e "get battery_power_plugged\nget battery" | nc -w 1 -q 0 127.0.0.1 8423 2>/dev/null)

# 如果没获取到任何响应（比如后台服务没启动），直接输出错误图标并退出
if [[ -z "$response" ]]; then
    echo -e "${COLOR_RED}${ICON_ERROR}${COLOR_RESET} N/A"
    exit 1
fi

# ==========================================
# 3. 数据提取 (Bash 原生正则)
# ==========================================
power_status="false"
battery_level="0"

# 使用 Bash 内置的 =~ 进行正则匹配，并将括号捕获的内容存入 BASH_REMATCH 数组
if [[ "$response" =~ battery_power_plugged:\ (true|false) ]]; then
    power_status="${BASH_REMATCH[1]}"
fi

if [[ "$response" =~ battery:\ ([0-9]+) ]]; then
    battery_level="${BASH_REMATCH[1]}"
fi

# ==========================================
# 4. 状态判断与输出
# ==========================================
if [[ "$power_status" == "true" ]]; then
    echo -e "${COLOR_PURPLE}${ICON_CHARGE}${COLOR_RESET} USB Power"
else
    if (( battery_level > 20 )); then
        echo -e "${COLOR_GREEN}${ICON_GOOD}${COLOR_RESET} ${battery_level}%"
    else
        echo -e "${COLOR_RED}${ICON_LOW}${COLOR_RESET} ${battery_level}%"
    fi
fi
