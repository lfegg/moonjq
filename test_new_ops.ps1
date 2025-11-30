# 测试新添加的数组操作函数

Write-Host "=== Testing New Array Operations ===" -ForegroundColor Cyan

# Test contains
Write-Host "`n1. Testing contains([2,3]):" -ForegroundColor Yellow
Write-Host "jq output:" -ForegroundColor Green
echo '[1,2,3,4,5]' | jq 'contains([2,3])'
Write-Host "moonjq output:" -ForegroundColor Green
echo 'echo ''[1,2,3,4,5]'' | jq ''contains([2,3])''' | Out-File -Encoding UTF8 test_cmd.txt

# Test flatten
Write-Host "`n2. Testing flatten:" -ForegroundColor Yellow
Write-Host "jq output:" -ForegroundColor Green
echo '[[1,2],[3,4],[5,6]]' | jq 'flatten'
Write-Host "moonjq output:" -ForegroundColor Green
echo 'echo ''[[1,2],[3,4],[5,6]]'' | jq ''flatten''' | Out-File -Encoding UTF8 test_cmd.txt

# Test flatten with depth
Write-Host "`n3. Testing flatten(1):" -ForegroundColor Yellow
Write-Host "jq output:" -ForegroundColor Green
echo '[[[1,2]],[[3,4]]]' | jq 'flatten(1)'
Write-Host "moonjq output:" -ForegroundColor Green
echo 'echo ''[[[1,2]],[[3,4]]]'' | jq ''flatten(1)''' | Out-File -Encoding UTF8 test_cmd.txt

# Test add
Write-Host "`n4. Testing add:" -ForegroundColor Yellow
Write-Host "jq output:" -ForegroundColor Green
echo '[1,2,3,4,5]' | jq 'add'
Write-Host "moonjq output:" -ForegroundColor Green
echo 'echo ''[1,2,3,4,5]'' | jq ''add''' | Out-File -Encoding UTF8 test_cmd.txt

# Test reverse
Write-Host "`n5. Testing sort | reverse:" -ForegroundColor Yellow
Write-Host "jq output:" -ForegroundColor Green
echo '[5,2,8,1,9]' | jq 'sort | reverse'
Write-Host "moonjq output:" -ForegroundColor Green
echo 'echo ''[5,2,8,1,9]'' | jq ''sort | reverse''' | Out-File -Encoding UTF8 test_cmd.txt

# Test reverse alone
Write-Host "`n6. Testing reverse:" -ForegroundColor Yellow
Write-Host "jq output:" -ForegroundColor Green
echo '[1,2,3,4,5]' | jq 'reverse'
Write-Host "moonjq output:" -ForegroundColor Green
echo 'echo ''[1,2,3,4,5]'' | jq ''reverse''' | Out-File -Encoding UTF8 test_cmd.txt

Write-Host "`n=== All expected outputs shown above ===" -ForegroundColor Cyan
Write-Host "Test these commands in moonjq REPL:" -ForegroundColor Cyan
Write-Host "  echo '[1,2,3,4,5]' | jq 'contains([2,3])'" -ForegroundColor Gray
Write-Host "  echo '[[1,2],[3,4],[5,6]]' | jq 'flatten'" -ForegroundColor Gray
Write-Host "  echo '[1,2,3,4,5]' | jq 'add'" -ForegroundColor Gray
Write-Host "  echo '[5,2,8,1,9]' | jq 'sort | reverse'" -ForegroundColor Gray
