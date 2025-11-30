# 测试数组索引和嵌套访问

Write-Host "=== Testing Array Indexing and Nested Access ===" -ForegroundColor Cyan

# 测试 1: 数组索引
Write-Host "`n1. Array indexing .users[0]:" -ForegroundColor Yellow
Write-Host "jq:      " -NoNewline -ForegroundColor Green
echo '{"users":[{"name":"Alice","age":30},{"name":"Bob","age":25}]}' | jq -c '.users[0]'

# 测试 2: 数组索引 + 字段访问
Write-Host "`n2. Nested access .users[0].name:" -ForegroundColor Yellow
Write-Host "jq:      " -NoNewline -ForegroundColor Green
echo '{"users":[{"name":"Alice","age":30},{"name":"Bob","age":25}]}' | jq -c '.users[0].name'

# 测试 3: 多层嵌套
Write-Host "`n3. Deep nesting .data.items[1]:" -ForegroundColor Yellow
Write-Host "jq:      " -NoNewline -ForegroundColor Green
echo '{"data":{"items":[1,2,3]}}' | jq -c '.data.items[1]'

# 测试 4: 数组索引 + 迭代
Write-Host "`n4. Array indexing with iterator .users[1].age:" -ForegroundColor Yellow
Write-Host "jq:      " -NoNewline -ForegroundColor Green
echo '{"users":[{"name":"Alice","age":30},{"name":"Bob","age":25}]}' | jq -c '.users[1].age'

# 测试 5: 负索引
Write-Host "`n5. Negative index .users[-1].name:" -ForegroundColor Yellow
Write-Host "jq:      " -NoNewline -ForegroundColor Green
echo '{"users":[{"name":"Alice","age":30},{"name":"Bob","age":25}]}' | jq -c '.users[-1].name'

Write-Host "`n=== All tests shown above ===" -ForegroundColor Cyan
