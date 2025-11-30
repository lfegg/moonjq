# PowerShell 使用指南

## 关于字符串和转义字符

在 PowerShell 中使用 MoonJQ 时，需要注意字符串的引号和转义规则。

## 引号规则

### 单引号 `'...'`
- 字面字符串，内部内容不会被解析
- 最简单，推荐用于包含 JSON 数据
- 要包含单引号本身，使用两个单引号 `''`

### 双引号 `"..."`
- 可解析字符串，内部会进行变量替换和转义
- 需要转义特殊字符
- 反引号 `` ` `` 是转义字符

## 常见场景

### 1. 简单查询（推荐方式）

```powershell
# 使用单引号包裹整个命令
"echo '{\"x\":1}' | jq '.x'" | .\moonjq.exe

# 或者使用变量
$cmd = 'echo ''{"x":1}'' | jq ''.x'''
$cmd | .\moonjq.exe
```

### 2. 包含双引号的查询

**问题示例**：
```powershell
# ❌ 错误：会导致解析错误
"jq '.name + " Smith"' file.json"
```

**解决方案 A** - 使用单引号和双单引号：
```powershell
# ✅ 正确
$cmd = 'jq ''.name + " Smith"'' file.json'
$cmd | .\moonjq.exe
```

**解决方案 B** - 使用反引号转义：
```powershell
# ✅ 正确
"jq '.name + `" Smith`"' file.json" | .\moonjq.exe
```

**解决方案 C** - 使用 here-string：
```powershell
# ✅ 正确
$cmd = @'
jq '.name + " Smith"' file.json
'@
$cmd | .\moonjq.exe
```

### 3. 复杂 JSON 数据

**推荐方式** - 使用单引号和双单引号：
```powershell
$cmd = 'echo ''{"name":"John","skills":["js","python"]}'' | jq ''.skills[]'''
$cmd | .\moonjq.exe
```

**或者分步处理**：
```powershell
$json = '{"name":"John","skills":["js","python"]}'
$query = '.skills[]'
"echo '$json' | jq '$query'" | .\moonjq.exe
```

### 4. 字符串运算

```powershell
# 字符串连接
$cmd = 'echo ''null'' | jq ''"hello" + " " + "world"'''
$cmd | .\moonjq.exe

# 字符串重复
$cmd = 'echo ''null'' | jq ''"ab" * 3'''
$cmd | .\moonjq.exe
```

### 5. 数组和对象

```powershell
# 数组运算
"echo 'null' | jq '[1,2] + [3,4]'" | .\moonjq.exe

# 对象合并
$cmd = 'echo ''null'' | jq ''{"a":1} + {"b":2}'''
$cmd | .\moonjq.exe
```

## 转义字符对照表

| 字符 | PowerShell 双引号内 | PowerShell 单引号内 |
|------|---------------------|---------------------|
| `"` | `` `" `` | `"` (直接使用) |
| `'` | `'` (直接使用) | `''` (两个单引号) |
| `` ` `` | ``` `` ``` | `` ` `` (直接使用) |
| `$` | `` `$ `` | `$` (直接使用) |
| `\` | `\` (直接使用) | `\` (直接使用) |

## 实用技巧

### 技巧 1: 使用变量简化复杂命令

```powershell
$json = '{"user":{"name":"Alice","age":30}}'
$query = '.user.name'
"echo '$json' | jq '$query'" | .\moonjq.exe
```

### 技巧 2: 使用 Here-String 处理多行

```powershell
$cmd = @'
echo '{"data":[1,2,3,4,5]}' | jq '.data | .[] | . * 2'
'@
$cmd | .\moonjq.exe
```

### 技巧 3: 从文件读取避免转义问题

```powershell
# 将 JSON 保存到文件
'{"name":"John","age":30}' | Out-File -Encoding utf8 test.json

# 直接读取文件
"jq '.name' test.json" | .\moonjq.exe
```

### 技巧 4: 使用函数封装

```powershell
function Invoke-JQ {
    param(
        [string]$Query,
        [string]$Json = 'null',
        [string]$File
    )
    
    if ($File) {
        "jq '$Query' $File" | .\target\native\release\build\src\src.exe
    } else {
        "echo '$Json' | jq '$Query'" | .\target\native\release\build\src\src.exe
    }
}

# 使用示例
Invoke-JQ -Query '.name' -File 'test.json'
Invoke-JQ -Query '1 + 2' -Json 'null'
```

## 常见错误和解决方法

### 错误 1: 意外的标记

```powershell
# ❌ 错误
"jq '.name + "test"' file.json"
# 错误信息: 表达式或语句中包含意外的标记

# ✅ 解决
$cmd = 'jq ''.name + "test"'' file.json'
$cmd | .\moonjq.exe
```

### 错误 2: 变量未展开

```powershell
# ❌ 问题：单引号内变量不展开
$query = '.name'
'echo ''{}'' | jq ''$query''' | .\moonjq.exe
# 结果: 查询字面上是 "$query" 而不是 ".name"

# ✅ 解决：使用双引号或字符串拼接
$query = '.name'
"echo '{}' | jq '$query'" | .\moonjq.exe
```

### 错误 3: 反斜杠路径问题

```powershell
# Windows 路径
$file = "C:\data\test.json"

# ❌ 可能有问题
"jq '.name' $file" | .\moonjq.exe

# ✅ 使用正斜杠或转义
$file = "C:/data/test.json"
"jq '.name' $file" | .\moonjq.exe
```

## 调试技巧

### 1. 打印实际命令

```powershell
$cmd = 'echo ''{"x":1}'' | jq ''.x'''
Write-Host "Command: $cmd"
$cmd | .\moonjq.exe
```

### 2. 分步测试

```powershell
# 先测试 JSON 是否正确
$json = '{"x":1}'
Write-Host "JSON: $json"

# 再测试查询
$query = '.x'
Write-Host "Query: $query"

# 组合测试
"echo '$json' | jq '$query'" | .\moonjq.exe
```

### 3. 使用 -WhatIf (如果适用)

```powershell
# 对于自定义函数，可以添加 -WhatIf 支持
function Invoke-JQ {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Query, [string]$Json)
    
    $cmd = "echo '$Json' | jq '$Query'"
    if ($PSCmdlet.ShouldProcess($cmd)) {
        $cmd | .\moonjq.exe
    }
}

# 预览命令
Invoke-JQ -Query '.x' -Json '{"x":1}' -WhatIf
```

## 快速参考

```powershell
# 基础用法
"echo 'null' | jq '1 + 2'" | .\moonjq.exe

# 字段访问
"jq '.name' file.json" | .\moonjq.exe

# 复杂查询（使用变量）
$cmd = 'echo ''{"a":1}'' | jq ''.a + 10'''
$cmd | .\moonjq.exe

# 管道操作
"echo '[1,2,3]' | jq '.[] | . * 2'" | .\moonjq.exe

# 文件读取
"jq '.users[] | .name' data.json" | .\moonjq.exe
```

## 推荐的编码风格

1. **优先使用单引号**包裹命令字符串
2. **用变量**存储复杂的 JSON 和查询
3. **用函数**封装常用操作
4. **分步调试**复杂命令
5. **将 JSON 数据保存到文件**以避免转义问题

## 示例脚本

参考项目中的示例脚本：
- `tests/demo_shell.ps1` - Shell 命令风格示例
- `tests/demo_file.ps1` - 文件读取示例
- `tests/demo_advanced.ps1` - 高级功能示例
- `tests/demo_arithmetic.ps1` - 算术运算示例

这些脚本展示了正确的转义和引号使用方式。
