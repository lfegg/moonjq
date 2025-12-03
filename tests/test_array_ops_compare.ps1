# 对比测试moonjq和jq的数组操作功能

function Test-ArrayOp {
    param(
        [string]$Name,
        [string]$Json,
        [string]$Query
    )
    
    Write-Host "`n=== $Name ===" -ForegroundColor Cyan
    Write-Host "JSON: $Json"
    Write-Host "Query: $Query"
    
    # 测试jq
    Write-Host "`njq output:" -ForegroundColor Yellow
    $jqResult = echo $Json | jq -c $Query 2>&1
    Write-Host $jqResult
    
    # 测试moonjq
    Write-Host "`nmoonjq would output:" -ForegroundColor Green  
    Write-Host "(Manually test in REPL mode)"
}

# Test map
Test-ArrayOp "map" '[1,2,3]' 'map(. * 2)'

# Test add
Test-ArrayOp "add (numbers)" '[1,2,3]' 'add'
Test-ArrayOp "add (strings)" '["a","b","c"]' 'add'

# Test min/max
Test-ArrayOp "min" '[3,1,4,1,5]' 'min'
Test-ArrayOp "max" '[3,1,4,1,5]' 'max'

# Test sort
Test-ArrayOp "sort" '[3,1,4,1,5]' 'sort'

# Test unique
Test-ArrayOp "unique" '[1,2,1,3,2]' 'unique'

# Test sort_by
Test-ArrayOp "sort_by" '[{"x":2},{"x":1},{"x":3}]' 'sort_by(.x)'

# Test group_by
Test-ArrayOp "group_by" '[{"x":1,"y":"a"},{"x":2,"y":"b"},{"x":1,"y":"c"}]' 'group_by(.x)'

# Test unique_by
Test-ArrayOp "unique_by" '[{"x":1,"y":"a"},{"x":2,"y":"b"},{"x":1,"y":"c"}]' 'unique_by(.x)'

# Test map with pipe
Test-ArrayOp "map+add" '[1,2,3]' 'map(. * 2) | add'

Write-Host "`n`n=== All tests completed ===" -ForegroundColor Green
Write-Host "Please verify moonjq manually in REPL mode"
