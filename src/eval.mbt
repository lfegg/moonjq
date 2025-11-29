///|
/// 对给定的 JSON 数据执行查询，并返回结果数组。
///
/// 参数:
/// * `json`: 输入的 JSON 数据。
/// * `query`: 要执行的查询 AST。
///
/// 返回:
/// * `Array[Json]`: 查询结果数组。jq 的查询可能会产生多个结果（例如迭代器），所以返回数组。
pub fn eval(json : Json, query : Query) -> Array[Json] {
  match query {
    // 恒等查询 '.'，直接返回输入本身
    Identity => [json]

    // 字段访问 '.key'
    Field(key) =>
      match json {
        Object(m) =>
          match m.get(key) {
            Some(v) => [v]
            None => [Json::Null] // 键不存在时返回 null
          }
        _ => [Json::Null] // 非对象类型访问字段返回 null
      }

    // 数组索引 '[idx]'
    Index(idx) =>
      match json {
        Array(arr) =>
          if idx >= 0 && idx < arr.length() {
            [arr[idx]]
          } else {
            [Json::Null] // 索引越界返回 null
          }
        _ => [Json::Null] // 非数组类型索引返回 null
      }

    // 切片 '[start:end]'
    Slice(start_opt, end_opt) =>
      match json {
        Array(arr) => {
          let len = arr.length()
          // 处理负数索引和边界
          let start = match start_opt {
            Some(s) => if s < 0 { len + s } else { s }
            None => 0
          }
          let end = match end_opt {
            Some(e) => if e < 0 { len + e } else { e }
            None => len
          }
          // 确保索引在有效范围内
          let start = if start < 0 {
            0
          } else if start > len {
            len
          } else {
            start
          }
          let end = if end < 0 { 0 } else if end > len { len } else { end }
          // 确保 start <= end
          let end = if end < start { start } else { end }
          // 提取子数组
          let result = []
          for i = start; i < end; i = i + 1 {
            result.push(arr[i])
          }
          [Json::Array(result)]
        }
        String(s) => {
          let len = s.length()
          // 处理负数索引和边界
          let start = match start_opt {
            Some(st) => if st < 0 { len + st } else { st }
            None => 0
          }
          let end = match end_opt {
            Some(e) => if e < 0 { len + e } else { e }
            None => len
          }
          // 确保索引在有效范围内
          let start = if start < 0 {
            0
          } else if start > len {
            len
          } else {
            start
          }
          let end = if end < 0 { 0 } else if end > len { len } else { end }
          // 确保 start <= end
          let end = if end < start { start } else { end }
          // 提取子字符串
          let result = if start == end {
            ""
          } else {
            s.view(start_offset=start, end_offset=end).to_string()
          }
          [Json::String(result)]
        }
        _ => [Json::Null] // 其他类型返回 null
      }

    // 迭代器 '.[]'
    Iterator =>
      match json {
        Array(arr) => arr // 数组展开为元素序列
        Object(obj) => {
          let res = []
          for v in obj.values() {
            res.push(v)
          }
          res // 对象展开为值序列
        }
        _ => [] // 其他类型无法迭代，返回空序列
      }

    // 递归下降 '..'
    // 返回当前值以及所有嵌套的子值
    Recurse => {
      fn recurse_helper(j : Json, results : Array[Json]) -> Unit {
        results.push(j)
        match j {
          Array(arr) =>
            for item in arr {
              recurse_helper(item, results)
            }
          Object(obj) =>
            for v in obj.values() {
              recurse_helper(v, results)
            }
          _ => () // 基本类型没有子值
        }
      }

      let results = []
      recurse_helper(json, results)
      results
    }

    // 可选操作符 '?'
    // 安全访问：如果查询失败或返回空结果，返回 null 而不是报错
    Optional(q) => {
      let results = eval(json, q)
      if results.length() == 0 {
        [Json::Null] // 如果没有结果，返回 null
      } else {
        results // 否则返回正常结果
      }
    }

    // 字面量，如 1, "string", true
    Literal(v) => [v]

    // 二元操作，如 ==, !=, >, <, +, -, *, /
    Binary(op, left, right) => {
      let l_res = eval(json, left)
      let r_res = eval(json, right)
      let res = []
      // 笛卡尔积：左侧每个结果与右侧每个结果进行操作
      for l in l_res {
        for r in r_res {
          match op {
            // 比较操作符返回布尔值
            Eq | Neq | Gt | Lt | Gte | Lte =>
              res.push(Json::Bool(compare(op, l, r)))
            // 算术操作符返回数值或null
            Add | Sub | Mul | Div =>
              match (l, r) {
                (Number(a), Number(b)) => {
                  let result = match op {
                    Add => a + b
                    Sub => a - b
                    Mul => a * b
                    Div => if b == 0.0 { 0.0 / 0.0 } else { a / b } // NaN for division by zero
                    _ => 0.0 // unreachable
                  }
                  res.push(Json::Number(result))
                }
                _ => res.push(Json::Null) // 非数值类型返回 null
              }
          }
        }
      }
      res
    }

    // 选择/过滤 'select(cond)'
    Select(cond) => {
      let cond_res = eval(json, cond)
      for c in cond_res {
        if is_truthy(c) {
          return [json] // 如果条件为真，保留当前输入
        }
      }
      [] // 否则丢弃
    }

    // 获取长度 'length'
    Length =>
      match json {
        String(s) => [Json::Number(s.length().to_double())]
        Array(arr) => [Json::Number(arr.length().to_double())]
        Object(obj) => [Json::Number(obj.length().to_double())]
        Null => [Json::Number(0.0)]
        Number(n) => [Json::Number(n)]
        _ => [Json::Null] // 其他类型返回 null (jq 会报错，这里简化处理)
      }

    // 获取键名 'keys'
    Keys =>
      match json {
        Object(obj) => {
          let keys = []
          for k in obj.keys() {
            keys.push(k)
          }
          // 简单的冒泡排序，确保键名有序
          for i = 0; i < keys.length(); i = i + 1 {
            for j = 0; j < keys.length() - 1 - i; j = j + 1 {
              if keys[j] > keys[j + 1] {
                let temp = keys[j]
                keys[j] = keys[j + 1]
                keys[j + 1] = temp
              }
            }
          }
          let res = []
          for k in keys {
            res.push(Json::String(k))
          }
          [Json::Array(res)]
        }
        Array(arr) => {
          let res = []
          for i = 0; i < arr.length(); i = i + 1 {
            res.push(Json::Number(i.to_double()))
          }
          [Json::Array(res)]
        }
        _ => [Json::Null] // 其他类型返回 null
      }

    // 获取类型 'type'
    Type =>
      match json {
        Null => [Json::String("null")]
        Bool(_) => [Json::String("boolean")]
        Number(_) => [Json::String("number")]
        String(_) => [Json::String("string")]
        Array(_) => [Json::String("array")]
        Object(_) => [Json::String("object")]
      }

    // 检查对象是否有指定键 'has(key)'
    Has(key) =>
      match json {
        Object(obj) => [Json::Bool(obj.contains(key))]
        _ => [Json::Bool(false)] // 非对象类型始终返回 false
      }

    // 检查值是否在数组中 'in(array)'
    In(array_query) => {
      let array_results = eval(json, array_query)
      // 对于每个查询结果（应该是数组），检查当前值是否在其中
      for array_val in array_results {
        match array_val {
          Array(arr) =>
            for item in arr {
              if item == json {
                return [Json::Bool(true)]
              }
            }
          _ => ()
        }
      }
      [Json::Bool(false)]
    }

    // 条件表达式 'if cond then expr1 else expr2 end'
    IfThenElse(cond, then_expr, else_expr) => {
      let cond_results = eval(json, cond)
      // 如果条件为真（任何一个结果为真值），执行 then 分支
      for c in cond_results {
        if is_truthy(c) {
          return eval(json, then_expr)
        }
      }
      // 否则执行 else 分支
      eval(json, else_expr)
    }

    // 逻辑与 'a and b'
    And(left, right) => {
      let left_results = eval(json, left)
      for l in left_results {
        if not(is_truthy(l)) {
          return [Json::Bool(false)]
        }
      }
      let right_results = eval(json, right)
      for r in right_results {
        if not(is_truthy(r)) {
          return [Json::Bool(false)]
        }
      }
      [Json::Bool(true)]
    }

    // 逻辑或 'a or b'
    Or(left, right) => {
      let left_results = eval(json, left)
      for l in left_results {
        if is_truthy(l) {
          return [Json::Bool(true)]
        }
      }
      let right_results = eval(json, right)
      for r in right_results {
        if is_truthy(r) {
          return [Json::Bool(true)]
        }
      }
      [Json::Bool(false)]
    }

    // 逻辑非 'not(expr)'
    Not(expr) => {
      let results = eval(json, expr)
      for r in results {
        if is_truthy(r) {
          return [Json::Bool(false)]
        }
      }
      [Json::Bool(true)]
    }

    // 空值替代 'a // b'
    Alternative(left, right) => {
      let left_results = eval(json, left)
      // 如果左侧返回非 null 且非 false 的值，使用它
      for l in left_results {
        match l {
          Null | Bool(false) => continue
          _ => return [l]
        }
      }
      // 否则使用右侧的值
      eval(json, right)
    }

    // 类型转换：tostring
    ToString =>
      match json {
        String(_) => [json]
        Number(n) => [Json::String(n.to_string())]
        Bool(b) => [Json::String(b.to_string())]
        Null => [Json::String("null")]
        Array(_) => [Json::String(json.to_json_string())]
        Object(_) => [Json::String(json.to_json_string())]
      }

    // 类型转换：tonumber
    ToNumber =>
      match json {
        Number(_) => [json]
        String(s) => {
          // 尝试解析字符串为数字
          let parser = Parser::new(s)
          match parser.parse_number() {
            Ok(n) => [Json::Number(n)]
            Err(_) => [Json::Null] // 解析失败返回 null
          }
        }
        _ => [Json::Null]
      }

    // 数组函数：reverse
    Reverse =>
      match json {
        Array(arr) => {
          let result = []
          for i = arr.length() - 1; i >= 0; i = i - 1 {
            result.push(arr[i])
          }
          [Json::Array(result)]
        }
        _ => [Json::Null]
      }

    // 数组函数：flatten
    Flatten =>
      match json {
        Array(arr) => {
          let result = []
          for item in arr {
            match item {
              Array(sub) =>
                for elem in sub {
                  result.push(elem)
                }
              _ => result.push(item)
            }
          }
          [Json::Array(result)]
        }
        _ => [Json::Null]
      }

    // 数组函数：first
    First =>
      match json {
        Array(arr) => if arr.length() > 0 { [arr[0]] } else { [Json::Null] }
        _ => [Json::Null]
      }

    // 数组函数：last
    Last =>
      match json {
        Array(arr) =>
          if arr.length() > 0 {
            [arr[arr.length() - 1]]
          } else {
            [Json::Null]
          }
        _ => [Json::Null]
      }

    // 管道 '|'
    Pipe(left, right) => {
      let results = []
      let left_results = eval(json, left)
      // 将左侧的每个结果作为输入传递给右侧查询
      for val in left_results {
        let right_results = eval(val, right)
        results.append(right_results)
      }
      results
    }

    // 序列 ',' (逗号操作符)
    Sequence(left, right) => {
      let results = []
      results.append(eval(json, left))
      results.append(eval(json, right))
      results // 连接两个查询的结果
    }

    // 数组构造 '[ ... ]'
    ArrayConstructor(q) => {
      let results = eval(json, q)
      [Json::Array(results)] // 将查询结果收集到一个新数组中
    }

    // 对象构造 '{ key: val, ... }'
    ObjectConstructor(fields) => {
      // 递归函数处理对象字段的笛卡尔积组合
      // 因为每个字段的值可能是一个产生多个结果的查询
      fn cartesian(
        index : Int,
        current_obj : Map[String, Json],
      ) -> Array[Json] {
        if index >= fields.length() {
          return [Json::Object(current_obj)]
        }
        let (key, q) = fields[index]
        let val_results = eval(json, q)
        let results = []
        for val in val_results {
          let new_obj = Map::new()
          // 复制当前对象
          current_obj.each(fn(k, v) { new_obj.set(k, v) })
          new_obj.set(key, val)
          results.append(cartesian(index + 1, new_obj))
        }
        results
      }

      cartesian(0, Map::new())
    }

    // 数组操作：map(expr) - 对数组的每个元素应用表达式
    Map(expr) =>
      match json {
        Array(arr) => {
          let results = []
          for item in arr {
            let item_results = eval(item, expr)
            results.append(item_results)
          }
          [Json::Array(results)]
        }
        _ => [Json::Null] // 非数组类型返回 null
      }

    // 数组操作：add - 累加数组元素（数字求和，字符串拼接，数组连接）
    Add =>
      match json {
        Array(arr) => {
          if arr.length() == 0 {
            return [Json::Null]
          }
          // 根据第一个元素的类型决定累加方式
          match arr[0] {
            Number(_) => {
              let mut sum = 0.0
              for item in arr {
                match item {
                  Number(n) => sum = sum + n
                  _ => () // 忽略非数字
                }
              }
              [Json::Number(sum)]
            }
            String(_) => {
              let mut concat = ""
              for item in arr {
                match item {
                  String(s) => concat = concat + s
                  _ => () // 忽略非字符串
                }
              }
              [Json::String(concat)]
            }
            Array(_) => {
              let result = []
              for item in arr {
                match item {
                  Array(sub) =>
                    for elem in sub {
                      result.push(elem)
                    }
                  _ => () // 忽略非数组
                }
              }
              [Json::Array(result)]
            }
            _ => [Json::Null] // 不支持的类型
          }
        }
        _ => [Json::Null] // 非数组类型返回 null
      }

    // 数组操作：min - 找最小值
    Min =>
      match json {
        Array(arr) => {
          if arr.length() == 0 {
            return [Json::Null]
          }
          let mut min_val = arr[0]
          for i = 1; i < arr.length(); i = i + 1 {
            if compare_values(arr[i], min_val) < 0 {
              min_val = arr[i]
            }
          }
          [min_val]
        }
        _ => [Json::Null]
      }

    // 数组操作：max - 找最大值
    Max =>
      match json {
        Array(arr) => {
          if arr.length() == 0 {
            return [Json::Null]
          }
          let mut max_val = arr[0]
          for i = 1; i < arr.length(); i = i + 1 {
            if compare_values(arr[i], max_val) > 0 {
              max_val = arr[i]
            }
          }
          [max_val]
        }
        _ => [Json::Null]
      }

    // 数组操作：sort - 排序
    Sort =>
      match json {
        Array(arr) => {
          let sorted = []
          for item in arr {
            sorted.push(item)
          }
          // 冒泡排序
          for i = 0; i < sorted.length(); i = i + 1 {
            for j = 0; j < sorted.length() - 1 - i; j = j + 1 {
              if compare_values(sorted[j], sorted[j + 1]) > 0 {
                let temp = sorted[j]
                sorted[j] = sorted[j + 1]
                sorted[j + 1] = temp
              }
            }
          }
          [Json::Array(sorted)]
        }
        _ => [Json::Null]
      }

    // 数组操作：sort_by(expr) - 按表达式结果排序
    SortBy(expr) =>
      match json {
        Array(arr) => {
          // 创建 (原值, 排序键) 的配对数组
          let pairs : Array[(Json, Json)] = []
          for item in arr {
            let key_results = eval(item, expr)
            let key = if key_results.length() > 0 {
              key_results[0]
            } else {
              Json::Null
            }
            pairs.push((item, key))
          }
          // 冒泡排序
          for i = 0; i < pairs.length(); i = i + 1 {
            for j = 0; j < pairs.length() - 1 - i; j = j + 1 {
              let (_, key1) = pairs[j]
              let (_, key2) = pairs[j + 1]
              if compare_values(key1, key2) > 0 {
                let temp = pairs[j]
                pairs[j] = pairs[j + 1]
                pairs[j + 1] = temp
              }
            }
          }
          // 提取排序后的原值
          let sorted = []
          for pair in pairs {
            let (val, _) = pair
            sorted.push(val)
          }
          [Json::Array(sorted)]
        }
        _ => [Json::Null]
      }

    // 数组操作：group_by(expr) - 按表达式结果分组
    GroupBy(expr) =>
      match json {
        Array(arr) => {
          // 使用 Map 来分组，键是表达式结果，值是元素数组
          let groups : Map[String, Array[Json]] = Map::new()
          for item in arr {
            let key_results = eval(item, expr)
            let key = if key_results.length() > 0 {
              // 将键转换为字符串用于分组
              match key_results[0] {
                String(s) => s
                Number(n) => n.to_string()
                Bool(b) => b.to_string()
                Null => "null"
                _ => "complex" // 数组和对象统一归为一组
              }
            } else {
              "null"
            }
            match groups.get(key) {
              Some(group) => group.push(item)
              None => {
                let new_group = []
                new_group.push(item)
                groups.set(key, new_group)
              }
            }
          }
          // 将分组结果转换为数组的数组
          let result = []
          for group in groups.values() {
            result.push(Json::Array(group))
          }
          [Json::Array(result)]
        }
        _ => [Json::Null]
      }

    // 数组操作：unique - 去重
    Unique =>
      match json {
        Array(arr) => {
          let seen = []
          let result = []
          for item in arr {
            let mut found = false
            for s in seen {
              if s == item {
                found = true
                break
              }
            }
            if not(found) {
              seen.push(item)
              result.push(item)
            }
          }
          [Json::Array(result)]
        }
        _ => [Json::Null]
      }

    // 数组操作：unique_by(expr) - 按表达式结果去重
    UniqueBy(expr) =>
      match json {
        Array(arr) => {
          let seen_keys = []
          let result = []
          for item in arr {
            let key_results = eval(item, expr)
            let key = if key_results.length() > 0 {
              key_results[0]
            } else {
              Json::Null
            }
            let mut found = false
            for sk in seen_keys {
              if sk == key {
                found = true
                break
              }
            }
            if not(found) {
              seen_keys.push(key)
              result.push(item)
            }
          }
          [Json::Array(result)]
        }
        _ => [Json::Null]
      }

    // 字符串操作：split(sep) - 按分隔符分割字符串
    Split(sep) =>
      match json {
        String(s) => {
          let parts = []
          if sep == "" {
            // 空分隔符：分割为字符数组
            for i = 0; i < s.length(); i = i + 1 {
              parts.push(
                Json::String(
                  s.view(start_offset=i, end_offset=i + 1).to_string(),
                ),
              )
            }
          } else {
            // 非空分隔符：按分隔符分割
            let mut start = 0
            let sep_len = sep.length()
            for i = 0; i <= s.length() - sep_len; i = i + 1 {
              let substr = s
                .view(start_offset=i, end_offset=i + sep_len)
                .to_string()
              if substr == sep {
                parts.push(
                  Json::String(
                    s.view(start_offset=start, end_offset=i).to_string(),
                  ),
                )
                start = i + sep_len
                continue i + sep_len
              }
            }
            // 添加最后一部分
            parts.push(Json::String(s.view(start_offset=start).to_string()))
          }
          [Json::Array(parts)]
        }
        _ => [Json::Null]
      }

    // 字符串操作：join(sep) - 用分隔符连接数组元素
    Join(sep) =>
      match json {
        Array(arr) => {
          let mut result = ""
          for i = 0; i < arr.length(); i = i + 1 {
            match arr[i] {
              String(s) => {
                result = result + s
                if i < arr.length() - 1 {
                  result = result + sep
                }
              }
              _ => () // 忽略非字符串元素
            }
          }
          [Json::String(result)]
        }
        _ => [Json::Null]
      }

    // 字符串操作：startswith(prefix) - 检查是否以指定前缀开始
    StartsWith(prefix) =>
      match json {
        String(s) => {
          let prefix_len = prefix.length()
          if s.length() >= prefix_len {
            let start_part = s
              .view(start_offset=0, end_offset=prefix_len)
              .to_string()
            [Json::Bool(start_part == prefix)]
          } else {
            [Json::Bool(false)]
          }
        }
        _ => [Json::Bool(false)]
      }

    // 字符串操作：endswith(suffix) - 检查是否以指定后缀结束
    EndsWith(suffix) =>
      match json {
        String(s) => {
          let suffix_len = suffix.length()
          if s.length() >= suffix_len {
            let end_part = s
              .view(start_offset=s.length() - suffix_len)
              .to_string()
            [Json::Bool(end_part == suffix)]
          } else {
            [Json::Bool(false)]
          }
        }
        _ => [Json::Bool(false)]
      }

    // 字符串操作：contains(substr) - 检查是否包含子串
    Contains(substr) =>
      match json {
        String(s) => {
          let substr_len = substr.length()
          let mut found = false
          for i = 0; i <= s.length() - substr_len; i = i + 1 {
            let part = s
              .view(start_offset=i, end_offset=i + substr_len)
              .to_string()
            if part == substr {
              found = true
              break
            }
          }
          [Json::Bool(found)]
        }
        _ => [Json::Bool(false)]
      }

    // 字符串操作：ltrimstr(prefix) - 去除左侧前缀
    LTrimStr(prefix) =>
      match json {
        String(s) => {
          let prefix_len = prefix.length()
          if s.length() >= prefix_len {
            let start_part = s
              .view(start_offset=0, end_offset=prefix_len)
              .to_string()
            if start_part == prefix {
              [Json::String(s.view(start_offset=prefix_len).to_string())]
            } else {
              [json] // 不匹配，返回原字符串
            }
          } else {
            [json] // 字符串太短，返回原字符串
          }
        }
        _ => [Json::Null]
      }

    // 字符串操作：rtrimstr(suffix) - 去除右侧后缀
    RTrimStr(suffix) =>
      match json {
        String(s) => {
          let suffix_len = suffix.length()
          if s.length() >= suffix_len {
            let end_part = s
              .view(start_offset=s.length() - suffix_len)
              .to_string()
            if end_part == suffix {
              [
                Json::String(
                  s
                  .view(start_offset=0, end_offset=s.length() - suffix_len)
                  .to_string(),
                ),
              ]
            } else {
              [json] // 不匹配，返回原字符串
            }
          } else {
            [json] // 字符串太短，返回原字符串
          }
        }
        _ => [Json::Null]
      }
  }
}

