# MoonJQ

MoonJQ 是一个使用 [MoonBit](https://github.com/moonbitlang/moonbit) 编写的轻量级、可移植的 JSON 处理器。

由于操作系统问题，兼容性一般，推荐尝试command-style分支的版本。

## 特性

- **可移植**: 编译为 WebAssembly (Wasm)，可在任何支持 Wasm 的地方运行。
- **轻量级**: 依赖极少，二进制体积小。
- **Unicode 支持**: 完整支持 `\uXXXX` Unicode 转义序列，正确处理中文、emoji 等多语言字符。
- **核心 `jq` 功能**:
  - **恒等**: `.`
  - **字段访问**: `.foo`, `.bar`
  - **数组索引**: `.[0]`, `.[1]`
  - **切片**: `.[start:end]` (数组和字符串切片，支持负数索引)
  - **迭代**: `.[]` (迭代数组元素或对象值)
  - **递归下降**: `..` (递归搜索所有层级的值)
  - **可选操作符**: `?` (安全访问，失败时返回 null)
  - **管道**: `|` (链接过滤器)
  - **选择**: `select(. > 10)` (基于条件过滤值)
  - **构造**: `[ .foo, .bar ]`, `{ "a": .foo }`
  - **算术运算**: `+`, `-`, `*`, `/` (支持数值运算和括号表达式)
  - **比较**: `==`, `!=`, `>`, `<`, `>=`, `<=`
  - **布尔运算**: `and`, `or`, `not`
  - **空值合并**: `//` (alternative operator)
  - **类型检查**: `type`, `has(key)`, `in(array)`
  - **类型转换**: `tostring`, `tonumber`
  - **工具函数**: `length`, `keys`
  - **数组操作**: `map(expr)`, `add`, `min`, `max`, `sort`, `sort_by(expr)`, `group_by(expr)`, `unique`, `unique_by(expr)`, `reverse`, `flatten`, `first`, `last`
  - **字符串操作**: `split(sep)`, `join(sep)`, `startswith(str)`, `endswith(str)`, `contains(str)`, `ltrimstr(str)`, `rtrimstr(str)`
  - **条件表达式**: `if-then-else-end`

## 安装与构建

确保你已经安装了 [MoonBit 工具链](https://www.moonbitlang.com/download/)。

1. 克隆仓库:

   ```bash
   git clone https://github.com/lfegg/moonjq.git
   cd moonjq
   ```

2. 构建项目:

   ```bash
   moon build
   ```

3. 运行测试:

   ```bash
   moon test
   ```

## 用法

基本用法语法如下:

```bash
moon run src -- <query> [json_string | file_path]
```

> **关于 `--`**: 命令中的 `--` 是必须的。它用于告诉 `moon` 构建工具，后面的参数不是给 `moon` 自己的，而是要传递给正在运行的程序 (`moonjq`) 的。

> **Windows 用户**: 如果您使用 Windows PowerShell 或 CMD，请参考 [README_WINDOWS.md](README_WINDOWS.md) 获取适合 Windows 的命令示例。

### 从文件读取 JSON

moonjq 支持直接从文件读取 JSON 数据：

```bash
# 从 test.json 文件读取并查询
moon run src -- ".user.name" test.json
# 输出: "Tom"

# 从文件读取并进行复杂查询
moon run src -- ".user.name | .[0:3]" test.json
# 输出: "Tom"

# 从文件读取并迭代数组
moon run src -- ".projects | .[] | .title" test.json
# 输出:
# "Web App"
# "CLI Tool"

# 从文件读取并进行过滤
moon run src -- ".user.skills | .[] | select(. != \"Java\")" test.json
# 输出:
# "JavaScript"
# "Go"
```

如果提供的参数无法作为文件读取，moonjq 会将其视为 JSON 字符串进行解析。

### 示例

#### 1. 恒等 (格式化输出)

```bash
moon run src -- "." '{"a": 1, "b": 2}'
# 输出: {"a": 1, "b": 2}
```

#### 2. 字段访问

```bash
moon run src -- ".name" '{"name": "MoonBit", "type": "Language"}'
# 输出: "MoonBit"
```

#### 3. 切片操作

切片操作支持数组和字符串，使用 `[start:end]` 语法。支持负数索引（从末尾开始计数）：

```bash
# 数组切片
moon run src -- ".[1:4]" "[0, 1, 2, 3, 4, 5]"
# 输出: [1, 2, 3]

# 从开头切片
moon run src -- ".[:3]" "[0, 1, 2, 3, 4]"
# 输出: [0, 1, 2]

# 切片到末尾
moon run src -- ".[2:]" "[0, 1, 2, 3, 4]"
# 输出: [2, 3, 4]

# 完整复制
moon run src -- ".[:]" "[0, 1, 2]"
# 输出: [0, 1, 2]

# 负数索引
moon run src -- ".[-3:-1]" "[0, 1, 2, 3, 4]"
# 输出: [2, 3]

# 字符串切片
moon run src -- ".user.name | .[0:3]" test.json
# 输出: "Tom"

# 数组字段切片
moon run src -- ".user.skills | .[1:]" test.json
# 输出: ["JavaScript", "Go"]
```

#### 4. 数组迭代与过滤

```bash
# 基本迭代
moon run src -- '.[]' '[1, 2, 3]'
# 输出:
# 1
# 2
# 3

# 字段数组迭代（简化语法）
moon run src -- '.projects[]' test.json
# 输出:
# {"title": "Web App", "stars": 120}
# {"title": "CLI Tool", "stars": 80}

# 字段迭代并访问子字段
moon run src -- '.projects[].title' test.json
# 输出:
# "Web App"
# "CLI Tool"

# 带过滤的迭代
moon run src -- '.[] | select(. > 1)' '[1, 2, 3]'
# 输出:
# 2
# 3
```

#### 5. 链式操作与对象构造

```bash
# 单字段对象构造
moon run src -- '{ user: .name }' '{"name": "Alice"}'
# 输出: {"user": "Alice"}

# 多字段对象构造
moon run src -- '{name: .name, age: .age}' '{"name": "Alice", "age": 30}'
# 输出: {"name": "Alice", "age": 30}

# 使用字符串键
moon run src -- '{"full_name": .name, "user_age": .age}' '{"name": "Bob", "age": 25}'
# 输出: {"full_name": "Bob", "user_age": 25}

# 在管道中使用
moon run src -- '.users | .[] | { user: .name }' '{"users": [{"name": "Alice"}, {"name": "Bob"}]}'
# 输出:
# {"user": "Alice"}
# {"user": "Bob"}
```

#### 6. 递归下降

递归下降操作符 `..` 会返回当前值及其所有嵌套的子值：

```bash
moon run src -- ".." '[1, [2, 3], 4]'
# 输出:
# [1, [2, 3], 4]
# 1
# [2, 3]
# 2
# 3
# 4

moon run src -- '..' '{"a": {"b": 1}, "c": 2}'
# 输出:
# {"a": {"b": 1}, "c": 2}
# {"b": 1}
# 1
# 2
```

结合 `select` 可以递归搜索满足条件的值：

```bash
moon run src -- '.. | select(. > 20)' '{"users": [{"name": "Alice", "age": 30}, {"name": "Bob", "age": 25}]}'
# 输出:
# 30
# 25
```

#### 7. 可选操作符（安全访问）

可选操作符 `?` 提供安全访问功能，当操作失败时返回 `null` 而不是报错：

```bash
# 访问不存在的字段
moon run src -- '.c?' '{"a": 1, "b": 2}'
# 输出: null

# 正常访问时返回实际值
moon run src -- '.a?' '{"a": 1, "b": 2}'
# 输出: 1

# 索引越界
moon run src -- ".[10]?" "[1, 2, 3]"
# 输出: null

# 迭代非数组/对象类型
moon run src -- ".[]?" "5"
# 输出: null

# 链式访问中的安全访问
moon run src -- '.a.b.c?' '{"a": {"b": {"x": 1}}}'
# 输出: null (因为 b 没有 c 字段)
```

#### 8. 类型检查函数

**type** - 返回值的类型：

```bash
moon run src -- "type" "[1, 2, 3]"
# 输出: "array"

moon run src -- ".user | type" test.json
# 输出: "object"

moon run src -- ".user.age | type" test.json
# 输出: "number"

# 结合管道检查多个值的类型
moon run src -- ".user.skills | .[] | type" test.json
# 输出:
# "string"
# "string"
# "string"
```

**has(key)** - 检查对象是否有指定的键：

```bash
moon run src -- '.user | has("name")' test.json
# 输出: true

moon run src -- '.user | has("email")' test.json
# 输出: false

# 过滤有特定键的对象
moon run src -- '.projects | .[] | select(has("stars"))' test.json
# 输出: {"title": "Web App", "stars": 120}
#       {"title": "CLI Tool", "stars": 80}
```

**in(array)** - 检查值是否在数组中：

```bash
moon run src -- 'in([1, 2, 3])' "2"
# 输出: true

moon run src -- 'in([1, 2, 3])' "5"
# 输出: false

# 检查字符串是否在列表中
moon run src -- 'in(["apple", "banana", "orange"])' '"banana"'
# 输出: true
```

#### 9. 复杂查询

```bash
moon run src -- '.data | .[] | select(.id == 1) | .value' '{"data": [{"id": 1, "value": "found"}, {"id": 2, "value": "lost"}]}'
# 输出: "found"
```

#### 10. 读取文件

可以直接传递文件路径作为第二个参数：

```bash
# 假设有一个 test.json 文件
moon run src -- ".user.name" test.json
# 输出: "Tom"
```

#### 11. 数组索引与嵌套访问

```bash
moon run src -- ".[1]" '[1, 2, 3, 4, 5]'
# 输出: 2

moon run src -- '.[1]' '["first", "second", "third"]'
# 输出: "second"

moon run src -- '.[0].name' '[{"name": "Alice"}, {"name": "Bob"}]'
# 输出: "Alice"
```

#### 12. 数组操作

```bash
# map - 对每个元素应用表达式
moon run src -- 'map(. * 2)' '[1, 2, 3, 4, 5]'
# 输出: [2, 4, 6, 8, 10]

moon run src -- 'map(.x)' '[{"x": 1}, {"x": 2}, {"x": 3}]'
# 输出: [1, 2, 3]

# add - 累加数字、拼接字符串或合并数组
moon run src -- "add" '[1, 2, 3, 4]'
# 输出: 10

moon run src -- 'add' '["hello", " ", "world"]'
# 输出: "hello world"

moon run src -- "add" '[[1, 2], [3, 4]]'
# 输出: [1, 2, 3, 4]

# min / max - 找最小值/最大值
moon run src -- "min" '[3, 1, 4, 1, 5]'
# 输出: 1

moon run src -- "max" '[3, 1, 4, 1, 5]'
# 输出: 5

# sort - 排序数组
moon run src -- "sort" '[3, 1, 4, 1, 5, 9, 2]'
# 输出: [1, 1, 2, 3, 4, 5, 9]

# sort_by - 按表达式结果排序
moon run src -- 'sort_by(.age)' '[{"name": "Alice", "age": 30}, {"name": "Bob", "age": 25}]'
# 输出: [{"name": "Bob", "age": 25}, {"name": "Alice", "age": 30}]

# group_by - 按表达式结果分组
moon run src -- 'group_by(.type)' '[{"type": "fruit", "name": "apple"}, {"type": "fruit", "name": "banana"}, {"type": "vegetable", "name": "carrot"}]'
# 输出: [[{"type": "fruit", "name": "apple"}, {"type": "fruit", "name": "banana"}], [{"type": "vegetable", "name": "carrot"}]]

# unique - 去重
moon run src -- "unique" '[1, 2, 2, 3, 1, 4, 3]'
# 输出: [1, 2, 3, 4]

# unique_by - 按表达式结果去重
moon run src -- 'unique_by(.age)' '[{"name": "Alice", "age": 30}, {"name": "Bob", "age": 25}, {"name": "Charlie", "age": 30}]'
# 输出: [{"name": "Alice", "age": 30}, {"name": "Bob", "age": 25}]
```

#### 13. 字符串操作

```bash
# split - 按分隔符分割字符串
moon run src -- 'split(",")' '"a,b,c,d"'
# 输出: ["a", "b", "c", "d"]

moon run src -- 'split("")' '"abc"'
# 输出: ["a", "b", "c"]

# join - 用分隔符连接数组元素
moon run src -- 'join(",")' '["a", "b", "c"]'
# 输出: "a,b,c"

moon run src -- 'join(" - ")' '["hello", "world"]'
# 输出: "hello - world"

# startswith - 检查是否以指定前缀开始
moon run src -- 'startswith("hello")' '"hello world"'
# 输出: true

moon run src -- 'startswith("world")' '"hello world"'
# 输出: false

# endswith - 检查是否以指定后缀结束
moon run src -- 'endswith("world")' '"hello world"'
# 输出: true

moon run src -- 'endswith("hello")' '"hello world"'
# 输出: false

# contains - 检查是否包含子串
moon run src -- 'contains("lo wo")' '"hello world"'
# 输出: true

moon run src -- 'contains("xyz")' '"hello world"'
# 输出: false

# ltrimstr - 去除左侧前缀
moon run src -- 'ltrimstr("hello ")' '"hello world"'
# 输出: "world"

moon run src -- 'ltrimstr("world")' '"hello world"'
# 输出: "hello world"  # 不匹配，返回原字符串

# rtrimstr - 去除右侧后缀
moon run src -- 'rtrimstr(" world")' '"hello world"'
# 输出: "hello"

moon run src -- 'rtrimstr("hello")' '"hello world"'
# 输出: "hello world"  # 不匹配，返回原字符串
```

#### 14. 算术运算

```bash
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

# 负数字面量
moon run src -- "-10 + 5" "null"
# 输出: -5

moon run src -- "-3.14 * 2" "null"
# 输出: -6.28

# 字符串连接
moon run src -- '.user.name + " Smith"' test.json
# 输出: "Tom Smith"

# 数组连接
moon run src -- '[1, 2] + [3, 4]' "null"
# 输出: [1, 2, 3, 4]

# 对象合并
moon run src -- '{a: 1} + {b: 2}' "null"
# 输出: {"a": 1, "b": 2}

# 混合运算（遵循标准运算优先级：乘除优先于加减）
moon run src -- ". * 2 + 1" "5"
# 输出: 11

moon run src -- ". + 10 / 2" "5"
# 输出: 10

# 在 map 中使用算术运算
moon run src -- 'map(. * 2)' '[1, 2, 3, 4, 5]'
# 输出: [2, 4, 6, 8, 10]

# 在 select 中使用算术运算
moon run src -- '.[] | select(. * 2 > 25)' '[5, 10, 15, 20]'
# 输出:
# 15
# 20

# 对非数值类型的算术操作返回 null
moon run src -- ". + 5" '"hello"'
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

#### 15. 布尔运算

```bash
# and - 逻辑与
moon run src -- 'if .age > 18 and .status == "active" then "allowed" else "denied" end' '{"age": 25, "status": "active"}'
# 输出: "allowed"

moon run src -- '.x > 0 and .y > 0' '{"x": 5, "y": 10}'
# 输出: true

# or - 逻辑或
moon run src -- '.x > 100 or .y > 100' '{"x": 5, "y": 200}'
# 输出: true

# not - 逻辑非
moon run src -- 'if not(.deleted) then .name else empty end' '{"name": "Alice", "deleted": false}'
# 输出: "Alice"

moon run src -- 'not(.active)' '{"active": false}'
# 输出: true

# 组合使用
moon run src -- '.x > 0 and (.y > 10 or .z > 10)' '{"x": 5, "y": 15, "z": 3}'
# 输出: true
```

#### 16. 空值合并 (Alternative Operator)

```bash
# 使用 // 提供默认值
moon run src -- '.name // "Unknown"' '{"age": 30}'
# 输出: "Unknown"

moon run src -- '.name // "Unknown"' '{"name": "Alice", "age": 30}'
# 输出: "Alice"

# 处理 false 值（false 会被跳过，使用右侧）
moon run src -- '.active // true' '{"active": false}'
# 输出: true

# 如果左侧有值则使用左侧
moon run src -- '.active // false' '{"active": true}'
# 输出: true

# 链式使用
moon run src -- '.config.timeout // .defaultTimeout // 30' '{"defaultTimeout": 60}'
# 输出: 60

# 在配置中使用
moon run src -- '{name: .name // "default", port: .port // 8080}' '{"name": "app"}'
# 输出: {"name": "app", "port": 8080}
```

#### 17. 类型转换

```bash
# tostring - 转换为字符串
moon run src -- 'tostring' '123'
# 输出: "123"

moon run src -- 'tostring' 'true'
# 输出: "true"

moon run src -- '.age | tostring' '{"age": 30}'
# 输出: "30"

# tonumber - 转换为数字
moon run src -- 'tonumber' '"456"'
# 输出: 456

moon run src -- '"123" | tonumber | . * 2' 'null'
# 输出: 246

# 处理无效输入
moon run src -- 'tonumber' '"abc"'
# 输出: null

# 在 map 中使用
moon run src -- 'map(tonumber)' '["1", "2", "3"]'
# 输出: [1, 2, 3]
```

#### 18. 数组函数

```bash
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
# 输出:
# 10
# 40

# 在管道中使用
moon run src -- 'reverse | first' '[1, 2, 3]'
# 输出: 3
```

#### 19. 条件表达式

```bash
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
moon run src -- 'if .age >= 18 then \"adult\" else \"minor\" end' '{"age": 25}'
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
```

#### 20. Unicode 支持

MoonJQ 完整支持 JSON 标准的 `\uXXXX` Unicode 转义序列，可以正确处理包括中文、日文、emoji 等在内的所有 Unicode 字符。

```bash
# 解析 Unicode 转义的中文字符
moon run src -- "." test_unicode.json
# 输出: {"greeting": "Hello 世界!", "name": "张三", "emoji": "❤️", "mixed": "ASCII and 中文"}

# 提取 Unicode 字段
moon run src -- ".name" test_unicode.json
# 输出: "张三"

# Unicode 转义在 JSON 字符串中
moon run src -- "." '{"text": "\u4e2d\u6587"}'
# 输出: {"text": "中文"}

# Unicode emoji
moon run src -- ".emoji" test_unicode.json
# 输出: "❤️"
```

支持的 Unicode 范围：

- 基本拉丁字母：`\u0041` (A)
- 中日韩字符：`\u4e2d` (中)、`\u6587` (文)
- 特殊符号和 emoji：`\u2764` (❤)
- 完整的 Unicode BMP 平面（U+0000 到 U+FFFF）

## 项目结构

- `src/main.mbt`: CLI 入口点和参数处理。
- `src/parser.mbt`: 手写的 JSON 和查询字符串递归下降解析器。
- `src/eval.mbt`: 针对 JSON 数据执行查询的评估逻辑。
- `src/types.mbt`: JSON 和查询的 AST 定义。
- `src/printer.mbt`: JSON 序列化逻辑。

## 许可证

[Apache-2.0](LICENSE)
