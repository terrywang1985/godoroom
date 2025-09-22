@echo off
echo ========================================
echo      启动 GodoRoom 游戏客户端
echo ========================================
echo.

REM 检查 Godot 可执行文件是否存在
if not exist "..\godot.exe" (
    echo 错误：找不到 godot.exe，请确保 Godot 编辑器在上级目录中
    echo 当前查找路径：..\godot.exe
    pause
    exit /b 1
)

echo 正在启动游戏...
echo 提示：关闭游戏窗口或按 Ctrl+C 停止运行
echo.

REM 直接运行项目（不打开编辑器）
echo 使用命令："..\godot.exe" --no-editor "."
"..\godot.exe" --no-editor "."

REM 如果上面的命令不工作，尝试其他方法
if errorlevel 1 (
    echo.
    echo 尝试备用启动方法1...
    "..\godot.exe" "project.godot"
    
    if errorlevel 1 (
        echo.
        echo 尝试备用启动方法2...
        "..\godot.exe" .
    )
)

echo.
echo 游戏已退出
pause