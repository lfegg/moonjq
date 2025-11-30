# Test has() and in() functions

Write-Host "`n=== Testing has() and in() Functions ===" -ForegroundColor Cyan

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

Write-Host "`n=== 1. has() Function - Objects ===" -ForegroundColor Cyan

Test-Feature "Object has existing key" '{"name":"John","age":30}' 'has("name")' "true"
Test-Feature "Object missing key" '{"name":"John","age":30}' 'has("email")' "false"
Test-Feature "Object has nested check" '{"user":{"name":"John"}}' '.user | has("name")' "true"
Test-Feature "Empty object" '{}' 'has("key")' "false"

Write-Host "`n=== 2. has() Function - Arrays ===" -ForegroundColor Cyan

Test-Feature "Array has index 0" '[1,2,3]' 'has(0)' "true"
Test-Feature "Array has index 2" '[1,2,3]' 'has(2)' "true"
Test-Feature "Array missing index 5" '[1,2,3]' 'has(5)' "false"
Test-Feature "Array negative index" '[1,2,3]' 'has(-1)' "true"
Test-Feature "Array invalid negative index" '[1,2,3]' 'has(-10)' "false"
Test-Feature "Empty array" '[]' 'has(0)' "false"

Write-Host "`n=== 3. in() Function - Arrays ===" -ForegroundColor Cyan

Test-Feature "Value in array" '2' 'in([1,2,3])' "true"
Test-Feature "Value not in array" '5' 'in([1,2,3])' "false"
Test-Feature "String in array" '"b"' 'in(["a","b","c"])' "true"
Test-Feature "String not in array" '"d"' 'in(["a","b","c"])' "false"
Test-Feature "Null in array" 'null' 'in([1,null,3])' "true"
Test-Feature "Boolean in array" 'true' 'in([false,true])' "true"

Write-Host "`n=== 4. Combined Usage ===" -ForegroundColor Cyan

Test-Feature "Filter with has first" '[{"a":1},{"b":2}]' '.[] | select(has("a")) | .a' "1"
Test-Feature "Check multiple keys" '{"a":1,"b":2}' 'has("a")' "true"

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Passed: $passCount / $testCount" -ForegroundColor $(if ($passCount -eq $testCount) { "Green" } else { "Yellow" })
