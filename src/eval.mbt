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
        Array(arr) => {
          let len = arr.length()
          // Support negative indices
          let actual_idx = if idx < 0 { len + idx } else { idx }
          if actual_idx >= 0 && actual_idx < len {
            [arr[actual_idx]]
          } else {
            [Json::Null] // 索引越界返回 null
          }
        }
        _ => [Json::Null] // 非数组类型索引返回 null
      }

    // 切片 '[start:end]'
    Slice(start, end) =>
      match json {
        Array(arr) => {
          let len = arr.length()
          // 处理负数索引和默认值
          let s = match start {
            Some(idx) => if idx < 0 { len + idx } else { idx }
            None => 0
          }
          let e = match end {
            Some(idx) => if idx < 0 { len + idx } else { idx }
            None => len
          }
          // 确保索引在合法范围内
          let start_idx = if s < 0 { 0 } else if s > len { len } else { s }
          let end_idx = if e < 0 { 0 } else if e > len { len } else { e }
          let result = []
          for i = start_idx; i < end_idx; i = i + 1 {
            result.push(arr[i])
          }
          [Json::Array(result)]
        }
        String(s) => {
          let len = s.length()
          // 处理负数索引和默认值
          let start_idx = match start {
            Some(idx) => {
              let i = if idx < 0 { len + idx } else { idx }
              if i < 0 {
                0
              } else if i > len {
                len
              } else {
                i
              }
            }
            None => 0
          }
          let end_idx = match end {
            Some(idx) => {
              let i = if idx < 0 { len + idx } else { idx }
              if i < 0 {
                0
              } else if i > len {
                len
              } else {
                i
              }
            }
            None => len
          }
          let substr = s
            .view(start_offset=start_idx, end_offset=end_idx)
            .to_string()
          [Json::String(substr)]
        }
        _ => [Json::Null] // 非数组/字符串类型返回 null
      }

    // 递归下降 '..'
    RecursiveDescent(query) => {
      fn recurse(j : Json, q : Query) -> Array[Json] {
        let results = eval(j, q)
        match j {
          Array(arr) =>
            for elem in arr {
              results.append(recurse(elem, q))
            }
          Object(obj) =>
            for v in obj.values() {
              results.append(recurse(v, q))
            }
          _ => ()
        }
        results
      }

      recurse(json, query)
    }

    // 可选操作符 'query?'
    Optional(q) => {
      // 可选操作符会捕获错误，如果查询失败则返回空数组而不是报错
      // 在当前实现中，我们的 eval 不会抛出异常，而是返回 Null
      // 所以可选操作符主要是过滤掉 Null 结果
      let results = eval(json, q)
      let filtered = []
      for r in results {
        match r {
          Null => () // 过滤掉 null
          _ => filtered.push(r)
        }
      }
      filtered
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

    // 字面量，如 1, "string", true
    Literal(v) => [v]

    // 二元操作，如 ==, !=, >, <, +, -, *, /, %
    Binary(op, left, right) => {
      let l_res = eval(json, left)
      let r_res = eval(json, right)
      let res = []
      // 笛卡尔积：左侧每个结果与右侧每个结果进行运算
      for l in l_res {
        for r in r_res {
          res.push(apply_binary_op(op, l, r))
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

    // 检查对象是否有键或数组是否有索引 'has(key)'
    Has(key_query) =>
      match json {
        Object(obj) => {
          // 对于对象，检查键是否存在
          let key_results = eval(json, key_query)
          if key_results.length() > 0 {
            match key_results[0] {
              String(key) => [Json::Bool(obj.contains(key))]
              _ => [Json::Bool(false)]
            }
          } else {
            [Json::Bool(false)]
          }
        }
        Array(arr) => {
          // 对于数组，检查索引是否存在
          let key_results = eval(json, key_query)
          if key_results.length() > 0 {
            match key_results[0] {
              Number(n) => {
                let idx = n.to_int()
                let len = arr.length()
                // jq's has() does not accept negative indices
                if idx < 0 {
                  [Json::Bool(false)]
                } else {
                  [Json::Bool(idx >= 0 && idx < len)]
                }
              }
              _ => [Json::Bool(false)]
            }
          } else {
            [Json::Bool(false)]
          }
        }
        _ => [Json::Bool(false)]
      }

    // 条件表达式 'if cond then expr1 else expr2 end'
    Conditional(cond_query, then_query, else_query) => {
      let cond_results = eval(json, cond_query)
      if cond_results.length() > 0 {
        // Check if condition is truthy (not false or null)
        let is_truthy = match cond_results[0] {
          Json::Bool(false) => false
          Json::Null => false
          _ => true
        }
        if is_truthy {
          eval(json, then_query)
        } else {
          eval(json, else_query)
        }
      } else {
        // Empty result is falsy
        eval(json, else_query)
      }
    }

    // 条件表达式 'if cond then expr1 else expr2 end'
    Conditional(cond_query, then_query, else_query) => {
      let cond_results = eval(json, cond_query)
      if cond_results.length() > 0 {
        // Check if condition is truthy (not false or null)
        let is_truthy = match cond_results[0] {
          Json::Bool(false) => false
          Json::Null => false
          _ => true
        }
        if is_truthy {
          eval(json, then_query)
        } else {
          eval(json, else_query)
        }
      } else {
        // Empty result is falsy
        eval(json, else_query)
      }
    }

    // 检查值是否在数组中 'in(array)'
    In(array_query) => {
      let array_results = eval(json, array_query)
      if array_results.length() > 0 {
        match array_results[0] {
          Array(arr) => {
            // 检查当前json是否在数组中
            let mut found = false
            for item in arr {
              if item == json {
                found = true
                break
              }
            }
            [Json::Bool(found)]
          }
          Object(obj) =>
            // 对于对象，检查当前值（作为键）是否存在
            match json {
              String(key) => [Json::Bool(obj.contains(key))]
              _ => [Json::Bool(false)]
            }
          _ => [Json::Bool(false)]
        }
      } else {
        [Json::Bool(false)]
      }
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

    // 退出 REPL 'exit' 或 'exit()'
    Exit =>
      // Return a special marker that REPL will recognize
      // We'll use a string "__EXIT__" as a signal
      [Json::String("__EXIT__")]

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
  }
}

///|
/// 判断 JSON 值是否为“真值”。
/// 在 jq 中，只有 false 和 null 是假值，其他（包括 0, "", []）都是真值。
fn is_truthy(j : Json) -> Bool {
  match j {
    Null => false
    Bool(false) => false
    _ => true
  }
}

///|
/// 执行二元操作（比较或算术）。
fn apply_binary_op(op : Op, l : Json, r : Json) -> Json {
  match op {
    // 比较操作，返回布尔值
    Eq => Json::Bool(l == r)
    Neq => Json::Bool(l != r)
    Gt => Json::Bool(compare_values(l, r) > 0)
    Lt => Json::Bool(compare_values(l, r) < 0)
    Gte => Json::Bool(compare_values(l, r) >= 0)
    Lte => Json::Bool(compare_values(l, r) <= 0)
    // 算术操作，返回数字或 null
    Add =>
      match (l, r) {
        (Number(a), Number(b)) => Json::Number(a + b)
        (String(a), String(b)) => Json::String(a + b) // 字符串连接
        (Array(a), Array(b)) => {
          let result = []
          result.append(a)
          result.append(b)
          Json::Array(result) // 数组连接
        }
        (Object(a), Object(b)) => {
          let result = Map::new()
          a.each(fn(k, v) { result.set(k, v) })
          b.each(fn(k, v) { result.set(k, v) }) // 对象合并
          Json::Object(result)
        }
        _ => Json::Null // 类型不匹配返回 null
      }
    Sub =>
      match (l, r) {
        (Number(a), Number(b)) => Json::Number(a - b)
        (Array(a), Array(b)) => {
          // 数组差集：从 a 中移除 b 中的元素
          let result = []
          for item in a {
            let mut found = false
            for remove in b {
              if item == remove {
                found = true
                break
              }
            }
            if not(found) {
              result.push(item)
            }
          }
          Json::Array(result)
        }
        _ => Json::Null
      }
    Mul =>
      match (l, r) {
        (Number(a), Number(b)) => Json::Number(a * b)
        (String(s), Number(n)) | (Number(n), String(s)) =>
          // 字符串重复
          if n <= 0.0 {
            Json::String("")
          } else {
            let count = n.to_int()
            let buf = StringBuilder::new()
            for i = 0; i < count; i = i + 1 {
              buf.write_string(s)
            }
            Json::String(buf.to_string())
          }
        (Object(obj), Object(other)) => {
          // 对象递归合并
          let result = Map::new()
          obj.each(fn(k, v) { result.set(k, v) })
          other.each(fn(k, v) { result.set(k, v) })
          Json::Object(result)
        }
        _ => Json::Null
      }
    Div =>
      match (l, r) {
        (Number(a), Number(b)) =>
          if b == 0.0 {
            Json::Null // 除以零返回 null
          } else {
            Json::Number(a / b)
          }
        (String(s), String(_sep)) =>
          // 字符串分割（简化实现）
          // 这里简化处理，实际 jq 的字符串分割更复杂
          Json::Array([Json::String(s)]) // 简化：返回原字符串数组
        _ => Json::Null
      }
    Mod =>
      match (l, r) {
        (Number(a), Number(b)) =>
          if b == 0.0 {
            Json::Null
          } else {
            Json::Number(a % b)
          }
        _ => Json::Null
      }
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
