# 测试新添加的数组操作
Write-Host "=== Testing New Array Operations ===" -ForegroundColor Cyan

function Test-Operation {
    param(
        [string]$Name,
        [string]$Json,
        [string]$Query
    )
    
    Write-Host "`nTesting $Name" -ForegroundColor Yellow
    Write-Host "Query: $Query" -ForegroundColor Gray
    Write-Host "Input: $Json" -ForegroundColor Gray
    
    # Test with jq
    Write-Host "jq:      " -NoNewline -ForegroundColor Green
    $jqResult = $Json | jq $Query 2>&1
    Write-Host $jqResult
    
    # Test with moonjq (via file)
    $Json | Out-File -Encoding UTF8 temp_test.json
    Write-Host "moonjq:  " -NoNewline -ForegroundColor Green
    Write-Host "jq '$Query' temp_test.json" | Out-File -Encoding UTF8 moonjq_input.txt
    $moonjqResult = Get-Content moonjq_input.txt | moon run src 2>&1 | Select-Object -Skip 7 | Where-Object { $_ -notmatch "^\s*$" }
    Write-Host $moonjqResult
    
    # Compare
    if ($jqResult -eq $moonjqResult) {
        Write-Host "✓ MATCH" -ForegroundColor Green
    } else {
        Write-Host "✗ MISMATCH" -ForegroundColor Red
    }
}

# Test 1: contains
Test-Operation -Name "contains([2,3])" -Json '[1,2,3,4,5]' -Query 'contains([2,3])'

# Test 2: flatten
Test-Operation -Name "flatten" -Json '[[1,2],[3,4],[5,6]]' -Query 'flatten'

# Test 3: flatten with depth
Test-Operation -Name "flatten(1)" -Json '[[[1,2]],[[3,4]]]' -Query 'flatten(1)'

# Test 4: add
Test-Operation -Name "add" -Json '[1,2,3,4,5]' -Query 'add'

# Test 5: reverse
Test-Operation -Name "reverse" -Json '[1,2,3,4,5]' -Query 'reverse'

# Test 6: sort | reverse  
Test-Operation -Name "sort | reverse" -Json '[5,2,8,1,9]' -Query 'sort | reverse'

# Cleanup
Remove-Item temp_test.json -ErrorAction SilentlyContinue
Remove-Item moonjq_input.txt -ErrorAction SilentlyContinue

Write-Host "`n=== Testing Complete ===" -ForegroundColor Cyan
