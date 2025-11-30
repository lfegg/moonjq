# MoonJQ 交互式 REPL 使用指南（jq 兼容语法）

## 启动 REPL

### 方式 1: 从管道读取 JSON（推荐，与 jq 相同）

```bash
# 从管道传入 JSON，然后在 REPL 中输入查询
echo '{"name":"Alice","age":25}' | moonjq.exe

# 或使用 moon run
echo '{"name":"Alice","age":25}' | moon run --target native src
```

### 方式 2: 直接启动（使用 null 作为输入）

```bash
# 直接启动，默认输入为 null
.\target\native\release\build\src\src.exe

# 或
moon run --target native src
```

## 使用方式（与原版 jq 相同）

### 从管道读取 JSON

```bash
PS> echo '{"name":"Alice","age":25}' | .\target\native\release\build\src\src.exe
moonjq - Interactive JSON processor (jq-compatible)
Type jq filters (e.g., '.', '.key', '.[0]')
Ctrl+C or Ctrl+D to exit.

jq> .name
"Alice"
jq> .age
25
jq> .
{"name": "Alice", "age": 25}
```

### 示例会话 1: 查询对象字段

```bash
PS> echo '{"user":{"name":"Bob","age":30},"active":true}' | moonjq.exe
jq> .user.name
"Bob"
jq> .user.age
30
jq> .active
true
```

### 示例会话 2: 数组操作

```bash
PS> echo '[1,2,3,4,5]' | moonjq.exe
jq> .[]
1
2
3
4
5
jq> .[] | select(. > 2)
3
4
5
jq> .[2]
3
```

### 示例会话 3: 复杂查询

```bash
PS> echo '{"users":[{"name":"Alice","age":25},{"name":"Bob","age":30}]}' | moonjq.exe
jq> .users
[{"name": "Alice", "age": 25}, {"name": "Bob", "age": 30}]
jq> .users[]
{"name": "Alice", "age": 25}
{"name": "Bob", "age": 30}
jq> .users[].name
"Alice"
"Bob"
```

### 支持的查询

- **恒等**: `.` - 返回整个 JSON
- **字段访问**: `.name`, `.user.age`
- **数组索引**: `.[0]`, `.[1]`
- **数组迭代**: `.[]`
- **管道**: `.users | .[] | .name`
- **过滤**: `.[] | select(. > 10)`
- **比较**: `==`, `!=`, `>`, `<`, `>=`, `<=`

### 退出程序

在 `JSON>` 或 `Query>` 提示符下输入 `exit()` 即可退出。

## 非交互式使用

如果提供命令行参数，程序将以非交互模式运行：

```bash
# 从管道读取
echo '{"name":"Alice"}' | moonjq.exe ".name"

# 从文件读取
moonjq.exe ".users[]" data.json

# 使用 JSON 字符串
moonjq.exe "." '{"test":123}'
```
