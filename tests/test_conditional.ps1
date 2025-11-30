# Test conditional expressions compatibility with jq

Write-Host "`n=== Conditional Expression Tests ===" -ForegroundColor Cyan

$moonjq = ".\target\native\release\build\src\src.exe"
$testDir = "tests\temp_cond"
New-Item -ItemType Directory -Force -Path $testDir | Out-Null

$tests = @(
    @{Name="Simple if true"; JSON="5"; Query='if . > 3 then "big" else "small" end'; Expected='"big"'},
    @{Name="Simple if false"; JSON="2"; Query='if . > 3 then "big" else "small" end'; Expected='"small"'},
    @{Name="Elif first true"; JSON="10"; Query='if . > 5 then "large" elif . > 2 then "medium" else "small" end'; Expected='"large"'},
    @{Name="Elif second true"; JSON="4"; Query='if . > 5 then "large" elif . > 2 then "medium" else "small" end'; Expected='"medium"'},
    @{Name="Elif all false"; JSON="1"; Query='if . > 5 then "large" elif . > 2 then "medium" else "small" end'; Expected='"small"'},
    @{Name="Null is falsy"; JSON="null"; Query='if . then "truthy" else "falsy" end'; Expected='"falsy"'},
    @{Name="False is falsy"; JSON="false"; Query='if . then "truthy" else "falsy" end'; Expected='"falsy"'},
    @{Name="True is truthy"; JSON="true"; Query='if . then "truthy" else "falsy" end'; Expected='"truthy"'},
    @{Name="Zero is truthy"; JSON="0"; Query='if . then "truthy" else "falsy" end'; Expected='"truthy"'},
    @{Name="Empty string is truthy"; JSON='""'; Query='if . then "truthy" else "falsy" end'; Expected='"truthy"'},
    @{Name="Empty array is truthy"; JSON="[]"; Query='if . then "truthy" else "falsy" end'; Expected='"truthy"'},
    @{Name="Empty object is truthy"; JSON="{}"; Query='if . then "truthy" else "falsy" end'; Expected='"truthy"'},
    @{Name="Conditional with comparison"; JSON='{"age":25}'; Query='if .age >= 18 then "adult" else "minor" end'; Expected='"adult"'},
    @{Name="Nested conditional"; JSON="7"; Query='if . > 10 then "huge" else if . > 5 then "big" else "small" end end'; Expected='"big"'}
)

$passed = 0
$failed = 0

foreach ($test in $tests) {
    Write-Host "`nTest: $($test.Name)" -ForegroundColor Yellow
    Write-Host "  JSON: $($test.JSON)" -ForegroundColor Gray
    Write-Host "  Query: $($test.Query)" -ForegroundColor Gray
    
    # Write JSON to file
    $jsonFile = "$testDir\test.json"
    [System.IO.File]::WriteAllText($jsonFile, $test.JSON, (New-Object System.Text.UTF8Encoding $false))
    
    # Test with jq
    $jqResult = (Get-Content $jsonFile | jq $test.Query).Trim()
    
    # Test with moonjq
    $moonjqCmd = "jq '$($test.Query)' $jsonFile"
    $moonjqResult = ($moonjqCmd | & $moonjq 2>&1 | Select-String -Pattern "jq>" -NotMatch | Select-String -Pattern "moonjq" -NotMatch | Select-String -Pattern "Type jq" -NotMatch | Select-String -Pattern "Ctrl" -NotMatch | Out-String).Trim()
    
    if ($jqResult -eq $moonjqResult -and $jqResult -eq $test.Expected) {
        Write-Host "  PASS" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  FAIL" -ForegroundColor Red
        Write-Host "    Expected: $($test.Expected)" -ForegroundColor Magenta
        Write-Host "    jq:       $jqResult" -ForegroundColor Cyan
        Write-Host "    moonjq:   $moonjqResult" -ForegroundColor Yellow
        $failed++
    }
}

# Cleanup
Remove-Item -Recurse -Force $testDir

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red

if ($failed -eq 0) {
    Write-Host "`nAll conditional expression tests passed!" -ForegroundColor Green
} else {
    Write-Host "`nSome tests failed." -ForegroundColor Red
}
