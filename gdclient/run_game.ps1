# GodoRoom 游戏启动脚本 (PowerShell)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "      启动 GodoRoom 游戏客户端" -ForegroundColor Cyan  
Write-Host "========================================" -ForegroundColor Cyan
Write-Host

# 检查 Godot 可执行文件
$godotPath = "..\godot.exe"
if (-not (Test-Path $godotPath)) {
    Write-Host "错误：找不到 godot.exe" -ForegroundColor Red
    Write-Host "当前查找路径：$godotPath" -ForegroundColor Yellow
    Read-Host "按 Enter 键退出"
    exit 1
}

Write-Host "正在启动游戏..." -ForegroundColor Green
Write-Host "提示：关闭游戏窗口或按 Ctrl+C 停止运行" -ForegroundColor Yellow
Write-Host

try {
    # 直接运行项目（不打开编辑器）
    & $godotPath "project.godot"
}
catch {
    Write-Host "启动失败：$($_.Exception.Message)" -ForegroundColor Red
}

Write-Host
Write-Host "游戏已退出" -ForegroundColor Green
Read-Host "按 Enter 键退出"