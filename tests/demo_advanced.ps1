#!/usr/bin/env pwsh
# 高级功能演示脚本

Write-Host "`n=== MoonJQ 高级功能演示 ===" -ForegroundColor Cyan

# 构建项目
Write-Host "`n构建项目..." -ForegroundColor Yellow
moon build --target native

$exe = ".\target\native\release\build\src\src.exe"

Write-Host "`n1. 切片操作 - 数组切片" -ForegroundColor Green
Write-Host "   输入: echo '[0,1,2,3,4,5]' | jq '.[1:4]'" -ForegroundColor Gray
$result = "echo '[0,1,2,3,4,5]' | jq '.[1:4]'" | & $exe
Write-Host "   输出: $result" -ForegroundColor White

Write-Host "`n2. 切片操作 - 负数索引" -ForegroundColor Green
Write-Host "   输入: echo '[0,1,2,3,4]' | jq '.[-2:]'" -ForegroundColor Gray
$result = "echo '[0,1,2,3,4]' | jq '.[-2:]'" | & $exe
Write-Host "   输出: $result" -ForegroundColor White

Write-Host "`n3. 切片操作 - 字符串切片" -ForegroundColor Green
Write-Host "   输入: echo '""hello world""' | jq '.[0:5]'" -ForegroundColor Gray
$result = "echo '""hello world""' | jq '.[0:5]'" | & $exe
Write-Host "   输出: $result" -ForegroundColor White

Write-Host "`n4. 递归下降 - 查找所有值" -ForegroundColor Green
Write-Host "   输入: echo '{""a"":{""b"":1},""c"":{""b"":2}}' | jq '..' | select -First 5" -ForegroundColor Gray
$result = "echo '{""a"":{""b"":1},""c"":{""b"":2}}' | jq '..' | select -First 5" | & $exe
Write-Host "   输出: $result" -ForegroundColor White

Write-Host "`n5. 递归下降 + 可选 - 查找所有 .b 字段" -ForegroundColor Green
Write-Host "   输入: echo '{""a"":{""b"":1},""c"":{""b"":2}}' | jq '.. | .b?'" -ForegroundColor Gray
$result = "echo '{""a"":{""b"":1},""c"":{""b"":2}}' | jq '.. | .b?'" | & $exe
Write-Host "   输出: $result" -ForegroundColor White

Write-Host "`n6. 可选操作符 - 不存在的字段" -ForegroundColor Green
Write-Host "   输入: echo '{""a"":1}' | jq '.b?'" -ForegroundColor Gray
$result = "echo '{""a"":1}' | jq '.b?'" | & $exe
Write-Host "   输出: $result (空输出表示成功)" -ForegroundColor White

Write-Host "`n7. 可选操作符 - 数组越界" -ForegroundColor Green
Write-Host "   输入: echo '[1,2,3]' | jq '.[10]?'" -ForegroundColor Gray
$result = "echo '[1,2,3]' | jq '.[10]?'" | & $exe
Write-Host "   输出: $result (空输出表示成功)" -ForegroundColor White

Write-Host "`n8. 切片 - 开放式结束" -ForegroundColor Green
Write-Host "   输入: echo '[1,2,3,4,5]' | jq '.[2:]'" -ForegroundColor Gray
$result = "echo '[1,2,3,4,5]' | jq '.[2:]'" | & $exe
Write-Host "   输出: $result" -ForegroundColor White

Write-Host "`n9. 切片 - 开放式开始" -ForegroundColor Green
Write-Host "   输入: echo '[1,2,3,4,5]' | jq '.[:3]'" -ForegroundColor Gray
$result = "echo '[1,2,3,4,5]' | jq '.[:3]'" | & $exe
Write-Host "   输出: $result" -ForegroundColor White

Write-Host "`n10. 组合使用 - 切片后过滤" -ForegroundColor Green
Write-Host "   输入: echo '[1,2,3,4,5,6,7,8,9]' | jq '.[2:7] | .[] | select(. > 4)'" -ForegroundColor Gray
$result = "echo '[1,2,3,4,5,6,7,8,9]' | jq '.[2:7] | .[] | select(. > 4)'" | & $exe
Write-Host "   输出: $result" -ForegroundColor White

Write-Host "`n==================" -ForegroundColor Cyan
Write-Host "演示完成!" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Cyan
Write-Host ""
