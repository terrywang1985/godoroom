#!/bin/bash

echo "========================================"
echo "      启动 GodoRoom 游戏客户端"
echo "========================================"
echo

# 检查 Godot 可执行文件是否存在
if [ ! -f "../godot.exe" ]; then
    echo "错误：找不到 godot.exe，请确保 Godot 编辑器在上级目录中"
    echo "当前查找路径：../godot.exe"
    read -p "按 Enter 键退出..."
    exit 1
fi

echo "正在启动游戏..."
echo "提示：关闭游戏窗口或按 Ctrl+C 停止运行"
echo

# 直接运行项目（不打开编辑器）
"../godot.exe" --main-pack project.godot

# 如果上面的命令不工作，尝试这个替代方法
if [ $? -ne 0 ]; then
    echo
    echo "尝试备用启动方法..."
    "../godot.exe" project.godot
fi

echo
echo "游戏已退出"
read -p "按 Enter 键退出..."