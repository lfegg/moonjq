# 测试数组操作函数
Write-Host "=== Testing Array Operations ===" -ForegroundColor Green

# Test map
Write-Host "`n1. Testing map(. * 2):" -ForegroundColor Yellow
echo '[1,2,3]' | moon run src

# Test add - numbers
Write-Host "`n2. Testing add (numbers):" -ForegroundColor Yellow
echo '[1,2,3]' | moon run src

# Test add - strings
Write-Host "`n3. Testing add (strings):" -ForegroundColor Yellow
echo '["a","b","c"]' | moon run src

# Test min
Write-Host "`n4. Testing min:" -ForegroundColor Yellow
echo '[3,1,4,1,5]' | moon run src

# Test max
Write-Host "`n5. Testing max:" -ForegroundColor Yellow
echo '[3,1,4,1,5]' | moon run src

# Test sort
Write-Host "`n6. Testing sort:" -ForegroundColor Yellow
echo '[3,1,4,1,5]' | moon run src

# Test sort_by
Write-Host "`n7. Testing sort_by(.x):" -ForegroundColor Yellow
echo '[{"x":2},{"x":1},{"x":3}]' | moon run src

# Test unique
Write-Host "`n8. Testing unique:" -ForegroundColor Yellow
echo '[1,2,1,3,2]' | moon run src

# Test group_by
Write-Host "`n9. Testing group_by(.x):" -ForegroundColor Yellow
echo '[{"x":1,"y":"a"},{"x":2,"y":"b"},{"x":1,"y":"c"}]' | moon run src

# Test unique_by
Write-Host "`n10. Testing unique_by(.x):" -ForegroundColor Yellow
echo '[{"x":1,"y":"a"},{"x":2,"y":"b"},{"x":1,"y":"c"}]' | moon run src

# Test combined operations
Write-Host "`n11. Testing map(. * 2) | add:" -ForegroundColor Yellow
echo '[1,2,3]' | moon run src

Write-Host "`n=== All tests completed ===" -ForegroundColor Green
