# Comprehensive comparison test between moonjq and jq
# This script tests various features to ensure output compatibility

Write-Host "`n=== MoonJQ vs JQ Compatibility Test ===" -ForegroundColor Cyan

$moonjq = ".\target\native\release\build\src\src.exe"
$testCount = 0
$passCount = 0
$failCount = 0

function Test-Compatibility {
    param(
        [string]$Name,
        [string]$Json,
        [string]$Query,
        [string]$Category = "General"
    )
    
    $script:testCount++
    Write-Host "`n[$Category] Test $testCount : $Name" -ForegroundColor Yellow
    Write-Host "  JSON: $Json" -ForegroundColor Gray
    Write-Host "  Query: $Query" -ForegroundColor Gray
    
    try {
        # Run with jq
        $jqCmd = "echo '$Json' | jq '$Query'"
        $jqResult = Invoke-Expression $jqCmd 2>&1 | Out-String
        $jqResult = $jqResult.Trim()
        
        # Run with moonjq
        $moonjqCmd = "echo '$Json' | jq '$Query'"
        $moonjqResult = $moonjqCmd | & $moonjq 2>&1 | Select-String -Pattern "jq>" -NotMatch | Select-String -Pattern "moonjq" -NotMatch | Select-String -Pattern "Type jq" -NotMatch | Select-String -Pattern "Ctrl" -NotMatch | Out-String
        $moonjqResult = $moonjqResult.Trim()
        
        if ($jqResult -eq $moonjqResult) {
            Write-Host "  PASS" -ForegroundColor Green
            $script:passCount++
        } else {
            Write-Host "  FAIL" -ForegroundColor Red
            Write-Host "  jq output:     $jqResult" -ForegroundColor Magenta
            Write-Host "  moonjq output: $moonjqResult" -ForegroundColor Cyan
            $script:failCount++
        }
    } catch {
        Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
        $script:failCount++
    }
}

Write-Host "`n=== Basic Operations ===" -ForegroundColor Cyan

Test-Compatibility "Identity" '{"a":1}' '.' "Basic"
Test-Compatibility "Field access" '{"name":"John","age":30}' '.name' "Basic"
Test-Compatibility "Nested field" '{"user":{"name":"Alice"}}' '.user.name' "Basic"
Test-Compatibility "Array index" '[1,2,3,4,5]' '.[2]' "Basic"
Test-Compatibility "Negative index" '[1,2,3,4,5]' '.[-1]' "Basic"
Test-Compatibility "Iterator" '[1,2,3]' '.[]' "Basic"

Write-Host "`n=== Slicing ===" -ForegroundColor Cyan

Test-Compatibility "Basic slice" '[0,1,2,3,4]' '.[1:3]' "Slice"
Test-Compatibility "Open end slice" '[1,2,3,4,5]' '.[2:]' "Slice"
Test-Compatibility "Open start slice" '[1,2,3,4,5]' '.[:3]' "Slice"
Test-Compatibility "Negative slice" '[1,2,3,4,5]' '.[-2:]' "Slice"
Test-Compatibility "String slice" '"hello world"' '.[0:5]' "Slice"

Write-Host "`n=== Arithmetic ===" -ForegroundColor Cyan

Test-Compatibility "Addition" 'null' '1 + 2' "Arithmetic"
Test-Compatibility "Subtraction" 'null' '10 - 3' "Arithmetic"
Test-Compatibility "Multiplication" 'null' '4 * 5' "Arithmetic"
Test-Compatibility "Division" 'null' '20 / 4' "Arithmetic"
Test-Compatibility "Modulo" 'null' '10 % 3' "Arithmetic"
Test-Compatibility "Precedence" 'null' '2 + 3 * 4' "Arithmetic"
Test-Compatibility "Parentheses" 'null' '(2 + 3) * 4' "Arithmetic"
Test-Compatibility "Negative number" 'null' '-5 + 3' "Arithmetic"
Test-Compatibility "Float division" 'null' '7 / 2' "Arithmetic"

Write-Host "`n=== String Operations ===" -ForegroundColor Cyan

Test-Compatibility "String concat" 'null' '"hello" + " " + "world"' "String"
Test-Compatibility "String multiply" 'null' '"x" * 3' "String"

Write-Host "`n=== Array Operations ===" -ForegroundColor Cyan

Test-Compatibility "Array concat" 'null' '[1,2] + [3,4]' "Array"
Test-Compatibility "Array subtract" 'null' '[1,2,3,4] - [2,4]' "Array"
Test-Compatibility "Array length" '[1,2,3,4,5]' 'length' "Array"

Write-Host "`n=== Comparison ===" -ForegroundColor Cyan

