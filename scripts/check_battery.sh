#!/bin/bash

# 获取所有需要的信息
response=$(echo -e "get battery_power_plugged\nget battery" | nc -q 0 127.0.0.1 8423)

# 使用 rg 提取充电状态和电池电量
power_status=$(echo "$response" | rg -oP 'battery_power_plugged: \K(true|false)')
battery_level=$(echo "$response" | rg -oP 'battery: \K\d+')

if [[ "$power_status" == "true" ]]; then
    # 正在充电
    echo -e "\033[35m\033[0m USB Power"
else
    # 检查电池电量
    if ((battery_level > 20)); then
        echo -e "\033[32m󱊢\033[0m $battery_level%"
  else
        echo -e "\033[31m󰂃\033[0m $battery_level%"
  fi
fi
