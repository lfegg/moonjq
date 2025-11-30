# 算术运算功能

MoonJQ 支持基本的四则运算，并对不同数据类型提供了特殊的运算语义。

## 运算符

- `+` 加法 / 连接
- `-` 减法 / 差集
- `*` 乘法 / 重复 / 合并
- `/` 除法 / 分割
- `%` 取模

## 运算符优先级

1. `*`, `/`, `%` (乘、除、模) - 最高优先级
2. `+`, `-` (加、减)
3. 比较运算符 (`==`, `!=`, `>`, `<`, `>=`, `<=`)
4. 管道 (`|`)
5. 逗号 (`,`) - 最低优先级

示例：
```bash
2 + 3 * 4   # 结果: 14 (先计算 3*4=12, 再加 2)
10 - 2 * 3  # 结果: 4 (先计算 2*3=6, 再用 10 减去)
```

## 数字运算

### 加法 `+`
```bash
echo 'null' | jq '1 + 2'
# 输出: 3

echo '{"a": 10, "b": 5}' | jq '.a + .b'
# 输出: 15
```

### 减法 `-`
```bash
echo 'null' | jq '10 - 3'
# 输出: 7
```

### 乘法 `*`
```bash
echo 'null' | jq '4 * 5'
# 输出: 20
```

### 除法 `/`
```bash
echo 'null' | jq '20 / 4'
# 输出: 5

echo 'null' | jq '10 / 0'
# 输出: null (除以零返回 null)
```

### 取模 `%`
```bash
echo 'null' | jq '10 % 3'
# 输出: 1
```

## 字符串运算

### 字符串连接 `+`
```bash
echo 'null' | jq '"hello" + " " + "world"'
# 输出: "hello world"

echo '{"first": "John", "last": "Doe"}' | jq '.first + " " + .last'
# 输出: "John Doe"
```

### 字符串重复 `*`
```bash
echo 'null' | jq '"ab" * 3'
# 输出: "ababab"

echo 'null' | jq '3 * "xy"'
# 输出: "xyxyxy"
```

## 数组运算

### 数组连接 `+`
```bash
echo 'null' | jq '[1, 2] + [3, 4]'
# 输出: [1, 2, 3, 4]

echo '{"a": [1, 2], "b": [3, 4]}' | jq '.a + .b'
# 输出: [1, 2, 3, 4]
```

### 数组差集 `-`
从左侧数组中移除右侧数组中存在的元素：

```bash
echo 'null' | jq '[1, 2, 3, 4] - [2, 4]'
# 输出: [1, 3]
```

## 对象运算

### 对象合并 `+`
右侧对象的字段会覆盖左侧对象的同名字段：

```bash
echo 'null' | jq '{"a": 1, "b": 2} + {"b": 3, "c": 4}'
# 输出: {"a": 1, "b": 3, "c": 4}
```

### 对象合并 `*`
类似于 `+`，递归合并两个对象：

```bash
echo 'null' | jq '{"a": 1} * {"b": 2}'
# 输出: {"a": 1, "b": 2}
```

## 复杂表达式

算术运算可以与其他 jq 功能组合使用：

```bash
# 管道中的运算
echo '[1, 2, 3]' | jq '.[] | . * 2'
# 输出: 2, 4, 6

# 条件过滤 + 运算
echo '[1, 2, 3, 4, 5]' | jq '.[] | select(. > 2) | . + 10'
# 输出: 13, 14, 15

# 数组构造 + 运算
echo '{"x": 5, "y": 3}' | jq '[.x + .y, .x - .y, .x * .y]'
# 输出: [8, 2, 15]
```

## 类型不匹配

当运算数类型不匹配时，结果通常为 `null`：

```bash
echo 'null' | jq '"text" - 5'
# 输出: null

echo 'null' | jq '[1, 2] * "string"'
# 输出: null
```

## 实际应用示例

### 计算总价
```bash
echo '{"items": [{"price": 10}, {"price": 20}, {"price": 30}]}' | jq '.items | map(.price) | add'
# 注意: 这里需要 add 函数（未实现），目前可以用管道实现
```

### 构造完整名称
```bash
echo '{"users": [{"first": "Alice", "last": "Smith"}, {"first": "Bob", "last": "Jones"}]}' | jq '.users | .[] | .first + " " + .last'
# 输出:
# "Alice Smith"
# "Bob Jones"
```

### 数据转换
```bash
echo '{"value": 100}' | jq '{original: .value, doubled: (.value * 2), half: (.value / 2)}'
# 输出: {"original": 100, "doubled": 200, "half": 50}
```

## 测试

所有算术运算功能都经过单元测试验证：
- `src/arithmetic_test.mbt` - 包含 12 个测试用例
- 测试覆盖：数字运算、字符串操作、数组操作、运算符优先级、除零处理等

运行测试：
```powershell
moon test
```
