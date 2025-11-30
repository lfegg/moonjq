# 测试目录说明

## 测试脚本

### 主要脚本

- **`test_all.ps1`** - 综合功能测试套件，测试所有核心功能
- **`demo_shell.ps1`** - Shell 命令风格示例演示
- **`demo_file.ps1`** - 文件读取功能示例演示
- **`demo_advanced.ps1`** - 高级功能演示（切片、递归下降、可选操作符）

### 运行测试

```powershell
# 运行所有测试
.\tests\test_all.ps1

# 查看 Shell 风格示例
.\tests\demo_shell.ps1

# 查看文件读取示例
.\tests\demo_file.ps1

# 查看高级功能示例
.\tests\demo_advanced.ps1
```

## 根目录脚本

- **`run.ps1`** - 快速启动 REPL 的便捷脚本