///|
/// 判断 JSON 值是否为"真值"。
/// 在 jq 中，只有 false 和 null 是假值，其他（包括 0, "", []）都是真值。
fn is_truthy(j : Json) -> Bool {
  match j {
    Null => false
    Bool(false) => false
    _ => true
  }
}

///|
/// 执行比较操作。
fn compare(op : Op, l : Json, r : Json) -> Bool {
  match op {
    Eq => l == r
    Neq => l != r
    Gt => compare_values(l, r) > 0
    Lt => compare_values(l, r) < 0
    Gte => compare_values(l, r) >= 0
    Lte => compare_values(l, r) <= 0
    Add | Sub | Mul | Div => false // 算术操作符不应该在这里调用
  }
}

///|
/// 比较两个 JSON 值的大小。
/// 返回值: -1 (l < r), 0 (l == r), 1 (l > r)
/// jq 的排序规则: null < false < true < number < string < array < object
fn compare_values(l : Json, r : Json) -> Int {
  match (l, r) {
    (Number(a), Number(b)) => if a < b { -1 } else if a > b { 1 } else { 0 }
    (String(a), String(b)) => if a < b { -1 } else if a > b { 1 } else { 0 }
    (Bool(a), Bool(b)) => if a == b { 0 } else if a { 1 } else { -1 }
    (Null, Null) => 0
    (Null, _) => -1 // Null 最小
    (_, Null) => 1
    _ => 0 // 不同类型比较的简单回退（实际 jq 规则更复杂，这里简化处理）
  }
}
