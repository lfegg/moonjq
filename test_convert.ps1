# Test tostring
Write-Host "Testing tostring:"
'123' | .\target\native\release\main.exe tostring
'true' | .\target\native\release\main.exe tostring
'null' | .\target\native\release\main.exe tostring
'[1,2,3]' | .\target\native\release\main.exe tostring

Write-Host "`nTesting tonumber:"
'"456"' | .\target\native\release\main.exe tonumber
'"3.14"' | .\target\native\release\main.exe tonumber
'123' | .\target\native\release\main.exe tonumber
'"abc"' | .\target\native\release\main.exe tonumber
