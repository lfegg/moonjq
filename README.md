# MoonJQ

MoonJQ 是一个使用 [MoonBit](https://github.com/moonbitlang/moonbit) 编写的轻量级、交互式 JSON 处理器。它的灵感来自于流行的命令行工具 `jq`，提供友好的 REPL 交互环境。

## 特性

- **交互式 REPL**: 提供友好的交互式环境，支持多种输入方式
- **文件读取**: 直接从文件读取 JSON 数据
- **Shell 命令风格**: 支持 `echo '...' | jq '...'` 和 `jq '...' file.json` 语法
- **可移植**: 编译为 WebAssembly (Wasm) 或 Native Binary，可在多种平台运行
- **轻量级**: 依赖极少，二进制体积小
- **核心 `jq` 功能**:
  - **恒等**: `.`
  - **字段访问**: `.foo`, `.bar`
  - **数组索引**: `.[0]`, `.[1]`
  - **数组切片**: `.[1:4]`, `.[-2:]`, `.[:3]` (支持负数索引)
  - **字符串切片**: `.[0:5]` (提取子字符串)
  - **迭代**: `.[]` (迭代数组元素或对象值)
  - **递归下降**: `..` (递归遍历所有值)
  - **可选操作符**: `.foo?` (安全访问，不存在时不报错)
  - **管道**: `|` (链接过滤器)
  - **选择**: `select(. > 10)` (基于条件过滤值)
  - **构造**: `[ .foo, .bar ]`, `{ "a": .foo }`
  - **比较**: `==`, `!=`, `>`, `<`, `>=`, `<=`
  - **算术运算**: `+`, `-`, `*`, `/`, `%` (支持数字、字符串、数组运算)
  - **括号**: `(...)` (改变运算优先级)
  - **负数字面量**: `-5`, `-3.14` (支持负数直接使用)
  - **类型函数**: `type` (返回值类型)
  - **成员检查**: `has(key)` (检查对象键或数组索引是否存在)
  - **包含检查**: `in(array)` (检查值是否在数组中)
  - **条件表达式**: `if-then-else-end`, `if-elif-else-end` (条件分支)
  - **数组操作**:
    - `map(expr)`: 对数组每个元素应用表达式
    - `select(expr)`: 根据条件过滤元素
    - `add`: 求和或连接数组元素
    - `min`, `max`: 获取最小/最大值
    - `sort`: 排序数组
    - `sort_by(expr)`: 按表达式结果排序
    - `group_by(expr)`: 按表达式结果分组
    - `unique`: 去重
    - `unique_by(expr)`: 按表达式结果去重
    - `reverse`: 反转数组
    - `flatten`, `flatten(depth)`: 扁平化数组
    - `contains(expr)`: 检查是否包含
    - `first`, `first(expr)`: 获取第一个元素或结果
    - `last`, `last(expr)`: 获取最后一个元素或结果
  - **退出**: `exit` 或 `exit()` 退出 REPL

## 安装与构建

确保你已经安装了 [MoonBit 工具链](https://www.moonbitlang.com/download/)。

1. 克隆仓库:

   ```bash
   git clone https://github.com/lfegg/moonjq.git
   cd moonjq
   ```

2. 构建项目 (需要 Native 支持):

   ```bash
   moon build --target native
   ```

3. 运行测试:

   ```bash
   moon test
   ```

## 用法

### 启动 REPL

```bash
# 使用 moon run
moon run --target native src

# 或直接运行编译后的可执行文件
.\target\native\release\build\src\src.exe
```

启动后会看到交互提示符：

```
moonjq - Interactive JSON processor (jq-compatible)
Type jq filters or shell commands (e.g., 'echo {...} | jq .')
Ctrl+C or Ctrl+D to exit.

jq>
```

### 使用方式

#### 1. Shell 命令风格：echo JSON | jq 查询

在 REPL 中输入完整的 shell 风格命令：

```bash
jq> echo '{"name":"Alice","age":25}' | jq '.'
{"name": "Alice", "age": 25}

jq> echo '[1,2,3,4,5]' | jq '.[] | select(. > 2)'
3
4
5
```

#### 2. 文件读取：jq 查询 文件名

直接从文件读取 JSON 数据：

```bash
jq> jq '.user.name' test.json
"Tom"

jq> jq '.user.skills' test.json
["Java", "JavaScript", "Go"]

jq> jq '.projects | .[] | select(.stars > 100)' test.json
{"title": "Web App", "stars": 120}
```

#### 3. 直接查询

输入查询表达式，使用默认的 null 数据：

```bash
jq> .
null

jq> 1 + 1
# (暂不支持算术运算)
```

#### 4. 退出 REPL

```bash
jq> exit
Goodbye!

# 或使用
jq> exit()
Goodbye!

# 也可以使用 Ctrl+D (Unix) 或 Ctrl+C
```

### 示例

#### 简单查询

```bash
jq> echo '{"name":"MoonBit","version":"0.1"}' | jq '.name'
"MoonBit"
```

#### 数组迭代

```bash
jq> echo '[1,2,3,4,5]' | jq '.[]'
1
2
3
4
5

jq> echo '[1,2,3,4,5]' | jq '.[] | select(. > 2)'
3
4
5
```

#### 切片操作

```bash
jq> echo '[0,1,2,3,4,5]' | jq '.[1:4]'
[1, 2, 3]

jq> echo '[0,1,2,3,4]' | jq '.[-2:]'
[3, 4]

jq> echo '"hello world"' | jq '.[0:5]'
"hello"

# 字段访问 + 切片
jq> jq '.skills[1:]' test_advanced.json
["python", "rust"]

jq> jq '.name[0:4]' test_advanced.json
"John"
```

#### 递归下降

```bash
jq> jq '..' test_advanced.json
# 递归输出所有值

jq> jq '.. | .city?' test_advanced.json
"NYC"
# 递归查找所有包含 city 字段的对象
```

#### 可选操作符

```bash
jq> echo '{"a":1}' | jq '.b?'
# 无输出，不会报错

jq> echo '[1,2,3]' | jq '.[10]?'
# 无输出，索引越界但不报错
```

#### 对象构造

```bash
jq> echo '{"users":[{"name":"Alice"},{"name":"Bob"}]}' | jq '.users | .[] | {user: .name}'
{"user": "Alice"}
{"user": "Bob"}
```

#### 算术运算

```bash
# 数字运算
jq> echo 'null' | jq '1 + 2'
3

jq> echo 'null' | jq '2 + 3 * 4'
14

jq> echo 'null' | jq '10 - 2 * 3'
4

# 字段运算
jq> jq '.age + 10' test_advanced.json
40

# 字符串连接
jq> echo 'null' | jq '"hello" + " " + "world"'
"hello world"

# 数组连接
jq> echo 'null' | jq '[1, 2] + [3, 4]'
[1, 2, 3, 4]

# 字符串重复
jq> echo 'null' | jq '"ab" * 3'
"ababab"
```

#### 成员检查和包含检查

```bash
# has() - 检查对象键是否存在
jq> echo '{"name":"John","age":30}' | jq 'has("name")'
true

jq> echo '{"name":"John"}' | jq 'has("email")'
false

# has() - 检查数组索引是否存在
jq> echo '[1,2,3]' | jq 'has(1)'
true

jq> echo '[1,2,3]' | jq 'has(5)'
false

jq> echo '[1,2,3]' | jq 'has(-1)'
true

# in() - 检查值是否在数组中
jq> echo '2' | jq 'in([1,2,3])'
true

jq> echo '5' | jq 'in([1,2,3])'
false

jq> echo '"b"' | jq 'in(["a","b","c"])'
true

# 结合使用
jq> echo '[{"a":1},{"b":2},{"a":3}]' | jq '.[] | select(has("a"))'
{"a": 1}
{"a": 3}
```

#### 条件表达式

```bash
# 简单 if-then-else
jq> echo '5' | jq 'if . > 3 then "big" else "small" end'
"big"

jq> echo '2' | jq 'if . > 3 then "big" else "small" end'
"small"

# elif 多条件分支
jq> echo '10' | jq 'if . > 5 then "large" elif . > 2 then "medium" else "small" end'
"large"

jq> echo '4' | jq 'if . > 5 then "large" elif . > 2 then "medium" else "small" end'
"medium"

jq> echo '1' | jq 'if . > 5 then "large" elif . > 2 then "medium" else "small" end'
"small"

# 真值判断：false 和 null 是假值，其他都是真值
jq> echo 'null' | jq 'if . then "yes" else "no" end'
"no"

jq> echo 'false' | jq 'if . then "yes" else "no" end'
"no"

jq> echo '0' | jq 'if . then "yes" else "no" end'
"yes"

jq> echo '""' | jq 'if . then "yes" else "no" end'
"yes"

# 结合其他操作
jq> echo '[1,5,3,8,2]' | jq '.[] | if . > 4 then "big" else "small" end'
"small"
"big"
"small"
"big"
"small"

jq> echo '{"age":25}' | jq 'if .age >= 18 then "adult" else "minor" end'
"adult"
```

#### 数组操作

```bash
# map() - 转换数组元素
jq> echo '[1,2,3,4,5]' | jq 'map(. * 2)'
[2, 4, 6, 8, 10]

jq> echo '[{"x":1,"y":2},{"x":3,"y":4}]' | jq 'map(.x)'
[1, 3]

# add - 求和或连接
jq> echo '[1,2,3,4,5]' | jq 'add'
15

jq> echo '["hello", " ", "world"]' | jq 'add'
"hello world"

jq> echo '[[1,2],[3,4],[5]]' | jq 'add'
[1, 2, 3, 4, 5]

# min/max - 最小/最大值
jq> echo '[5,2,8,1,9]' | jq 'min'
1

jq> echo '[5,2,8,1,9]' | jq 'max'
9

# sort - 排序
jq> echo '[5,2,8,1,9]' | jq 'sort'
[1, 2, 5, 8, 9]

# sort_by() - 按字段排序
jq> echo '[{"x":2},{"x":1},{"x":3}]' | jq 'sort_by(.x)'
[{"x": 1}, {"x": 2}, {"x": 3}]

# group_by() - 分组
jq> echo '[{"x":1,"y":2},{"x":1,"y":3},{"x":2,"y":4}]' | jq 'group_by(.x)'
[[{"x": 1, "y": 2}, {"x": 1, "y": 3}], [{"x": 2, "y": 4}]]

# unique - 去重
jq> echo '[1,2,1,3,2]' | jq 'unique'
[1, 2, 3]

# unique_by() - 按字段去重
jq> echo '[{"x":1,"y":2},{"x":1,"y":3},{"x":2,"y":4}]' | jq 'unique_by(.x)'
[{"x": 1, "y": 2}, {"x": 2, "y": 4}]

# reverse - 反转数组
jq> echo '[1,2,3,4,5]' | jq 'reverse'
[5, 4, 3, 2, 1]

jq> echo '[5,2,8,1,9]' | jq 'sort | reverse'
[9, 8, 5, 2, 1]

# flatten - 扁平化数组
jq> echo '[[1,2],[3,4],[5,6]]' | jq 'flatten'
[1, 2, 3, 4, 5, 6]

# flatten(depth) - 扁平化指定深度
jq> echo '[[[1,2]],[[3,4]]]' | jq 'flatten(1)'
[[1, 2], [3, 4]]

# contains() - 包含检查
jq> echo '[1,2,3,4,5]' | jq 'contains([2,3])'
true

jq> echo '[1,2,3]' | jq 'contains([4,5])'
false

jq> echo '"hello world"' | jq 'contains("world")'
true

jq> echo '{"a":1,"b":2}' | jq 'contains({"a":1})'
true

# first/last - 获取第一个/最后一个元素
jq> echo '[1,2,3,4,5]' | jq 'first'
1

jq> echo '[1,2,3,4,5]' | jq 'last'
5

jq> echo '[]' | jq 'first'
null

# first(expr)/last(expr) - 获取表达式的第一个/最后一个结果
jq> echo '[1,2,3,4,5]' | jq 'first(.[] | select(. > 2))'
3

jq> echo '[1,2,3,4,5]' | jq 'last(.[] | select(. > 2))'
5
```

#### 从文件读取

```bash
# 假设 test.json 包含: {"user": {"name": "Tom", "age": 20}}
jq> jq '.user.name' test.json
"Tom"

jq> jq '.user.age' test.json
20
```

## 项目结构

- `src/main.mbt`: REPL 主入口和交互逻辑
- `src/command_parser.mbt`: 命令行解析器，支持多种输入格式
- `src/parser.mbt`: JSON 和查询字符串递归下降解析器
- `src/eval.mbt`: 查询求值器
- `src/types.mbt`: JSON 和查询的 AST 定义
- `src/printer.mbt`: JSON 序列化
- `src/io.mbt`: 标准输入读取接口（平台无关）
- `src/io_ffi.*.mbt`: Backend 特定的 FFI 实现
- `src/io.c`: C 语言实现的底层 IO 函数（Native backend）

## 运算符优先级

MoonJQ 遵循以下运算符优先级（从高到低）：

1. **乘法/除法/取模**: `*`, `/`, `%`
2. **加法/减法**: `+`, `-`
3. **比较**: `==`, `!=`, `>`, `<`, `>=`, `<=`
4. **管道**: `|`
5. **逗号**: `,`

示例：

- `2 + 3 * 4` 等价于 `2 + (3 * 4)` = `14`
- `10 - 2 * 3` 等价于 `10 - (2 * 3)` = `4`

## 相关文档

- [FILE_READING_GUIDE.md](FILE_READING_GUIDE.md) - 文件读取功能详细说明
- [COMMAND_STYLE_GUIDE.md](COMMAND_STYLE_GUIDE.md) - Shell 命令风格使用指南
- [POWERSHELL_GUIDE.md](POWERSHELL_GUIDE.md) - PowerShell 环境下的使用指南

## 测试

项目包含完善的测试套件:

```bash
# 运行单元测试
moon test

# 运行兼容性测试 (PowerShell)
.\tests\test_jq_compatibility_v2.ps1

# 运行条件表达式测试
.\tests\test_conditional.ps1

# 运行 has/in 函数测试
.\tests\test_has_in.ps1

# 查看测试覆盖率
moon coverage analyze > uncovered.log
```

## 最近更新

### 版本 0.4.0 (2025-12-01)

**新功能：**

- ✅ **数组操作函数**：实现了 14 个强大的数组处理函数
  - `map(expr)`: 对每个元素应用表达式
  - `add`: 求和或连接数组元素
  - `min`, `max`: 获取最小/最大值
  - `sort`: 排序（支持数字、字符串、布尔值）
  - `sort_by(expr)`: 按表达式结果排序
  - `group_by(expr)`: 按表达式结果分组
  - `unique`: 去重（保持排序）
  - `unique_by(expr)`: 按表达式结果去重
  - `reverse`: 反转数组顺序
  - `flatten`, `flatten(depth)`: 扁平化嵌套数组
  - `contains(expr)`: 检查数组、字符串或对象是否包含指定内容
  - `first`, `first(expr)`: 获取第一个元素或表达式的第一个结果
  - `last`, `last(expr)`: 获取最后一个元素或表达式的最后一个结果

**Bug 修复：**

- ✅ 修复了 `.projects[].title` 解析错误（解析器现在能正确处理 `[]` 后的字段访问）
- ✅ 所有数组操作的输出与 jq 完全一致

**测试：**

- 🎯 所有 91 个单元测试通过
- ✅ 新增 11 个数组操作测试用例
- 📝 与 jq 行为完全兼容

### 版本 0.3.0 (2025-12-01)

**新功能：**

- ✅ 条件表达式：完整支持 `if-then-else-end` 和 `if-elif-else-end` 语法
- ✅ 真值判断：`false` 和 `null` 为假值，其他值（包括0、空字符串、空数组）为真值
- ✅ 嵌套条件：支持条件表达式的任意嵌套

**Bug 修复：**

- ✅ 修复了 `has(-1)` 对负索引的错误处理（现在返回 false，与 jq 一致）
- ✅ 修复了对象构造器 `{a:.x, b:.y}` 的解析问题
- ✅ 修复了负数索引 `.[-1]` 不工作的问题
- ✅ 修复了命令解析器中的转义字符处理

## 许可证

[Apache-2.0](LICENSE)
