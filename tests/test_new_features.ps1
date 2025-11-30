# Test new features: negative numbers, parentheses, type function

Write-Host "`n=== Testing New Features ===" -ForegroundColor Cyan

$exe = ".\target\native\release\build\src\src.exe"
$testCount = 0
$passCount = 0

function Test-Feature {
    param(
        [string]$Name,
        [string]$Json,
        [string]$Query,
        [string]$Expected
    )
    
    $script:testCount++
    Write-Host "`nTest $testCount : $Name" -ForegroundColor Yellow
    Write-Host "  Input: $Json" -ForegroundColor Gray
    Write-Host "  Query: $Query" -ForegroundColor Gray
    Write-Host "  Expected: $Expected" -ForegroundColor Gray
    
    try {
        # Create input for REPL
        $input = "echo '$Json' | jq '$Query'"
        $result = $input | & $exe 2>&1 | Select-String -Pattern "jq>" -NotMatch | Select-String -Pattern "moonjq" -NotMatch | Select-String -Pattern "Type jq" -NotMatch | Select-String -Pattern "Ctrl" -NotMatch | Out-String
        $result = $result.Trim()
        
        if ($result -eq $Expected) {
            Write-Host "  PASS" -ForegroundColor Green
            $script:passCount++
        } else {
            Write-Host "  FAIL - Got: $result" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== 1. Negative Number Literals ===" -ForegroundColor Cyan

Test-Feature "Simple negative" "null" "-5" "-5"
Test-Feature "Negative addition" "null" "-5 + 3" "-2"
Test-Feature "Negative subtraction" "null" "-10 - 5" "-15"
Test-Feature "Negative multiplication" "null" "-3 * 4" "-12"
Test-Feature "Double negative" "null" "0 - (-5)" "5"

Write-Host "`n=== 2. Parentheses Expressions ===" -ForegroundColor Cyan

Test-Feature "Simple parens" "null" "(2 + 3) * 4" "20"
Test-Feature "Nested parens" "null" "((2 + 3) * 4) - 10" "10"
Test-Feature "Precedence override" "null" "2 * (3 + 4)" "14"
Test-Feature "Complex expression" "null" "(10 - 2) / (3 + 1)" "2"

Write-Host "`n=== 3. Type Function ===" -ForegroundColor Cyan

Test-Feature "Null type" "null" "null | type" '"null"'
Test-Feature "Boolean type" "true" "type" '"boolean"'
Test-Feature "Number type" "42" "type" '"number"'
Test-Feature "String type" '{"name":"test"}' ".name | type" '"string"'
Test-Feature "Array type" "[1,2,3]" "type" '"array"'
Test-Feature "Object type" '{"a":1}' "type" '"object"'

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Passed: $passCount / $testCount" -ForegroundColor $(if ($passCount -eq $testCount) { "Green" } else { "Yellow" })
