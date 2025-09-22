@echo off
echo 正在复制 godobuf 插件文件...

REM 删除现有的 protobuf 目录内容
if exist "addons\protobuf" (
    rmdir /s /q "addons\protobuf"
)
mkdir "addons\protobuf"

REM 复制所有文件
copy "..\godobuf\addons\protobuf\*.gd" "addons\protobuf\" >nul
copy "..\godobuf\addons\protobuf\*.cfg" "addons\protobuf\" >nul
copy "..\godobuf\addons\protobuf\*.tscn" "addons\protobuf\" >nul

echo 插件文件复制完成！
echo.
echo 现在可以使用命令生成 protobuf 文件:
echo ..\godot.exe --headless -s addons/protobuf/protobuf_cmdln.gd --input=..\jigger_protobuf\proto\game.proto --output=game_proto.gd
echo.
pause