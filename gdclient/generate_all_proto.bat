@echo off
echo GodoRoom Protobuf Batch Generator
echo ========================================

REM Create output directory
if not exist "proto" mkdir proto

REM Copy godobuf plugin files if not exists
if not exist "addons\protobuf\parser.gd" (
    echo Copying godobuf plugin files...
    copy "..\godobuf\addons\protobuf\*.gd" "addons\protobuf\" > nul
    echo Plugin files copied
)

echo.
echo Starting batch protobuf generation...
echo.


REM Generate desktop_pet.proto
echo  Generating desktop_pet_proto.gd...
"..\godot.exe" --headless -s addons/protobuf/protobuf_cmdln.gd --input=.\desktop_pet.proto --output=proto\game_proto.gd



echo.
echo ========================================
echo Batch generation completed!
echo ========================================
echo.

echo Generated files:
dir /b proto\*.gd

echo.
echo Usage:
echo 1. Load in project: const GameProto = preload("res://proto/game_proto.gd")
echo 2. Create message: var msg = GameProto.AuthRequest.new()  
echo 3. Set field: msg.set_token("guest_token")
echo 4. Serialize: var bytes = msg.to_bytes()
echo.

pause