# moonjq - Windows 用户指南

一个用 MoonBit 编写的 JSON 处理工具，灵感来自 [jq](https://jqlang.github.io/jq/)。

> **注意**：本文档专门针对 Windows PowerShell 用户编写。如果您使用 Linux/macOS，请参考 [README.md](README.md)。

## 安装

确保您已安装 [MoonBit 工具链](https://www.moonbitlang.com/download/)（版本 0.4.37 或更高）。

## 快速开始

### 构建项目

```powershell
moon build
```

### 运行示例

```powershell
# 基本用法 - 提取字段
moon run src -- ".name" '{\"name\": \"Alice\", \"age\": 30}'
# 输出: "Alice"

# 处理数组
moon run src -- ".[0]" '[1, 2, 3]'
# 输出: 1
```

### 从文件读取 JSON

```powershell
# 读取文件内容
Get-Content test.json | moon run src -- ".name"

# 或者使用标准输入重定向
moon run src -- ".name" < test.json
```

## Windows PowerShell 特别说明

### JSON 字符串转义

在 Windows PowerShell 中处理 JSON 时，需要特别注意引号的转义：

```powershell
# ✅ 正确：使用反斜杠转义 JSON 中的双引号
moon run src -- ".name" '{\"name\": \"Alice\"}'

# ❌ 错误：会导致解析错误
moon run src -- ".name" '{"name": "Alice"}'
```

### 查询字符串中的引号

当查询本身包含字符串字面量时，也需要转义：

```powershell
# ✅ 正确：查询中的字符串使用 \" 转义
moon run src -- 'if . > 5 then \"large\" else \"small\" end' "10"

# ❌ 错误：会导致解析错误
moon run src -- 'if . > 5 then "large" else "small" end' "10"
```

### 使用单引号和双引号

- **外层使用单引号** `'...'` 包裹查询语句
- **内层 JSON 或字符串字面量使用** `\"` 转义双引号

```powershell
# 查询语句用单引号，JSON 数据中的引号用 \" 转义
moon run src -- '.items[0].name' '{\"items\": [{\"name\": \"item1\"}]}'
```

## 功能特性

### 1. 基本选择器

```powershell
# 身份运算符
moon run src -- "." "42"
# 输出: 42

# 字段访问
moon run src -- ".name" '{\"name\": \"Alice\"}'
# 输出: "Alice"

# 嵌套字段
moon run src -- ".person.name" '{\"person\": {\"name\": \"Bob\"}}'
# 输出: "Bob"
```

### 2. 数组操作

```powershell
# 数组索引
moon run src -- ".[1]" '[1, 2, 3]'
# 输出: 2

# 数组切片
moon run src -- ".[1:3]" '[0, 1, 2, 3, 4]'
# 输出: [1, 2]

# 负索引
moon run src -- ".[-1]" '[1, 2, 3]'
# 输出: 3

# 数组迭代器
moon run src -- ".[]" '[1, 2, 3]'
# 输出: 1 2 3 (每行一个)
```

### 3. 管道操作

```powershell
# 链式操作
moon run src -- ".items | .[0]" '{\"items\": [1, 2, 3]}'
# 输出: 1

# 复杂管道
moon run src -- ".users | .[0] | .name" '{\"users\": [{\"name\": \"Alice\"}]}'
# 输出: "Alice"
```

### 4. 递归下降

```powershell
# 递归查找所有 name 字段（可选操作符 ? 会为没有 name 的对象返回 null）
moon run src -- ".. | .name?" '{\"name\": \"root\", \"child\": {\"name\": \"leaf\"}}'
# 输出: "root" null "leaf" null

# 递归查找所有数组元素
moon run src -- ".. | .[]?" '[1, [2, [3, 4]]]'
# 输出: 1 2 3 4

# 如果只想要有值的结果，可以用 select
moon run src -- ".. | .name? | select(. != null)" '{\"name\": \"root\", \"child\": {\"name\": \"leaf\"}}'
# 输出: "root" "leaf"
```

### 5. 可选运算符

```powershell
# 安全访问不存在的字段（不报错）
moon run src -- ".missing?" '{\"name\": \"Alice\"}'
# 输出: null

# 安全访问数组越界（不报错）
moon run src -- ".[10]?" '[1, 2, 3]'
# 输出: null
```

### 6. 对象构造

```powershell
# 构造新对象（单个字段）
moon run src -- '{ user: .name }' '{\"name\": \"Alice\"}'
# 输出: {"user": "Alice"}

# 构造多字段对象
moon run src -- '{name: .name, age: .age}' '{\"name\": \"Alice\", \"age\": 30}'
# 输出: {"name": "Alice", "age": 30}

# 使用字符串键（支持特殊字符）
moon run src -- '{\"full_name\": .name, \"user_age\": .age}' '{\"name\": \"Bob\", \"age\": 25}'
# 输出: {"full_name": "Bob", "user_age": 25}

# 混合使用字段和字面量
moon run src -- '{name: .name, status: \"active\", count: 5}' '{\"name\": \"Charlie\"}'
# 输出: {"name": "Charlie", "status": "active", "count": 5}

# 在管道中使用对象构造
moon run src -- '.users | .[] | { user: .name }' '{\"users\": [{\"name\": \"Alice\"}, {\"name\": \"Bob\"}]}'
# 输出:
# {"user": "Alice"}
# {"user": "Bob"}
```

### 7. 数组构造

```powershell
# 构造数组
moon run src -- "[.name, .age]" '{\"name\": \"Alice\", \"age\": 30}'
# 输出: ["Alice", 30]

# 收集迭代结果
moon run src -- "[.items[]]" '{\"items\": [1, 2, 3]}'
# 输出: [1, 2, 3]
```

### 8. 算术运算

```powershell
# 加法
moon run src -- ". + 5" "10"
# 输出: 15

# 减法
moon run src -- ". - 3" "20"
# 输出: 17

# 乘法
moon run src -- ". * 4" "7"
# 输出: 28

# 除法
moon run src -- ". / 2" "100"
# 输出: 50

# 混合运算（遵循标准运算优先级）
moon run src -- ". * 2 + 1" "5"
# 输出: 11

moon run src -- ". + 10 / 2" "5"
# 输出: 10

# 在 map 中使用算术运算
moon run src -- 'map(. * 2)' '[1, 2, 3, 4, 5]'
# 输出: [2, 4, 6, 8, 10]

# 在 select 中使用算术运算
moon run src -- '.[] | select(. * 2 > 25)' '[5, 10, 15, 20]'
# 输出: 15 20

# 对非数值类型的算术操作返回 null
moon run src -- ". + 5" '\"hello\"'
# 输出: null

# 使用括号改变运算优先级
moon run src -- "(. + 5) * 2" "10"
# 输出: 30

moon run src -- "2 * (3 + 4)" "0"
# 输出: 14

# 嵌套括号
moon run src -- "((. + 5) * 2) - 1" "10"
# 输出: 29
```

### 9. 布尔运算

```powershell
# and - 逻辑与
moon run src -- 'if .age > 18 and .status == \"active\" then \"allowed\" else \"denied\" end' '{\"age\": 25, \"status\": \"active\"}'
# 输出: "allowed"

moon run src -- '.x > 0 and .y > 0' '{\"x\": 5, \"y\": 10}'
# 输出: true

# or - 逻辑或
moon run src -- '.x > 100 or .y > 100' '{\"x\": 5, \"y\": 200}'
# 输出: true

# not - 逻辑非
moon run src -- 'if not(.deleted) then .name else empty end' '{\"name\": \"Alice\", \"deleted\": false}'
# 输出: "Alice"

moon run src -- 'not(.active)' '{\"active\": false}'
# 输出: true

# 组合使用
moon run src -- '.x > 0 and (.y > 10 or .z > 10)' '{\"x\": 5, \"y\": 15, \"z\": 3}'
# 输出: true
```

### 10. 空值合并 (Alternative Operator)

```powershell
# 使用 // 提供默认值
moon run src -- '.name // \"Unknown\"' '{\"age\": 30}'
# 输出: "Unknown"

moon run src -- '.name // \"Unknown\"' '{\"name\": \"Alice\", \"age\": 30}'
# 输出: \"Alice\"

# 处理 false 值（false 会被跳过，使用右侧）
moon run src -- '.active // true' '{\"active\": false}'
# 输出: true

# 如果左侧有值则使用左侧
moon run src -- '.active // false' '{\"active\": true}'
# 输出: true

# 链式使用
moon run src -- '.config.timeout // .defaultTimeout // 30' '{\"defaultTimeout\": 60}'
# 输出: 60

# 在配置中使用
moon run src -- '{name: .name // \"default\", port: .port // 8080}' '{\"name\": \"app\"}'
# 输出: {"name": "app", "port": 8080}
```

### 11. 类型转换

```powershell
# tostring - 转换为字符串
moon run src -- 'tostring' '123'
# 输出: "123"

moon run src -- 'tostring' 'true'
# 输出: "true"

moon run src -- '.age | tostring' '{\"age\": 30}'
# 输出: "30"

# tonumber - 转换为数字
moon run src -- 'tonumber' '\"456\"'
# 输出: 456

moon run src -- '\"123\" | tonumber | . * 2' 'null'
# 输出: 246

# 处理无效输入
moon run src -- 'tonumber' '\"abc\"'
# 输出: null

# 在 map 中使用
moon run src -- 'map(tonumber)' '[\"1\", \"2\", \"3\"]'
# 输出: [1, 2, 3]
```

### 12. 数组函数

```powershell
# reverse - 反转数组
moon run src -- 'reverse' '[1, 2, 3, 4, 5]'
# 输出: [5, 4, 3, 2, 1]

# flatten - 扁平化数组（一层）
moon run src -- 'flatten' '[[1, 2], [3, 4], [5]]'
# 输出: [1, 2, 3, 4, 5]

moon run src -- 'flatten' '[[1, [2, 3]], [4, 5]]'
# 输出: [1, [2, 3], 4, 5]

# first - 获取第一个元素
moon run src -- 'first' '[10, 20, 30]'
# 输出: 10

# last - 获取最后一个元素
moon run src -- 'last' '[10, 20, 30]'
# 输出: 30

# 组合使用
moon run src -- 'first, last' '[10, 20, 30, 40]'
# 输出: 10 40

# 在管道中使用
moon run src -- 'reverse | first' '[1, 2, 3]'
# 输出: 3
```

### 13. 逗号运算符

```powershell
# 多个输出
moon run src -- ".name, .age" '{\"name\": \"Alice\", \"age\": 30}'
# 输出: "Alice" 30

# 多个查询
moon run src -- ".[0], .[2]" '[1, 2, 3]'
# 输出: 1 3
```

### 10. 类型检查函数

```powershell
# type - 返回值的类型
moon run src -- "type" "42"
# 输出: "number"

moon run src -- "type" '\"hello\"'
# 输出: "string"

moon run src -- ".items | type" '{\"items\": [1, 2]}'
# 输出: "array"

# has(key) - 检查对象是否包含键
moon run src -- 'has(\"name\")' '{\"name\": \"Alice\", \"age\": 30}'
# 输出: true

moon run src -- 'has(\"email\")' '{\"name\": \"Alice\"}'
# 输出: false

# in(array) - 检查值是否在数组中
moon run src -- 'in([1, 2, 3])' "2"
# 输出: true

moon run src -- 'in([1, 2, 3])' "5"
# 输出: false

# 检查字符串是否在列表中
moon run src -- 'in([\"apple\", \"banana\", \"orange\"])' '\"banana\"'
# 输出: true
```

### 11. 数组函数

```powershell
# map(expr) - 对数组每个元素应用表达式
moon run src -- 'map(. * 2)' '[1, 2, 3, 4, 5]'
# 输出: [2, 4, 6, 8, 10]

moon run src -- 'map(.x)' '[{\"x\": 1}, {\"x\": 2}, {\"x\": 3}]'
# 输出: [1, 2, 3]

moon run src -- '.items | map(.price)' '{\"items\": [{\"price\": 10}, {\"price\": 20}]}'
# 输出: [10, 20]

# add - 求和（数字）或连接（字符串/数组）
moon run src -- "add" "[1, 2, 3, 4]"
# 输出: 10

moon run src -- "add" '[\"Hello\", \" \", \"World\"]'
# 输出: "Hello World"

# min - 最小值
moon run src -- "min" "[3, 1, 4, 1, 5]"
# 输出: 1

# max - 最大值
moon run src -- "max" "[3, 1, 4, 1, 5]"
# 输出: 5

# sort - 排序
moon run src -- "sort" "[3, 1, 4, 1, 5]"
# 输出: [1, 1, 3, 4, 5]

# group_by(expr) - 按表达式分组
moon run src -- "group_by(.type)" '[{\"type\": \"a\", \"val\": 1}, {\"type\": \"b\", \"val\": 2}, {\"type\": \"a\", \"val\": 3}]'
# 输出: [[{"type": "a", "val": 1}, {"type": "a", "val": 3}], [{"type": "b", "val": 2}]]

# unique - 去重
moon run src -- "unique" "[1, 2, 1, 3, 2]"
# 输出: [1, 2, 3]

# unique_by(expr) - 按表达式去重
moon run src -- "unique_by(.id)" '[{\"id\": 1, \"name\": \"a\"}, {\"id\": 2, \"name\": \"b\"}, {\"id\": 1, \"name\": \"c\"}]'
# 输出: [{"id": 1, "name": "a"}, {"id": 2, "name": "b"}]
```

### 12. 字符串函数

```powershell
# split(sep) - 分割字符串
moon run src -- 'split(\",\")' '\"a,b,c\"'
# 输出: ["a", "b", "c"]

# join(sep) - 连接数组
moon run src -- 'join(\"-\")' '[\"2024\", \"01\", \"01\"]'
# 输出: "2024-01-01"

# startswith(str) - 检查是否以指定字符串开头
moon run src -- 'startswith(\"hello\")' '\"hello-world\"'
# 输出: true

# endswith(str) - 检查是否以指定字符串结尾
moon run src -- 'endswith(\"world\")' '\"hello-world\"'
# 输出: true

# contains(str) - 检查是否包含子字符串
moon run src -- 'contains(\"lo\")' '\"hello\"'
# 输出: true

# ltrimstr(str) - 删除开头的字符串
moon run src -- 'ltrimstr(\"hello-\")' '\"hello-world\"'
# 输出: "world"

# rtrimstr(str) - 删除结尾的字符串
moon run src -- 'rtrimstr(\"-world\")' '\"hello-world\"'
# 输出: "hello"
```

### 13. 比较运算

```powershell
# 等于
moon run src -- ". == 5" "5"
# 输出: true

# 不等于
moon run src -- ". != 5" "3"
# 输出: true

# 大于
moon run src -- ". > 5" "10"
# 输出: true

# 小于
moon run src -- ". < 5" "3"
# 输出: true

# 大于等于
moon run src -- ". >= 5" "5"
# 输出: true

# 小于等于
moon run src -- ". <= 5" "3"
# 输出: true
```

### 14. 条件表达式

```powershell
# if-then-else-end - 条件分支
moon run src -- 'if . > 5 then \"large\" else \"small\" end' "10"
# 输出: "large"

moon run src -- 'if . > 5 then \"large\" else \"small\" end' "3"
# 输出: "small"

# 使用类型检查
moon run src -- 'if type == \"string\" then . else \"not a string\" end' '\"hello\"'
# 输出: "hello"

moon run src -- 'if type == \"string\" then . else \"not a string\" end' "123"
# 输出: "not a string"

# 检查字段
moon run src -- 'if .age >= 18 then \"adult\" else \"minor\" end' '{\"age\": 25}'
# 输出: "adult"

# null 和 false 是假值
moon run src -- 'if . then \"has value\" else \"null value\" end' "null"
# 输出: "null value"

moon run src -- 'if . then \"true\" else \"false\" end' "false"
# 输出: "false"

# 其他所有值都是真值（包括 0、空字符串、空数组）
moon run src -- 'if . then \"true\" else \"false\" end' "0"
# 输出: "true"

moon run src -- 'if . then \"true\" else \"false\" end' '\"\"'
# 输出: "true"

moon run src -- 'if . then \"true\" else \"false\" end' "[]"
# 输出: "true"
```

## 常见问题

### Q: 为什么我的命令报错 "Unknown function or identifier"？

**A:** 这通常是因为查询中的字符串字面量没有正确转义。记住在查询中使用 `\"` 而不是 `"`：

```powershell
# ❌ 错误
moon run src -- 'if . > 5 then "large" else "small" end' "10"

# ✅ 正确
moon run src -- 'if . > 5 then \"large\" else \"small\" end' "10"
```

### Q: 如何处理复杂的 JSON 文件？

**A:** 使用 PowerShell 的 `Get-Content` 或重定向：

```powershell
# 方法 1：使用 Get-Content
Get-Content data.json | moon run src -- ".users[0].name"

# 方法 2：使用重定向
moon run src -- ".users[0].name" < data.json

# 方法 3：使用 PowerShell 变量
$json = Get-Content data.json -Raw
moon run src -- ".users[0].name" $json
```

### Q: 如何保存输出到文件？

**A:** 使用 PowerShell 的重定向或 `Out-File`：

```powershell
# 方法 1：使用 > 重定向
moon run src -- ".name" '{\"name\": \"Alice\"}' > output.txt

# 方法 2：使用 Out-File
moon run src -- ".name" '{\"name\": \"Alice\"}' | Out-File -FilePath output.txt

# 方法 3：使用 Tee-Object 同时显示和保存
moon run src -- ".name" '{\"name\": \"Alice\"}' | Tee-Object -FilePath output.txt
```

### Q: 如何处理多行 JSON？

**A:** 在 PowerShell 中使用 here-string 或者从文件读取：

```powershell
# 方法 1：使用 here-string
$json = @'
{
  "name": "Alice",
  "age": 30
}
'@
moon run src -- ".name" $json

# 方法 2：从文件读取（推荐）
moon run src -- ".name" < data.json
```

## 开发

### 运行测试

```powershell
moon test
```

### 更新测试快照

```powershell
moon test --update
```

### 代码检查

```powershell
moon check
```

### 代码格式化

```powershell
moon fmt
```

### 更新接口

```powershell
moon info
```

## 项目结构

```text
moonjq/
├── src/              # 源代码
│   ├── types.mbt     # 类型定义
│   ├── parser.mbt    # 解析器
│   ├── eval.mbt      # 求值器
│   ├── printer.mbt   # 输出格式化
│   └── main.mbt      # 入口点
├── moon.mod.json     # 模块配置
├── moon.pkg.json     # 包配置
└── README_WINDOWS.md # 本文档
```

## 许可证

MIT License

## 相关链接

- [MoonBit 官网](https://www.moonbitlang.com/)
- [MoonBit 文档](https://docs.moonbitlang.com/)
- [jq 官方文档](https://jqlang.github.io/jq/)
- [原版 README (Linux/macOS)](README.md)
