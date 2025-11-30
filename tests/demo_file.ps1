#!/usr/bin/env pwsh
# 文件读取示例

Write-Host "`n=== 文件读取示例 ===`n" -ForegroundColor Green

if (-not (Test-Path "test.json")) {
    Write-Host "错误: 找不到 test.json 文件" -ForegroundColor Red
    exit 1
}

Write-Host "示例 1: 读取字段" -ForegroundColor Cyan
Write-Host "命令: jq '.user.name' test.json" -ForegroundColor Gray
"jq '.user.name' test.json`nexit" | .\target\native\release\build\src\src.exe

Write-Host "`n示例 2: 读取数组" -ForegroundColor Cyan
Write-Host "命令: jq '.user.skills' test.json" -ForegroundColor Gray
"jq '.user.skills' test.json`nexit" | .\target\native\release\build\src\src.exe

Write-Host "`n示例 3: 复杂查询" -ForegroundColor Cyan
Write-Host "命令: jq '.projects | .[] | select(.stars > 100)' test.json" -ForegroundColor Gray
"jq '.projects | .[] | select(.stars > 100)' test.json`nexit" | .\target\native\release\build\src\src.exe
