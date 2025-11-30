# 文件读取功能使用指南

## ✅ 功能已实现

moonjq 现在支持在 REPL 中直接读取 JSON 文件！

## 使用方法

### 1. 在 REPL 中读取文件

```bash
# 启动 REPL
.\target\native\release\build\src\src.exe

jq> jq '.user.name' test.json
"Tom"

jq> jq '.user.skills' test.json
["Java", "JavaScript", "Go"]

jq> jq '.active' test.json
true

jq> exit
Goodbye!
```

### 2. 命令行直接读取文件

```bash
.\target\native\release\build\src\src.exe ".user.name" test.json
"Tom"
```

### 3. 支持的所有输入方式

```bash
# 方式1: echo JSON | jq 查询
jq> echo '{"x":123}' | jq '.x'
123

# 方式2: jq 查询 文件名
jq> jq '.user.name' test.json
"Tom"

# 方式3: 直接查询 (使用默认 null)
jq> .
null

# 方式4: 退出
jq> exit()
Goodbye!
```

## 已知限制

由于解析器的实现限制，`.field[]` 语法目前不能正确工作，需要使用显式管道：

```bash
# ❌ 不工作
jq> jq '.projects[]' test.json

# ✅ 解决方法：使用显式管道
jq> jq '.projects | .[]' test.json
{"title": "Web App", "stars": 120}
{"title": "CLI Tool", "stars": 80}
```

## 测试示例

使用提供的 test.json 文件：

```bash
# 读取嵌套字段
jq> jq '.user.name' test.json
"Tom"

# 读取数组
jq> jq '.user.skills' test.json
["Java", "JavaScript", "Go"]

# 使用管道和筛选
jq> jq '.projects | .[] | select(.stars > 100)' test.json
{"title": "Web App", "stars": 120}
```

## 实现细节

1. **JsonSource 枚举**: 区分 JSON 字符串和文件名
2. **优先级判断**: `jq 'query' file` 优先于 `echo ... | jq ...`
3. **文件读取**: 使用 `@fs.read_file_to_string()` 读取文件内容
4. **错误处理**: 文件不存在或读取失败时显示友好错误信息
