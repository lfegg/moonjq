#!/usr/bin/env pwsh
# MoonJQ 功能测试套件

Write-Host "`n=== MoonJQ 测试套件 ===`n" -ForegroundColor Cyan

$passed = 0
$total = 0

Write-Host "1. Shell 命令风格测试" -ForegroundColor Yellow
Write-Host "   输入: echo '{`"x`":1}' | jq '.x'" -ForegroundColor Gray
"echo '{`"x`":1}' | jq '.x'`nexit" | .\target\native\release\build\src\src.exe | Select-String "1" -Quiet
if ($?) { Write-Host "   ✓ 通过`n" -ForegroundColor Green; $passed++ } else { Write-Host "   ✗ 失败`n" -ForegroundColor Red }
$total++

Write-Host "2. 文件读取测试" -ForegroundColor Yellow  
Write-Host "   输入: jq '.user.name' test.json" -ForegroundColor Gray
"jq '.user.name' test.json`nexit" | .\target\native\release\build\src\src.exe | Select-String "Tom" -Quiet
if ($?) { Write-Host "   ✓ 通过`n" -ForegroundColor Green; $passed++ } else { Write-Host "   ✗ 失败`n" -ForegroundColor Red }
$total++

Write-Host "3. 数组过滤测试" -ForegroundColor Yellow
Write-Host "   输入: echo '[1,2,3]' | jq '.[] | select(. > 1)'" -ForegroundColor Gray  
"echo '[1,2,3]' | jq '.[] | select(. > 1)'`nexit" | .\target\native\release\build\src\src.exe | Select-String "2" -Quiet
if ($?) { Write-Host "   ✓ 通过`n" -ForegroundColor Green; $passed++ } else { Write-Host "   ✗ 失败`n" -ForegroundColor Red }
$total++

Write-Host "==================" -ForegroundColor Cyan
Write-Host "结果: $passed/$total 通过" -ForegroundColor $(if ($passed -eq $total) { "Green" } else { "Yellow" })
Write-Host "==================`n" -ForegroundColor Cyan
