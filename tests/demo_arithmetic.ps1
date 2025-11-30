# MoonJQ Arithmetic Operations Demo

Write-Host "`n=== MoonJQ Arithmetic Demo ===" -ForegroundColor Cyan

moon build --target native

$exe = ".\target\native\release\build\src\src.exe"

Write-Host "`n[Number Operations]" -ForegroundColor Green

Write-Host "`n1. Addition: 1 + 2" -ForegroundColor White
$result = "echo 'null' | jq '1 + 2'" | & $exe
Write-Host "   Result: $result" -ForegroundColor Cyan

Write-Host "`n2. Precedence: 2 + 3 * 4" -ForegroundColor White
$result = "echo 'null' | jq '2 + 3 * 4'" | & $exe
Write-Host "   Result: $result" -ForegroundColor Cyan

Write-Host "`n3. Division: 20 / 4" -ForegroundColor White
$result = "echo 'null' | jq '20 / 4'" | & $exe
Write-Host "   Result: $result" -ForegroundColor Cyan

Write-Host "`n4. Modulo: 10 % 3" -ForegroundColor White
$result = "echo 'null' | jq '10 % 3'" | & $exe
Write-Host "   Result: $result" -ForegroundColor Cyan

Write-Host "`n[Field Operations]" -ForegroundColor Green

Write-Host "`n5. Field addition: .age + 10" -ForegroundColor White
$result = "jq '.age + 10' test_advanced.json" | & $exe
Write-Host "   Result: $result" -ForegroundColor Cyan

Write-Host "`n[Array Operations]" -ForegroundColor Green

Write-Host "`n6. Array concatenation: [1, 2] + [3, 4]" -ForegroundColor White
$result = "echo 'null' | jq '[1, 2] + [3, 4]'" | & $exe
Write-Host "   Result: $result" -ForegroundColor Cyan

Write-Host "`n==================" -ForegroundColor Cyan
Write-Host "Demo Complete!" -ForegroundColor Green
Write-Host "==================`n" -ForegroundColor Cyan
