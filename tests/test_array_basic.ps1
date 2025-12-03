# 测试数组操作函数

Write-Host "Testing map..." -ForegroundColor Cyan
echo '[1,2,3]' | moon run src 'map(. * 2)'

Write-Host "`nTesting add (numbers)..." -ForegroundColor Cyan
echo '[1,2,3]' | moon run src 'add'

Write-Host "`nTesting add (strings)..." -ForegroundColor Cyan
echo '["a","b","c"]' | moon run src 'add'

Write-Host "`nTesting min..." -ForegroundColor Cyan
echo '[3,1,4,1,5]' | moon run src 'min'

Write-Host "`nTesting max..." -ForegroundColor Cyan
echo '[3,1,4,1,5]' | moon run src 'max'

Write-Host "`nTesting sort..." -ForegroundColor Cyan
echo '[3,1,4,1,5]' | moon run src 'sort'

Write-Host "`nTesting unique..." -ForegroundColor Cyan
echo '[1,2,1,3,2]' | moon run src 'unique'

Write-Host "`nTesting sort_by..." -ForegroundColor Cyan
echo '[{"x":2},{"x":1},{"x":3}]' | moon run src 'sort_by(.x)'

Write-Host "`nTesting group_by..." -ForegroundColor Cyan
echo '[{"x":1,"y":"a"},{"x":2,"y":"b"},{"x":1,"y":"c"}]' | moon run src 'group_by(.x)'

Write-Host "`nTesting unique_by..." -ForegroundColor Cyan
echo '[{"x":1,"y":"a"},{"x":2,"y":"b"},{"x":1,"y":"c"}]' | moon run src 'unique_by(.x)'

Write-Host "`nTesting map with pipe..." -ForegroundColor Cyan
echo '[1,2,3]' | moon run src 'map(. * 2) | add'
