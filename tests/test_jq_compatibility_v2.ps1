# Improved compatibility test between moonjq and jq
# Uses proper escaping and direct command execution

Write-Host "`n=== MoonJQ vs JQ Compatibility Test V2 ===" -ForegroundColor Cyan

$moonjq = ".\target\native\release\build\src\src.exe"
$testCount = 0
$passCount = 0
$failCount = 0
$formatDiffCount = 0  # Count differences only due to formatting

function Test-Compatibility {
    param(
        [string]$Name,
        [string]$JsonFile,
        [string]$Query,
        [string]$Category = "General"
    )
    
    $script:testCount++
    Write-Host "`n[$Category] Test $testCount : $Name" -ForegroundColor Yellow
    Write-Host "  Query: $Query" -ForegroundColor Gray
    
    try {
        # Run with jq
        $jqResult = Get-Content $JsonFile | jq $Query 2>&1 | Out-String
        $jqResult = $jqResult.Trim()
        
        # Run with moonjq
        $moonjqCmd = "jq '$Query' $JsonFile"
        $moonjqResult = $moonjqCmd | & $moonjq 2>&1 | Select-String -Pattern "jq>" -NotMatch | Select-String -Pattern "moonjq" -NotMatch | Select-String -Pattern "Type jq" -NotMatch | Select-String -Pattern "Ctrl" -NotMatch | Out-String
        $moonjqResult = $moonjqResult.Trim()
        
        # Normalize whitespace for comparison
        $jqNormalized = ($jqResult -replace '\s+', ' ').Trim()
        $moonjqNormalized = ($moonjqResult -replace '\s+', ' ').Trim()
        
        if ($jqResult -eq $moonjqResult) {
            Write-Host "  PASS (exact match)" -ForegroundColor Green
            $script:passCount++
        } elseif ($jqNormalized -eq $moonjqNormalized) {
            Write-Host "  PASS (format diff only)" -ForegroundColor Cyan
            $script:passCount++
            $script:formatDiffCount++
        } else {
            Write-Host "  FAIL" -ForegroundColor Red
            Write-Host "  jq:     $jqResult" -ForegroundColor Magenta
            Write-Host "  moonjq: $moonjqResult" -ForegroundColor Yellow
            $script:failCount++
        }
    } catch {
        Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
        $script:failCount++
    }
}

# Create test JSON files
$testDir = "tests\temp_test_data"
New-Item -ItemType Directory -Force -Path $testDir | Out-Null

# Test data files
@{
    "simple_obj.json" = '{"a":1}'
    "person.json" = '{"name":"John","age":30}'
    "nested.json" = '{"user":{"name":"Alice"}}'
    "array.json" = '[1,2,3,4,5]'
    "mixed_obj.json" = '{"x":1,"y":2}'
    "items.json" = '[{"a":1},{"b":2},{"a":3}]'
    "keys_obj.json" = '{"b":2,"a":1,"c":3}'
    "deep_nested.json" = '{"a":{"b":{"c":5}}}'
    "null.json" = 'null'
    "empty_array.json" = '[]'
    "empty_obj.json" = '{}'
}.GetEnumerator() | ForEach-Object {
    # Use UTF8 without BOM
    [System.IO.File]::WriteAllText("$testDir\$($_.Key)", $_.Value, (New-Object System.Text.UTF8Encoding $false))
}

Write-Host "`n=== Basic Operations ===" -ForegroundColor Cyan
Test-Compatibility "Identity" "$testDir\simple_obj.json" "." "Basic"
Test-Compatibility "Field access" "$testDir\person.json" ".name" "Basic"
Test-Compatibility "Nested field" "$testDir\nested.json" ".user.name" "Basic"
Test-Compatibility "Array index" "$testDir\array.json" ".[2]" "Basic"
Test-Compatibility "Negative index" "$testDir\array.json" ".[-1]" "Basic"
Test-Compatibility "Iterator" "$testDir\array.json" ".[]" "Basic"

Write-Host "`n=== Slicing ===" -ForegroundColor Cyan
Test-Compatibility "Basic slice" "$testDir\array.json" ".[1:3]" "Slice"
Test-Compatibility "Open end slice" "$testDir\array.json" ".[2:]" "Slice"
Test-Compatibility "Open start slice" "$testDir\array.json" ".[:3]" "Slice"
Test-Compatibility "Negative slice" "$testDir\array.json" ".[-2:]" "Slice"