Test-Compatibility "Equal" 'null' '5 == 5' "Compare"
Test-Compatibility "Not equal" 'null' '5 != 3' "Compare"
Test-Compatibility "Greater than" 'null' '5 > 3' "Compare"
Test-Compatibility "Less than" 'null' '3 < 5' "Compare"
Test-Compatibility "Greater or equal" 'null' '5 >= 5' "Compare"
Test-Compatibility "Less or equal" 'null' '3 <= 5' "Compare"

Write-Host "`n=== Built-in Functions ===" -ForegroundColor Cyan

Test-Compatibility "Length of string" '"hello"' 'length' "Function"
Test-Compatibility "Length of array" '[1,2,3]' 'length' "Function"
Test-Compatibility "Length of object" '{"a":1,"b":2}' 'length' "Function"
Test-Compatibility "Keys of object" '{"b":2,"a":1,"c":3}' 'keys' "Function"
Test-Compatibility "Keys of array" '[10,20,30]' 'keys' "Function"
Test-Compatibility "Type null" 'null' 'type' "Function"
Test-Compatibility "Type boolean" 'true' 'type' "Function"
Test-Compatibility "Type number" '42' 'type' "Function"
Test-Compatibility "Type string" '"test"' 'type' "Function"
Test-Compatibility "Type array" '[1,2]' 'type' "Function"
Test-Compatibility "Type object" '{"a":1}' 'type' "Function"

Write-Host "`n=== has() Function ===" -ForegroundColor Cyan

Test-Compatibility "Has existing key" '{"name":"John","age":30}' 'has("name")' "has"
Test-Compatibility "Has missing key" '{"name":"John"}' 'has("email")' "has"
Test-Compatibility "Has array index" '[1,2,3]' 'has(1)' "has"
Test-Compatibility "Has missing index" '[1,2,3]' 'has(5)' "has"
Test-Compatibility "Has negative index" '[1,2,3]' 'has(-1)' "has"

Write-Host "`n=== in() Function ===" -ForegroundColor Cyan

Test-Compatibility "Value in array" '2' 'in([1,2,3])' "in"
Test-Compatibility "Value not in array" '5' 'in([1,2,3])' "in"
Test-Compatibility "String in array" '"b"' 'in(["a","b","c"])' "in"
Test-Compatibility "Null in array" 'null' 'in([1,null,3])' "in"

Write-Host "`n=== Pipe Operations ===" -ForegroundColor Cyan

Test-Compatibility "Simple pipe" '[1,2,3]' '.[] | . * 2' "Pipe"
Test-Compatibility "Multi-stage pipe" '{"a":{"b":{"c":5}}}' '.a | .b | .c' "Pipe"
Test-Compatibility "Pipe with select" '[1,2,3,4,5]' '.[] | select(. > 2)' "Pipe"

Write-Host "`n=== Select ===" -ForegroundColor Cyan

Test-Compatibility "Select greater" '[1,2,3,4,5]' '.[] | select(. > 3)' "Select"
Test-Compatibility "Select with has" '[{"a":1},{"b":2},{"a":3}]' '.[] | select(has("a"))' "Select"
Test-Compatibility "Select equal" '[1,2,3,2,1]' '.[] | select(. == 2)' "Select"

Write-Host "`n=== Constructors ===" -ForegroundColor Cyan

Test-Compatibility "Array constructor" '{"a":1,"b":2}' '[.a, .b]' "Constructor"
Test-Compatibility "Object constructor" '{"x":1,"y":2}' '{a:.x, b:.y}' "Constructor"

Write-Host "`n=== Edge Cases ===" -ForegroundColor Cyan

Test-Compatibility "Empty object" '{}' '.' "Edge"
Test-Compatibility "Empty array" '[]' '.' "Edge"
Test-Compatibility "Null" 'null' '.' "Edge"
Test-Compatibility "Boolean true" 'true' '.' "Edge"
Test-Compatibility "Boolean false" 'false' '.' "Edge"
Test-Compatibility "Zero" '0' '.' "Edge"
Test-Compatibility "Negative zero" '-0' '.' "Edge"
Test-Compatibility "Large number" '999999999999' '.' "Edge"
Test-Compatibility "Float" '3.14159' '.' "Edge"
Test-Compatibility "Scientific notation" '1e10' '.' "Edge"

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Total Tests: $testCount" -ForegroundColor White
Write-Host "Passed: $passCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor Red

$percentage = [math]::Round(($passCount / $testCount) * 100, 2)
Write-Host "Success Rate: $percentage%" -ForegroundColor $(if ($percentage -eq 100) { "Green" } elseif ($percentage -ge 90) { "Yellow" } else { "Red" })

if ($failCount -eq 0) {
    Write-Host "`nAll compatibility tests passed! moonjq is fully compatible with jq." -ForegroundColor Green
} else {
    Write-Host "`nSome compatibility issues found. Please review the failures above." -ForegroundColor Red
}
