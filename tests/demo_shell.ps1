#!/usr/bin/env pwsh
# Shell 命令风格示例

Write-Host "`n=== Shell 命令风格示例 ===`n" -ForegroundColor Green

Write-Host "示例 1: 简单查询" -ForegroundColor Cyan
Write-Host "命令: echo '{`"name`":`"Alice`"}' | jq '.name'" -ForegroundColor Gray
"echo '{`"name`":`"Alice`"}' | jq '.name'`nexit" | .\target\native\release\build\src\src.exe

Write-Host "`n示例 2: 数组操作" -ForegroundColor Cyan  
Write-Host "命令: echo '[1,2,3,4,5]' | jq '.[]'" -ForegroundColor Gray
"echo '[1,2,3,4,5]' | jq '.[]'`nexit" | .\target\native\release\build\src\src.exe

Write-Host "`n示例 3: 过滤" -ForegroundColor Cyan
Write-Host "命令: echo '[1,2,3,4,5]' | jq '.[] | select(. > 2)'" -ForegroundColor Gray
"echo '[1,2,3,4,5]' | jq '.[] | select(. > 2)'`nexit" | .\target\native\release\build\src\src.exe
