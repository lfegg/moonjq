# 手动测试指南
# 启动 moonjq REPL: moon run src
# 然后依次输入以下命令进行测试

# 测试 1: contains
echo '[1,2,3,4,5]' | jq 'contains([2,3])'

# 测试 2: flatten
echo '[[1,2],[3,4],[5,6]]' | jq 'flatten'

# 测试 3: flatten with depth
echo '[[[1,2]],[[3,4]]]' | jq 'flatten(1)'

# 测试 4: add
echo '[1,2,3,4,5]' | jq 'add'

# 测试 5: reverse
echo '[1,2,3,4,5]' | jq 'reverse'

# 测试 6: sort | reverse
echo '[5,2,8,1,9]' | jq 'sort | reverse'

# 预期输出：
# 1. true
# 2. [1,2,3,4,5,6]
# 3. [[1,2],[3,4]]
# 4. 15
# 5. [5,4,3,2,1]
# 6. [9,8,5,2,1]
