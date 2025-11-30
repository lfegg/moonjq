# 数组操作功能验证测试
Write-Host "=== Array Operations Comparison Test ===" -ForegroundColor Cyan

function Test-ArrayOp {
    param($data, $query, $description)
    
    Write-Host "`n$description" -ForegroundColor Yellow
    Write-Host "Query: $query" -ForegroundColor Gray
    Write-Host "Data: $data" -ForegroundColor Gray
    
    # Test with jq
    $jqResult = Write-Output $data | jq $query 2>$null
    Write-Host "jq:     $jqResult" -ForegroundColor Green
    
    Write-Host "moonjq: (REPL mode - manual test needed)" -ForegroundColor Magenta
}

# 1. map
Test-ArrayOp '[1,2,3]' 'map(. * 2)' "1. map - Apply expression to each element"

# 2. add - numbers
Test-ArrayOp '[1,2,3]' 'add' "2. add - Sum numbers"

# 3. add - strings  
Test-ArrayOp '["a","b","c"]' 'add' "3. add - Concatenate strings"

# 4. add - arrays
Test-ArrayOp '[[1,2],[3,4]]' 'add' "4. add - Concatenate arrays"

# 5. min
Test-ArrayOp '[3,1,4,1,5]' 'min' "5. min - Find minimum"

# 6. max
Test-ArrayOp '[3,1,4,1,5]' 'max' "6. max - Find maximum"

# 7. sort
Test-ArrayOp '[3,1,4,1,5]' 'sort' "7. sort - Sort array"

# 8. sort_by
Test-ArrayOp '[{"x":2},{"x":1},{"x":3}]' 'sort_by(.x)' "8. sort_by - Sort by field"

# 9. unique
Test-ArrayOp '[1,2,1,3,2]' 'unique' "9. unique - Remove duplicates"

# 10. group_by
Test-ArrayOp '[{"x":1,"y":"a"},{"x":2,"y":"b"},{"x":1,"y":"c"}]' 'group_by(.x)' "10. group_by - Group by field"

# 11. unique_by
Test-ArrayOp '[{"x":1,"y":"a"},{"x":2,"y":"b"},{"x":1,"y":"c"}]' 'unique_by(.x)' "11. unique_by - Unique by field"

# 12. Combined
Test-ArrayOp '[1,2,3]' 'map(. * 2) | add' "12. map + add - Combined operations"

Write-Host "`n=== Expected outputs shown above ===" -ForegroundColor Cyan
Write-Host "Now test manually in moonjq REPL mode" -ForegroundColor Cyan
