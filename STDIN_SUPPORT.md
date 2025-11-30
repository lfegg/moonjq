# MoonJQ 标准输入支持

## 功能说明

MoonJQ 现在支持从标准输入 (stdin) 读取 JSON 数据，通过 C FFI 实现。

## 实现的函数

### 1. `read_line_from_stdin() -> String?`
从标准输入读取一行。
- 返回 `Some(line)` - 成功读取一行
- 返回 `None` - EOF 或错误

### 2. `read_all_stdin() -> String`
从标准输入读取所有数据直到 EOF。
- 返回完整的输入字符串

### 3. `has_stdin_data() -> Bool`
检查标准输入是否有可用数据（非阻塞）。
- 返回 `true` - 有数据可用
- 返回 `false` - 无数据

## 使用示例

### 1. 从管道读取 JSON

```bash
echo '{"name": "John", "age": 30}' | moonjq ".name"
# 输出: "John"
```

### 2. 从文件重定向读取

```bash
moonjq ".[]" < array.json
```

### 3. 交互式 REPL

```bash
moonjq
# 进入交互模式，输入查询表达式
moonjq> .
moonjq> exit()
```

### 4. 使用命令行参数

```bash
# 直接传入 JSON 字符串
moonjq "." '{"a": 1}'

# 读取文件
moonjq ".a" data.json
```

## 架构说明

### 文件结构

- `src/io.mbt` - IO 接口函数，平台无关
- `src/io_ffi.native.mbt` - Native backend 的 C FFI 声明
- `src/io_ffi.wasm-gc.mbt` - WASM backend 的存根实现
- `src/io.c` - C 语言实现的底层 IO 函数

### Backend 支持

- **Native Backend**: 完整支持标准输入，通过 C FFI 调用系统函数
- **WASM Backend**: 提供存根实现，默认返回无数据（WASM 环境通常无 stdin）

### C FFI 实现

C 代码实现了三个函数：
1. `fgets_wrapper` - 使用 `fgets()` 读取一行
2. `read_stdin_wrapper` - 使用 `fread()` 读取数据块
3. `stdin_has_data` - 平台特定的非阻塞检查
   - Windows: 使用 `PeekNamedPipe` 或 `GetNumberOfConsoleInputEvents`
   - Unix/Linux: 使用 `select()` 系统调用

## 编译和运行

### 编译为 Native Binary

```bash
# 清理旧的构建
moon clean

# 构建 native 版本
moon build --target native

# 运行
echo '{"test": 123}' | ./target/native/release/build/src/src.exe "."
```

### 运行测试

```bash
moon test
```

## 技术细节

### 内存管理
- 使用 MoonBit 的 `Bytes` 类型作为缓冲区
- 自动处理内存分配和释放
- 缓冲区大小：读取行 4KB，读取流 8KB

### 字符编码
- 支持 UTF-8 编码
- 使用 `Int::unsafe_to_char` 转换字节到字符

### 错误处理
- EOF 返回 `None` 或空字符串
- IO 错误统一作为 EOF 处理

## 未来改进

1. 支持更大的输入流（当前受内存限制）
2. 添加超时控制
3. 支持二进制数据流
4. 改进 WASM backend 支持（通过 WASI）
