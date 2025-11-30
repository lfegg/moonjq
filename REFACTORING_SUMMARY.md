# 重构说明

## 完成的改动

### 1. 简化主函数 (`src/main.mbt`)

**之前**: 支持命令行参数模式和 REPL 模式
```moonbit
fn main {
  let args = @sys.get_cli_args()
  if args.length() < 2 {
    repl()
  } else {
    // 处理命令行参数...
  }
}
```

**之后**: 仅保留 REPL 模式
```moonbit
fn main {
  repl()
}
```

### 2. 移除的代码

- ❌ 命令行参数解析逻辑
- ❌ `print_usage()` 函数
- ❌ 从命令行参数读取查询和 JSON 的代码
- ❌ `@sys.exit()` 调用

### 3. 清理依赖 (`src/moon.pkg.json`)

- ❌ 移除未使用的 `moonbitlang/x/sys` 导入

### 4. 更新文档 (`README.md`)

- ✅ 更新特性列表，突出 REPL 和交互式功能
- ✅ 移除命令行模式的使用说明
- ✅ 添加 REPL 的详细使用示例
- ✅ 更新项目结构说明
- ✅ 添加相关文档链接

## 保留的功能

✅ 交互式 REPL
✅ Shell 命令风格: `echo '...' | jq '...'`
✅ 文件读取: `jq '.query' filename.json`
✅ 直接查询: 输入 jq 表达式
✅ 退出命令: `exit` 或 `exit()`
✅ 所有 jq 核心功能 (管道、过滤、选择、构造等)

## 启动方式

```bash
# 开发模式
moon run --target native src

# 直接运行编译后的可执行文件
.\target\native\release\build\src\src.exe
```

## 测试验证

所有 REPL 功能测试通过：
- ✅ Shell 命令风格解析
- ✅ 文件读取功能
- ✅ 数组过滤和查询
- ✅ 退出命令

## 代码简化成果

- 主函数从 ~55 行减少到 ~3 行
- 移除 ~75 行命令行参数处理代码
- 代码更专注于 REPL 交互体验
- 更符合 jq 的交互式使用习惯
