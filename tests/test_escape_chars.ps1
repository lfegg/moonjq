# Test escape character handling in command parser

Write-Host "`n=== Testing Escape Character Handling ===" -ForegroundColor Cyan

$exe = ".\target\native\release\build\src\src.exe"
$testCount = 0
$passCount = 0

function Test-Escape {
    param(
        [string]$Name,
        [string]$Command,
        [string]$Expected
    )
    
    $script:testCount++
    Write-Host "`nTest $testCount : $Name" -ForegroundColor Yellow
    Write-Host "  Command: $Command" -ForegroundColor Gray
    Write-Host "  Expected: $Expected" -ForegroundColor Gray
    
    try {
        $result = $Command | & $exe 2>&1 | Select-String -Pattern "jq>" -NotMatch | Select-String -Pattern "moonjq" -NotMatch | Select-String -Pattern "Type jq" -NotMatch | Select-String -Pattern "Ctrl" -NotMatch | Out-String
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

Write-Host "`n=== 1. Escaped Quotes in JSON ===" -ForegroundColor Cyan

Test-Escape "Escaped double quotes in object" 'echo ''{\"name\":\"John\",\"age\":30}'' | jq ''.name''' '"John"'
Test-Escape "Escaped quotes with has" 'echo ''{\"a\":1,\"b\":2}'' | jq ''has(\"a\")''' "true"
Test-Escape "Escaped quotes in array" 'echo ''[{\"x\":1},{\"y\":2}]'' | jq ''.[0].x''' "1"

Write-Host "`n=== 2. Mixed Quotes ===" -ForegroundColor Cyan

Test-Escape "Single quotes for JSON, double for query" 'echo ''{"name":"test"}'' | jq ".name"' '"test"'
Test-Escape "Complex nested structure" 'echo ''{\"user\":{\"name\":\"Alice\"}}'' | jq ''.user.name''' '"Alice"'

Write-Host "`n=== 3. Special Characters ===" -ForegroundColor Cyan

Test-Escape "String with spaces" 'echo ''{\"text\":\"hello world\"}'' | jq ''.text''' '"hello world"'
Test-Escape "Empty object" 'echo ''{}'' | jq ''.''' "{}"
Test-Escape "Empty array" 'echo ''[]'' | jq ''.''' "[]"

Write-Host "`n=== 4. Complex Queries with Escapes ===" -ForegroundColor Cyan

Test-Escape "Filter with escaped quotes" 'echo ''[{\"a\":1},{\"b\":2}]'' | jq ''.[] | select(has(\"a\")) | .a''' "1"
Test-Escape "Type check with escapes" 'echo ''{\"name\":\"test\"}'' | jq ''.name | type''' '"string"'
Test-Escape "Length with escapes" 'echo ''[1,2,3,4,5]'' | jq ''length''' "5"

Write-Host "`n=== 5. Edge Cases ===" -ForegroundColor Cyan

Test-Escape "Null value" 'echo ''null'' | jq ''.''' "null"
Test-Escape "Boolean true" 'echo ''true'' | jq ''.''' "true"
Test-Escape "Boolean false" 'echo ''false'' | jq ''.''' "false"
Test-Escape "Number" 'echo ''42'' | jq ''.''' "42"

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Passed: $passCount / $testCount" -ForegroundColor $(if ($passCount -eq $testCount) { "Green" } else { "Yellow" })

if ($passCount -eq $testCount) {
    Write-Host "`nAll escape character tests passed!" -ForegroundColor Green
} else {
    Write-Host "`nSome tests failed." -ForegroundColor Red
}
