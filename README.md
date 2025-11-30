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
  - **迭代**: `.[]` (迭代数组元素或对象值)
  - **管道**: `|` (链接过滤器)
  - **选择**: `select(. > 10)` (基于条件过滤值)
  - **构造**: `[ .foo, .bar ]`, `{ "a": .foo }`
  - **比较**: `==`, `!=`, `>`, `<`, `>=`, `<=`
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

#### 数组操作

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

#### 对象构造

```bash
jq> echo '{"users":[{"name":"Alice"},{"name":"Bob"}]}' | jq '.users | .[] | {user: .name}'
{"user": "Alice"}
{"user": "Bob"}
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

## 相关文档

- [FILE_READING_GUIDE.md](FILE_READING_GUIDE.md) - 文件读取功能详细说明
- [COMMAND_STYLE_GUIDE.md](COMMAND_STYLE_GUIDE.md) - Shell 命令风格使用指南

## 许可证

[Apache-2.0](LICENSE)
