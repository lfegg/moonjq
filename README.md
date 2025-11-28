# MoonJQ

MoonJQ 是一个使用 [MoonBit](https://github.com/moonbitlang/moonbit) 编写的轻量级、可移植的 JSON 处理器。它的灵感来自于流行的命令行工具 `jq`。

## 特性

- **可移植**: 编译为 WebAssembly (Wasm)，可在任何支持 Wasm 的地方运行。
- **轻量级**: 依赖极少，二进制体积小。
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
  - **比较**: `==`, `!=`, `>`, `<`, `>=`, `<=`

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

### Windows CMD 用户注意

在 Windows CMD (命令提示符) 中，**不能**使用单引号 `'` 来包围 JSON 字符串。必须使用双引号 `"`，并且 JSON 内部的双引号需要使用反斜杠 `\` 转义。

**CMD 示例:**

```cmd
moon run src -- ".name" "{\"name\": \"MoonBit\"}"
```

### 示例

#### 1. 恒等 (格式化输出)

```bash
moon run src -- "." '{"a": 1, "b": 2}'
or
moon run src -- "." '{\"a\": 1, \"b\": 2}'
# 输出: {"a": 1, "b": 2}
```

#### 2. 字段访问

```bash
moon run src -- ".name" '{"name": "MoonBit", "type": "Language"}'
or
moon run src -- ".name" '{\"name\": \"MoonBit\", \"type\": \"Language\"}'
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
moon run src -- ".[] | select(. > 1)" '[1, 2, 3]'
or
moon run src -- '.[] | select(. > 1)' '[1,2,3]'
# 输出:
# 2
# 3
```

#### 5. 链式操作与对象构造

```bash
moon run src -- ".users | .[] | { user: .name }" '{"users": [{"name": "Alice"}, {"name": "Bob"}]}'
or
moon run src -- '.users | .[] | { user: .name }' '{\"users\": [{\"name\": \"Alice\"}, {\"name\": \"Bob\"}]}'
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

moon run src -- ".." '{"a": {"b": 1}, "c": 2}'
or
moon run src -- ".." '{\"a\": {\"b\": 1}, \"c\": 2}'
# 输出:
# {"a": {"b": 1}, "c": 2}
# {"b": 1}
# 1
# 2
```

结合 `select` 可以递归搜索满足条件的值：

```bash
moon run src -- ".. | select(. > 20)" '{"users": [{"name": "Alice", "age": 30}, {"name": "Bob", "age": 25}]}'
or
moon run src -- '.. | select(. > 20)' '{\"users\": [{\"name\": \"Alice\", \"age\": 30}, {\"name\": \"Bob\", \"age\": 25}]}'
# 输出:
# 30
# 25
```

#### 7. 可选操作符（安全访问）

可选操作符 `?` 提供安全访问功能，当操作失败时返回 `null` 而不是报错：

```bash
# 访问不存在的字段
moon run src -- ".c?" '{"a": 1, "b": 2}'
or
moon run src -- ".c?" '{\"a\": 1, \"b\": 2}'
# 输出: null

# 正常访问时返回实际值
moon run src -- ".a?" '{"a": 1, "b": 2}'
or
moon run src -- ".a?" '{\"a\": 1, \"b\": 2}'
# 输出: 1

# 索引越界
moon run src -- ".[10]?" "[1, 2, 3]"
# 输出: null

# 迭代非数组/对象类型
moon run src -- ".[]?" "5"
# 输出: null

# 链式访问中的安全访问
moon run src -- ".a.b.c?" '{"a": {"b": {"x": 1}}}'
or
moon run src -- ".a.b.c?" '{\"a\": {\"b\": {\"x\": 1}}}'
# 输出: null (因为 b 没有 c 字段)
```

#### 8. 复杂查询

```bash
moon run src -- ".data | .[] | select(.id == 1) | .value" '{"data": [{"id": 1, "value": "found"}, {"id": 2, "value": "lost"}]}'
or
moon run src -- '.data | .[] | select(.id == 1) | .value' '{\"data\": [{\"id\": 1, \"value\": \"found\"}, {\"id\": 2, \"value\": \"lost\"}]}'
# 输出: "found"
```

#### 9. 读取文件

可以直接传递文件路径作为第二个参数：

```bash
# 假设有一个 test.json 文件
moon run src -- ".user.name" test.json
# 输出: "Tom"
```

#### 10. 数组索引与嵌套访问

```bash
moon run src -- ".[1]" '[1, 2, 3, 4, 5]'
# 输出: 2

moon run src -- ".[1]" '["first", "second", "third"]'
or
moon run src -- ".[1]" '[\"first\", \"second\", \"third\"]'
# 输出: "second"

moon run src -- ".[0].name" '[{"name": "Alice"}, {"name": "Bob"}]'
or
moon run src -- ".[0].name" '[{\"name\": \"Alice\"}, {\"name\": \"Bob\"}]'
# 输出: "Alice"
```

## 项目结构

- `src/main.mbt`: CLI 入口点和参数处理。
- `src/parser.mbt`: 手写的 JSON 和查询字符串递归下降解析器。
- `src/eval.mbt`: 针对 JSON 数据执行查询的评估逻辑。
- `src/types.mbt`: JSON 和查询的 AST 定义。
- `src/printer.mbt`: JSON 序列化逻辑。

## 许可证

[Apache-2.0](LICENSE)
