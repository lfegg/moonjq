#!/usr/bin/env pwsh
# 启动 MoonJQ REPL

Write-Host "MoonJQ - Interactive JSON Processor" -ForegroundColor Cyan
Write-Host ""

# 检查是否需要构建
$exe = ".\target\native\release\build\src\src.exe"
if (-not (Test-Path $exe)) {
    Write-Host "首次运行，正在构建..." -ForegroundColor Yellow
    moon build --target native
    if ($LASTEXITCODE -ne 0) {
        Write-Host "构建失败!" -ForegroundColor Red
        exit 1
    }
}

Write-Host "启动 REPL..." -ForegroundColor Green
Write-Host ""
Write-Host "提示:" -ForegroundColor Yellow
Write-Host "  • Shell 风格: echo '{...}' | jq '.query'" -ForegroundColor Gray
Write-Host "  • 文件读取:   jq '.query' filename.json" -ForegroundColor Gray
Write-Host "  • 退出:       exit 或 exit()" -ForegroundColor Gray
Write-Host ""

& $exe
