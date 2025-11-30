# Comprehensive Bug Testing Script

Write-Host "`n=== MoonJQ Bug Testing ===" -ForegroundColor Cyan
Write-Host "Testing various edge cases and potential bugs...`n" -ForegroundColor Yellow

moon build --target native | Out-Null

$exe = ".\target\native\release\build\src\src.exe"
$passCount = 0
$failCount = 0
$bugCount = 0

function Test-JQ {
    param(
        [string]$Name,
        [string]$Command,
        [string]$Expected,
        [string]$Category = "General"
    )
    
    Write-Host "[$Category] $Name" -ForegroundColor White
    Write-Host "  CMD: $Command" -ForegroundColor Gray
    
    try {
        $result = $Command | & $exe 2>&1 | Select-String -Pattern "jq>" -NotMatch | Out-String
        $result = $result.Trim()
        
        if ($result -like "*$Expected*" -or $Expected -eq "ANY") {
            Write-Host "  OK PASS" -ForegroundColor Green
            $script:passCount++
        } else {
            Write-Host "  X FAIL - Got: $result" -ForegroundColor Red
            $script:failCount++
        }
    } catch {
        Write-Host "  X ERROR: $($_.Exception.Message)" -ForegroundColor Red
        $script:failCount++
    }
    Write-Host ""
}

function Test-Bug {
    param(
        [string]$Name,
        [string]$Command,
        [string]$Issue
    )
    
    Write-Host "[BUG] $Name" -ForegroundColor Yellow
    Write-Host "  CMD: $Command" -ForegroundColor Gray
    Write-Host "  Issue: $Issue" -ForegroundColor Red
    
    try {
        $result = $Command | & $exe 2>&1 | Select-String -Pattern "jq>" -NotMatch | Out-String
        Write-Host "  Result: $($result.Trim())" -ForegroundColor Cyan
    } catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    $script:bugCount++
    Write-Host ""
}

Write-Host "=== Arithmetic Operations ===" -ForegroundColor Cyan

Test-JQ "Basic addition" "echo 'null' | jq '1 + 2'" "3" "Arithmetic"
Test-JQ "Basic subtraction" "echo 'null' | jq '10 - 3'" "7" "Arithmetic"
Test-JQ "Basic multiplication" "echo 'null' | jq '4 * 5'" "20" "Arithmetic"
Test-JQ "Basic division" "echo 'null' | jq '20 / 4'" "5" "Arithmetic"
Test-JQ "Modulo operation" "echo 'null' | jq '10 % 3'" "1" "Arithmetic"
Test-JQ "Operator precedence" "echo 'null' | jq '2 + 3 * 4'" "14" "Arithmetic"
Test-JQ "Multiple operations" "echo 'null' | jq '1 + 2 + 3 + 4'" "10" "Arithmetic"
Test-JQ "Division by zero" "echo 'null' | jq '10 / 0'" "null" "Arithmetic"
Test-JQ "Floating point" "echo 'null' | jq '3.5 + 2.5'" "6" "Arithmetic"

Write-Host "=== String Operations ===" -ForegroundColor Cyan

Test-JQ "String concatenation" 'echo ''null'' | jq ''"a" + "b"''' "ab" "String"
Test-JQ "String repeat" 'echo ''null'' | jq ''"x" * 3''' "xxx" "String"
Test-JQ "Empty string concat" 'echo ''null'' | jq ''"" + "test"''' "test" "String"

Write-Host "=== Array Operations ===" -ForegroundColor Cyan

Test-JQ "Array concat" "echo 'null' | jq '[1,2] + [3,4]'" "[1, 2, 3, 4]" "Array"
Test-JQ "Array difference" "echo 'null' | jq '[1,2,3,4] - [2,4]'" "[1, 3]" "Array"
Test-JQ "Empty array operations" "echo 'null' | jq '[] + [1]'" "[1]" "Array"
Test-JQ "Empty array diff" 'echo ''null'' | jq ''[] - [1]''' "ANY" "Array"

Write-Host "=== Field Operations ===" -ForegroundColor Cyan

Test-JQ "Field arithmetic" "jq '.age + 10' test_advanced.json" "40" "Field"
Test-JQ "Field multiplication" "jq '.age * 2' test_advanced.json" "60" "Field"

Write-Host "=== Slice Operations ===" -ForegroundColor Cyan

Test-JQ "Basic slice" "echo '[0,1,2,3,4,5]' | jq '.[1:4]'" "[1, 2, 3]" "Slice"
Test-JQ "Negative index slice" "echo '[0,1,2,3,4]' | jq '.[-2:]'" "[3, 4]" "Slice"
Test-JQ "Open end slice" "echo '[1,2,3,4,5]' | jq '.[2:]'" "[3, 4, 5]" "Slice"
Test-JQ "Open start slice" "echo '[1,2,3,4,5]' | jq '.[:3]'" "[1, 2, 3]" "Slice"
Test-JQ "Field with slice" "jq '.skills[1:]' test_advanced.json" "python" "Slice"

Write-Host "=== Complex Expressions ===" -ForegroundColor Cyan

Test-JQ "Pipe with arithmetic" "echo '[1,2,3]' | jq '.[] | . * 2'" "2" "Complex"
Test-JQ "Filter with arithmetic" "echo '[1,2,3,4,5]' | jq '.[] | select(. > 2) | . + 10'" "13" "Complex"
Test-JQ "Length with arithmetic" "jq '.skills | length * 2' test_advanced.json" "6" "Complex"

Write-Host "=== Type Function ===" -ForegroundColor Cyan

Test-JQ "Null type" "echo 'null' | jq 'null | type'" "null" "Type"
Test-JQ "Number type" "echo '42' | jq 'type'" "number" "Type"
Test-JQ "String type" 'echo ''"test"'' | jq ''type''' "string" "Type"
Test-JQ "Array type" "echo '[1,2,3]' | jq 'type'" "array" "Type"
Test-JQ "Boolean type" "echo 'true' | jq 'type'" "boolean" "Type"

Write-Host "=== Advanced Features ===" -ForegroundColor Cyan

Test-JQ "Negative numbers" "echo 'null' | jq '-5 + 3'" "-2" "Advanced"
Test-JQ "Parentheses override" "echo 'null' | jq '(2 + 3) * 4'" "20" "Advanced"
Test-JQ "Nested parentheses" "echo 'null' | jq '((10 - 2) / 4) + 1'" "3" "Advanced"

Write-Host "=== Edge Cases ===" -ForegroundColor Cyan

Test-JQ "Very large numbers" "echo 'null' | jq '999999999 + 1'" "ANY" "Edge"
Test-JQ "Very small division" "echo 'null' | jq '1 / 1000000'" "ANY" "Edge"
Test-JQ "Multiple divisions" "echo 'null' | jq '100 / 2 / 5'" "10" "Edge"
Test-JQ "Multiple modulo" "echo 'null' | jq '17 % 5 % 2'" "ANY" "Edge"

Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Passed: $passCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor Red
Write-Host "Known Bugs: $bugCount" -ForegroundColor Yellow
Write-Host ""

if ($failCount -eq 0) {
    Write-Host "All tests passed!" -ForegroundColor Green
} else {
    Write-Host "Some tests failed." -ForegroundColor Red
}
