# MoonJQ 改进建议

## 优先级分类

### 🔴 高优先级（建议立即实现）

#### 1. 布尔运算符 ⬅️ **开始实现**
**功能**: `and`, `or`, `not`
**理由**: 条件表达式中经常需要组合多个条件
**示例**:
```moonbit
if .age > 18 and .status == "active" then "ok" else "no" end
if .x > 0 or .y > 0 then "positive" else "negative" end
if not(.deleted) then . else empty end
```

#### 2. 空值合并运算符 ⬅️ **开始实现**
**功能**: `//` (alternative operator)
**理由**: 处理缺失值的常见模式
**示例**:
```moonbit
.name // "Unknown"          # 如果 name 为 null，使用默认值
.config.timeout // 30       # 配置缺失时使用默认值
```

#### 3. 类型转换函数 ⬅️ **开始实现**
**功能**: `tostring`, `tonumber`
**理由**: 数据处理中经常需要类型转换
**示例**:
```moonbit
.id | tostring              # 数字转字符串
.age | tonumber             # 字符串转数字
```

#### 4. 更多数组函数 ⬅️ **开始实现**
**功能**: `reverse`, `flatten`, `first`, `last`
**理由**: 数组操作的基本需求
**已实现**: ✅ `map`, `add`, `min`, `max`, `sort`, `sort_by`, `group_by`, `unique`, `unique_by`
**待实现**: `reverse`, `flatten`, `first`, `last`, `range`, `nth`, `indices`, `index`
**示例**:
```moonbit
[1, 2, 3] | reverse         # [3, 2, 1]
[[1, 2], [3, 4]] | flatten  # [1, 2, 3, 4]
[1, 2, 3] | first          # 1
[1, 2, 3] | last           # 3
```

### 🟡 中优先级（有价值但不紧急）

#### 5. 对象转换函数
**功能**: `to_entries`, `from_entries`, `with_entries`
**示例**:
```moonbit
{"a": 1, "b": 2} | to_entries
# [{"key": "a", "value": 1}, {"key": "b", "value": 2}]

with_entries(.value = .value * 2)
# 将所有值翻倍
```

#### 6. 更多字符串函数
**功能**: `ascii_downcase`, `ascii_upcase`, `test`, `match`
**示例**:
```moonbit
"Hello" | ascii_downcase    # "hello"
"hello" | ascii_upcase      # "HELLO"
"test123" | test("\\d+")    # true
```

#### 7. 删除和修改操作
**功能**: `del`, `empty`
**示例**:
```moonbit
{"a": 1, "b": 2} | del(.a)  # {"b": 2}
.[] | select(. > 10) // empty  # 过滤并丢弃小于等于10的值
```

#### 8. 数学函数
**功能**: `floor`, `ceil`, `round`, `abs`, `sqrt`
**示例**:
```moonbit
3.7 | floor                 # 3
3.2 | ceil                  # 4
3.5 | round                 # 4
-5 | abs                    # 5
16 | sqrt                   # 4
```

### 🟢 低优先级（高级功能）

#### 9. 正则表达式支持
**功能**: `test`, `match`, `capture`, `sub`, `gsub`, `splits`
**注意**: 需要正则表达式库支持

#### 10. 递归和循环
**功能**: `walk`, `until`, `while`, `repeat`, `recurse_down`

#### 11. 路径操作
**功能**: `path`, `getpath`, `setpath`, `delpaths`

#### 12. 格式化输出
**功能**: `@json`, `@csv`, `@base64`, `@uri`

#### 13. 日期时间
**功能**: `now`, `strftime`, `strptime`

## 代码质量改进

### 1. 错误处理增强
- [ ] 添加行号和列号到错误信息
- [ ] 提供更详细的错误描述
- [ ] 添加错误恢复机制

### 2. 性能优化
- [ ] 减少中间数组分配
- [ ] 考虑使用迭代器模式
- [ ] 优化递归下降的性能

### 3. 测试覆盖
- [ ] 添加边界条件测试
- [ ] 添加性能基准测试
- [ ] 添加模糊测试

### 4. 文档改进
- [ ] 添加 API 文档
- [ ] 添加更多使用示例
- [ ] 创建交互式教程

## 实现顺序建议

1. **第一阶段** (1-2天):
   - 布尔运算符 (and, or, not)
   - 空值合并运算符 (//)
   - 类型转换 (tostring, tonumber)

2. **第二阶段** (2-3天):
   - 更多数组函数 (reverse, flatten, first, last, range)
   - 更多字符串函数 (ascii_downcase, ascii_upcase)
   - 数学函数 (floor, ceil, round, abs, sqrt)

3. **第三阶段** (3-5天):
   - 对象转换 (to_entries, from_entries, with_entries)
   - 删除操作 (del, empty)
   - 对象/数组的 values 函数

4. **第四阶段** (根据需求):
   - 正则表达式支持
   - 高级递归操作
   - 格式化输出

## 注意事项

### 向后兼容性
- 所有新功能应该是向后兼容的
- 现有测试应该继续通过
- 新功能应该有相应的测试

### 代码风格
- 遵循 MoonBit 的编码规范
- 使用块风格组织代码 (///|)
- 保持与现有代码一致的风格

### 测试要求
- 每个新功能至少 3 个测试用例
- 包括正常情况和边界情况
- 使用快照测试验证输出
