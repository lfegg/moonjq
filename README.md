# MoonJQ

MoonJQ 是一个使用 [MoonBit](https://github.com/moonbitlang/moonbit) 编写的轻量级、可移植的 JSON 处理器。它的灵感来自于流行的命令行工具 `jq`。

## 特性

- **可移植**: 编译为 WebAssembly (Wasm)，可在任何支持 Wasm 的地方运行。
- **轻量级**: 依赖极少，二进制体积小。
- **核心 `jq` 功能**:
  - **恒等**: `.`
  - **字段访问**: `.foo`, `.bar`
  - **数组索引**: `.[0]`, `.[1]`
  - **迭代**: `.[]` (迭代数组元素或对象值)
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

#### 3. 数组迭代与过滤

```bash
moon run src -- ".[] | select(. > 1)" '[1, 2, 3]'
or
moon run src -- '.[] | select(. > 1)' '[1,2,3]'
# 输出:
# 2
# 3
```

#### 4. 链式操作与对象构造

```bash
moon run src -- ".users | .[] | { user: .name }" '{"users": [{"name": "Alice"}, {"name": "Bob"}]}'
or
moon run src -- '.users | .[] | { user: .name }' '{\"users\": [{\"name\": \"Alice\"}, {\"name\": \"Bob\"}]}'
# 输出:
# {"user": "Alice"}
# {"user": "Bob"}
```

#### 5. 复杂查询

```bash
moon run src -- ".data | .[] | select(.id == 1) | .value" '{"data": [{"id": 1, "value": "found"}, {"id": 2, "value": "lost"}]}'
or
moon run src -- '.data | .[] | select(.id == 1) | .value' '{\"data\": [{\"id\": 1, \"value\": \"found\"}, {\"id\": 2, \"value\": \"lost\"}]}'
# 输出: "found"
```

#### 6. 读取文件

可以直接传递文件路径作为第二个参数：

```bash
# 假设有一个 test.json 文件
moon run src -- ".user.name" test.json
# 输出: "Tom"
```

#### 7. 数组索引与嵌套访问

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
