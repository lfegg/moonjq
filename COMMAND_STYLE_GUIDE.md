# Command-Style Input Guide

## 功能说明

现在 moonjq 的 REPL 支持两种输入方式:

### 1. 传统 jq 查询模式
直接输入查询表达式,使用从 stdin 读取或默认的 JSON 数据:

```
jq> .
jq> .name
jq> .[] | select(. > 2)
```

### 2. Shell 命令模式 (新功能!)
在 REPL 中输入完整的 shell 风格命令:

```
jq> echo '{"name":"John","age":30}' | jq '.'
{
  "name": "John",
  "age": 30
}

jq> echo '[1,2,3,4,5]' | jq '.[] | select(. > 2)'
3
4
5

jq> echo '{"users":[{"name":"Alice"},{"name":"Bob"}]}' | jq '.users[0].name'
"Alice"
```

## 实现细节

使用了 MoonBit 的字符串切片方法 `.view(start_offset, end_offset)`:

```moonbit
// 正确的切片用法
let substring = str.view(start_offset=0, end_offset=5).to_string()

// 错误的用法 (会导致编译错误)
let wrong = str[0:5]!.to_string()  // ❌
```

## 构建和运行

```powershell
# 构建
moon build --target native

# 运行 REPL
echo "null" | .\target\native\release\build\src\src.exe

# 在 REPL 中测试
jq> echo '{"hello":"world"}' | jq '.'
```

## 技术要点

1. **命令解析**: 识别管道符 `|` 并分割命令
2. **引号处理**: 支持单引号和双引号包裹的 JSON 字符串
3. **向后兼容**: 如果不是管道命令,退回到传统查询模式