Write-Host "`n=== Arithmetic ===" -ForegroundColor Cyan
Test-Compatibility "Addition" "$testDir\null.json" "1 + 2" "Arithmetic"
Test-Compatibility "Subtraction" "$testDir\null.json" "10 - 3" "Arithmetic"
Test-Compatibility "Multiplication" "$testDir\null.json" "4 * 5" "Arithmetic"
Test-Compatibility "Precedence" "$testDir\null.json" "2 + 3 * 4" "Arithmetic"
Test-Compatibility "Parentheses" "$testDir\null.json" "(2 + 3) * 4" "Arithmetic"
Test-Compatibility "Negative number" "$testDir\null.json" "-5 + 3" "Arithmetic"

Write-Host "`n=== Comparison ===" -ForegroundColor Cyan
Test-Compatibility "Equal" "$testDir\null.json" "5 == 5" "Compare"
Test-Compatibility "Not equal" "$testDir\null.json" "5 != 3" "Compare"
Test-Compatibility "Greater than" "$testDir\null.json" "5 > 3" "Compare"
Test-Compatibility "Less than" "$testDir\null.json" "3 < 5" "Compare"

Write-Host "`n=== Built-in Functions ===" -ForegroundColor Cyan
Test-Compatibility "Length of array" "$testDir\array.json" "length" "Function"
Test-Compatibility "Keys of object" "$testDir\keys_obj.json" "keys" "Function"
Test-Compatibility "Type null" "$testDir\null.json" "type" "Function"
Test-Compatibility "Type array" "$testDir\array.json" "type" "Function"

Write-Host "`n=== has() Function ===" -ForegroundColor Cyan
Test-Compatibility "Has existing key" "$testDir\person.json" 'has(\"name\")' "has"
Test-Compatibility "Has missing key" "$testDir\person.json" 'has(\"email\")' "has"
Test-Compatibility "Has array index" "$testDir\array.json" "has(1)" "has"
Test-Compatibility "Has negative index" "$testDir\array.json" "has(-1)" "has"

Write-Host "`n=== in() Function ===" -ForegroundColor Cyan
[System.IO.File]::WriteAllText("$testDir\two.json", '2', (New-Object System.Text.UTF8Encoding $false))
Test-Compatibility "Value in array" "$testDir\two.json" "in([1,2,3])" "in"
[System.IO.File]::WriteAllText("$testDir\five.json", '5', (New-Object System.Text.UTF8Encoding $false))
Test-Compatibility "Value not in array" "$testDir\five.json" "in([1,2,3])" "in"

Write-Host "`n=== Pipe Operations ===" -ForegroundColor Cyan
Test-Compatibility "Simple pipe" "$testDir\array.json" ".[] | . * 2" "Pipe"
Test-Compatibility "Multi-stage pipe" "$testDir\deep_nested.json" ".a | .b | .c" "Pipe"

Write-Host "`n=== Constructors ===" -ForegroundColor Cyan
Test-Compatibility "Array constructor" "$testDir\mixed_obj.json" "[.x, .y]" "Constructor"
Test-Compatibility "Object constructor" "$testDir\mixed_obj.json" "{a:.x, b:.y}" "Constructor"

Write-Host "`n=== Edge Cases ===" -ForegroundColor Cyan
Test-Compatibility "Empty object" "$testDir\empty_obj.json" "." "Edge"
Test-Compatibility "Empty array" "$testDir\empty_array.json" "." "Edge"
Test-Compatibility "Null" "$testDir\null.json" "." "Edge"

# Cleanup
Remove-Item -Recurse -Force $testDir

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Total Tests: $testCount" -ForegroundColor White
Write-Host "Passed: $passCount (Format diffs: $formatDiffCount)" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor Red

$percentage = [math]::Round(($passCount / $testCount) * 100, 2)
Write-Host "Success Rate: $percentage%" -ForegroundColor $(if ($percentage -eq 100) { "Green" } elseif ($percentage -ge 90) { "Yellow" } else { "Red" })

if ($failCount -eq 0) {
    Write-Host "`nAll compatibility tests passed!" -ForegroundColor Green
    if ($formatDiffCount -gt 0) {
        Write-Host "Note: $formatDiffCount tests have formatting differences (pretty-print vs compact)" -ForegroundColor Cyan
    }
} else {
    Write-Host "`nSome tests failed. Review failures above." -ForegroundColor Red
}
