@echo off
echo 启动 GodoRoom 多人在线房间游戏...
echo.

REM 检查是否有 Godot 在路径中
where godot.exe >nul 2>&1
if %errorlevel% == 0 (
    echo 使用系统路径中的 Godot...
    godot.exe --path . 
    goto :end
)

REM 尝试使用当前目录的 Godot
if exist "..\godot.exe" (
    echo 使用本地 Godot...
    "..\godot.exe" --path .
    goto :end
)

REM 尝试其他常见路径
if exist "C:\Program Files\Godot\godot.exe" (
    echo 使用 Program Files 中的 Godot...
    "C:\Program Files\Godot\godot.exe" --path .
    goto :end
)

echo.
echo 无法找到 Godot 引擎！
echo.
echo 请确保 Godot 4.4 已安装，然后：
echo 1. 打开 Godot 编辑器
echo 2. 点击 "导入" 按钮
echo 3. 选择此目录下的 project.godot 文件
echo 4. 点击播放按钮运行游戏
echo.
echo 服务器要求：
echo - jigger_protobuf 服务器需要在 localhost:8080 运行
echo - 确保 WebSocket 端点 /ws 可用
echo.
pause

:end