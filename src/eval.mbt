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

    // 对数组每个元素应用表达式 'map(expr)'
    Map(expr) =>
      match json {
        Array(arr) => {
          let results = []
          for item in arr {
            let item_results = eval(item, expr)
            if item_results.length() > 0 {
              results.push(item_results[0])
            }
          }
          [Json::Array(results)]
        }
        _ => [Json::Null]
      }

    // 数组求和或对象合并 'add'
    Add =>
      match json {
        Array(arr) =>
          if arr.length() == 0 {
            [Json::Null]
          } else {
            // Determine type from first element
            match arr[0] {
              Number(_) => {
                let mut sum = 0.0
                for item in arr {
                  match item {
                    Number(n) => sum = sum + n
                    _ => ()
                  }
                }
                [Json::Number(sum)]
              }
              String(_) => {
                let mut result = ""
                for item in arr {
                  match item {
                    String(s) => result = result + s
                    _ => ()
                  }
                }
                [Json::String(result)]
              }
              Array(_) => {
                let result = []
                for item in arr {
                  match item {
                    Array(a) => result.append(a)
                    _ => ()
                  }
                }
                [Json::Array(result)]
              }
              Object(_) => {
                let result = Map::new()
                for item in arr {
                  match item {
                    Object(obj) =>
                      for key in obj.keys() {
                        match obj.get(key) {
                          Some(value) => result.set(key, value)
                          None => ()
                        }
                      }
                    _ => ()
                  }
                }
                [Json::Object(result)]
              }
              _ => [Json::Null]
            }
          }
        _ => [Json::Null]
      }

    // 数组最小值 'min'
    Min =>
      match json {
        Array(arr) =>
          if arr.length() == 0 {
            [Json::Null]
          } else {
            let mut min_val = arr[0]
            for item in arr {
              if compare_json(item, min_val) < 0 {
                min_val = item
              }
            }
            [min_val]
          }
        _ => [Json::Null]
      }

    // 数组最大值 'max'
    Max =>
      match json {
        Array(arr) =>
          if arr.length() == 0 {
            [Json::Null]
          } else {
            let mut max_val = arr[0]
            for item in arr {
              if compare_json(item, max_val) > 0 {
                max_val = item
              }
            }
            [max_val]
          }
        _ => [Json::Null]
      }

    // 数组排序 'sort'
    Sort =>
      match json {
        Array(arr) => {
          let sorted = arr.copy()
          sort_json_array(sorted)
          [Json::Array(sorted)]
        }
        _ => [Json::Null]
      }

    // 按表达式排序 'sort_by(expr)'
    SortBy(expr) =>
      match json {
        Array(arr) => {
          // Create pairs of (original, key)
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
          // Sort by key
          sort_pairs_by_second(pairs)
          // Extract sorted values
          let sorted = []
          for pair in pairs {
            sorted.push(pair.0)
          }
          [Json::Array(sorted)]
        }
        _ => [Json::Null]
      }

    // 按表达式分组 'group_by(expr)'
    GroupBy(expr) =>
      match json {
        Array(arr) => {
          // First sort by the expression
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
          sort_pairs_by_second(pairs)

          // Group consecutive items with same key
          let groups = []
          if pairs.length() > 0 {
            let mut current_group = [pairs[0].0]
            let mut current_key = pairs[0].1
            for i = 1; i < pairs.length(); i = i + 1 {
              if pairs[i].1 == current_key {
                current_group.push(pairs[i].0)
              } else {
                groups.push(Json::Array(current_group))
                current_group = [pairs[i].0]
                current_key = pairs[i].1
              }
            }
            groups.push(Json::Array(current_group))
          }
          [Json::Array(groups)]
        }
        _ => [Json::Null]
      }

    // 数组去重 'unique'
    Unique =>
      match json {
        Array(arr) => {
          let sorted = arr.copy()
          sort_json_array(sorted)
          let unique_arr = []
          if sorted.length() > 0 {
            unique_arr.push(sorted[0])
            for i = 1; i < sorted.length(); i = i + 1 {
              if sorted[i] != sorted[i - 1] {
                unique_arr.push(sorted[i])
              }
            }
          }
          [Json::Array(unique_arr)]
        }
        _ => [Json::Null]
      }

    // 按表达式去重 'unique_by(expr)'
    UniqueBy(expr) =>
      match json {
        Array(arr) => {
          // Create pairs and sort
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
          sort_pairs_by_second(pairs)

          // Keep first of each unique key
          let unique_arr = []
          if pairs.length() > 0 {
            unique_arr.push(pairs[0].0)
            let mut prev_key = pairs[0].1
            for i = 1; i < pairs.length(); i = i + 1 {
              if pairs[i].1 != prev_key {
                unique_arr.push(pairs[i].0)
                prev_key = pairs[i].1
              }
            }
          }
          [Json::Array(unique_arr)]
        }
        _ => [Json::Null]
      }

    // 数组反转 'reverse'
    Reverse =>
      match json {
        Array(arr) => {
          let reversed = []
          for i = arr.length() - 1; i >= 0; i = i - 1 {
            reversed.push(arr[i])
          }
          [Json::Array(reversed)]
        }
        _ => [Json::Null]
      }

    // 数组扁平化 'flatten'
    Flatten =>
      match json {
        Array(arr) => {
          let result = []
          for item in arr {
            match item {
              Array(sub) => result.append(sub)
              _ => result.push(item)
            }
          }
          [Json::Array(result)]
        }
        _ => [Json::Null]
      }

    // 指定深度的数组扁平化 'flatten(depth)'
    FlattenDepth(depth) =>
      match json {
        Array(arr) => {
          fn flatten_recursive(items : Array[Json], d : Int) -> Array[Json] {
            if d <= 0 {
              return items
            }
            let result = []
            for item in items {
              match item {
                Array(sub) =>
                  if d > 1 {
                    result.append(flatten_recursive(sub, d - 1))
                  } else {
                    result.append(sub)
                  }
                _ => result.push(item)
              }
            }
            result
          }

          [Json::Array(flatten_recursive(arr, depth))]
        }
        _ => [Json::Null]
      }

    // 检查是否包含 'contains(value)'
    Contains(query) =>
      match json {
        Array(arr) => {
          let search_results = eval(json, query)
          if search_results.length() == 0 {
            [Json::Bool(false)]
          } else {
            let search_val = search_results[0]
            match search_val {
              Array(search_arr) => {
                // Check if all elements in search_arr are in arr
                let mut all_found = true
                for search_item in search_arr {
                  let mut found = false
                  for item in arr {
                    if item == search_item {
                      found = true
                      break
                    }
                  }
                  if not(found) {
                    all_found = false
                    break
                  }
                }
                [Json::Bool(all_found)]
              }
              _ => {
                // Check if single value is in array
                let mut found = false
                for item in arr {
                  if item == search_val {
                    found = true
                    break
                  }
                }
                [Json::Bool(found)]
              }
            }
          }
        }
        String(s) =>
          match eval(json, query) {
            [String(search)] => [Json::Bool(s.contains(search))]
            _ => [Json::Bool(false)]
          }
        Object(obj) =>
          match eval(json, query) {
            [Object(search_obj)] => {
              // Check if all key-value pairs in search_obj exist in obj
              let mut all_match = true
              for key in search_obj.keys() {
                match (obj.get(key), search_obj.get(key)) {
                  (Some(v1), Some(v2)) =>
                    if v1 != v2 {
                      all_match = false
                      break
                    }
                  (None, _) => {
                    all_match = false
                    break
                  }
                  _ => ()
                }
              }
              [Json::Bool(all_match)]
            }
            _ => [Json::Bool(false)]
          }
        _ => [Json::Bool(false)]
      }

    // 获取第一个元素 'first'
    First =>
      match json {
        Array(arr) => if arr.length() > 0 { [arr[0]] } else { [Json::Null] }
        _ => [Json::Null]
      }

    // 获取表达式的第一个结果 'first(expr)'
    FirstExpr(expr) => {
      let results = eval(json, expr)
      if results.length() > 0 {
        [results[0]]
      } else {
        [Json::Null]
      }
    }

    // 获取最后一个元素 'last'
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

    // 获取表达式的最后一个结果 'last(expr)'
    LastExpr(expr) => {
      let results = eval(json, expr)
      if results.length() > 0 {
        [results[results.length() - 1]]
      } else {
        [Json::Null]
      }
    }

    // 逻辑与 'expr1 and expr2'
    And(left, right) => {
      let left_results = eval(json, left)
      if left_results.length() == 0 {
        [Json::Bool(false)]
      } else {
        let left_val = left_results[0]
        if is_truthy(left_val) {
          let right_results = eval(json, right)
          if right_results.length() == 0 {
            [Json::Bool(false)]
          } else {
            [Json::Bool(is_truthy(right_results[0]))]
          }
        } else {
          [Json::Bool(false)]
        }
      }
    }

    // 逻辑或 'expr1 or expr2'
    Or(left, right) => {
      let left_results = eval(json, left)
      if left_results.length() == 0 {
        let right_results = eval(json, right)
        if right_results.length() == 0 {
          [Json::Bool(false)]
        } else {
          [Json::Bool(is_truthy(right_results[0]))]
        }
      } else {
        let left_val = left_results[0]
        if is_truthy(left_val) {
          [Json::Bool(true)]
        } else {
          let right_results = eval(json, right)
          if right_results.length() == 0 {
            [Json::Bool(false)]
          } else {
            [Json::Bool(is_truthy(right_results[0]))]
          }
        }
      }
    }

    // 逻辑非 'expr | not' 或 'not'
    Not(expr) => {
      let results = eval(json, expr)
      if results.length() == 0 {
        [Json::Bool(true)]
      } else {
        [Json::Bool(not(is_truthy(results[0])))]
      }
    }

    // 空值合并 'expr1 // expr2'
    // 如果左侧是 null 或 false，返回右侧；否则返回左侧
    Alternative(left, right) => {
      let left_results = eval(json, left)
      if left_results.length() == 0 {
        eval(json, right)
      } else {
        let left_val = left_results[0]
        match left_val {
          Null => eval(json, right)
          Bool(false) => eval(json, right)
          _ => left_results
        }
      }
    }

    // 转换为字符串 'tostring'
    ToString =>
      match json {
        String(_) => [json]
        Number(n) => {
          let s = n.to_string()
          // Remove trailing .0 for integers
          if s.contains(".") {
            let parts = s.split(".")
            let parts_array = parts.collect()
            if parts_array.length() == 2 && parts_array[1].to_string() == "0" {
              [Json::String(parts_array[0].to_string())]
            } else {
              [Json::String(s)]
            }
          } else {
            [Json::String(s)]
          }
        }
        Bool(b) => [Json::String(if b { "true" } else { "false" })]
        Null => [Json::String("null")]
        Array(_) => [Json::String(json.to_json_string())]
        Object(_) => [Json::String(json.to_json_string())]
      }

    // 转换为数字 'tonumber'
    ToNumber =>
      match json {
        Number(_) => [json]
        String(s) =>
          // Try to parse the string as a number
          match parse_json(s) {
            Ok(Json::Number(n)) => [Json::Number(n)]
            _ =>
              // If that fails, return null or error
              // jq would throw an error, but we'll return null for now
              [Json::Null]
          }
        _ => [Json::Null]
      }

    // 分割字符串 'split(sep)'
    Split(sep_query) =>
      match json {
        String(s) => {
          let sep_results = eval(json, sep_query)
          if sep_results.length() > 0 {
            match sep_results[0] {
              String(sep) => {
                let parts = s.split(sep)
                let result = []
                for part in parts {
                  result.push(Json::String(part.to_string()))
                }
                [Json::Array(result)]
              }
              _ => [Json::Null]
            }
          } else {
            [Json::Null]
          }
        }
        _ => [Json::Null]
      }

    // 连接数组 'join(sep)'
    Join(sep_query) =>
      match json {
        Array(arr) => {
          let sep_results = eval(json, sep_query)
          if sep_results.length() > 0 {
            match sep_results[0] {
              String(sep) => {
                let parts = []
                for item in arr {
                  match item {
                    String(s) => parts.push(s)
                    Number(n) => parts.push(n.to_string())
                    Bool(b) => parts.push(if b { "true" } else { "false" })
                    Null => parts.push("null")
                    _ => parts.push(item.to_json_string())
                  }
                }
                let mut result = ""
                for i = 0; i < parts.length(); i = i + 1 {
                  if i > 0 {
                    result = result + sep
                  }
                  result = result + parts[i]
                }
                [Json::String(result)]
              }
              _ => [Json::Null]
            }
          } else {
            [Json::Null]
          }
        }
        _ => [Json::Null]
      }

    // 检查前缀 'startswith(str)'
    StartsWith(prefix_query) =>
      match json {
        String(s) => {
          let prefix_results = eval(json, prefix_query)
          if prefix_results.length() > 0 {
            match prefix_results[0] {
              String(prefix) => [Json::Bool(s.has_prefix(prefix))]
              _ => [Json::Bool(false)]
            }
          } else {
            [Json::Bool(false)]
          }
        }
        _ => [Json::Null]
      }

    // 检查后缀 'endswith(str)'
    EndsWith(suffix_query) =>
      match json {
        String(s) => {
          let suffix_results = eval(json, suffix_query)
          if suffix_results.length() > 0 {
            match suffix_results[0] {
              String(suffix) => [Json::Bool(s.has_suffix(suffix))]
              _ => [Json::Bool(false)]
            }
          } else {
            [Json::Bool(false)]
          }
        }
        _ => [Json::Null]
      }

    // 删除左侧字符串 'ltrimstr(str)'
    LTrimStr(prefix_query) =>
      match json {
        String(s) => {
          let prefix_results = eval(json, prefix_query)
          if prefix_results.length() > 0 {
            match prefix_results[0] {
              String(prefix) =>
                if s.has_prefix(prefix) {
                  let new_s = s
                    .view(start_offset=prefix.length(), end_offset=s.length())
                    .to_string()
                  [Json::String(new_s)]
                } else {
                  [json]
                }
              _ => [json]
            }
          } else {
            [json]
          }
        }
        _ => [Json::Null]
      }

    // 删除右侧字符串 'rtrimstr(str)'
    RTrimStr(suffix_query) =>
      match json {
        String(s) => {
          let suffix_results = eval(json, suffix_query)
          if suffix_results.length() > 0 {
            match suffix_results[0] {
              String(suffix) =>
                if s.has_suffix(suffix) {
                  let new_s = s
                    .view(
                      start_offset=0,
                      end_offset=s.length() - suffix.length(),
                    )
                    .to_string()
                  [Json::String(new_s)]
                } else {
                  [json]
                }
              _ => [json]
            }
          } else {
            [json]
          }
        }
        _ => [Json::Null]
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

///|
/// 排序辅助函数 - 使用快速排序
fn sort_json_array(arr : Array[Json]) -> Unit {
  fn quicksort(left : Int, right : Int) -> Unit {
    if left < right {
      let pivot = arr[(left + right) / 2]
      let mut i = left
      let mut j = right
      while i <= j {
        while compare_json(arr[i], pivot) < 0 {
          i = i + 1
        }
        while compare_json(arr[j], pivot) > 0 {
          j = j - 1
        }
        if i <= j {
          let temp = arr[i]
          arr[i] = arr[j]
          arr[j] = temp
          i = i + 1
          j = j - 1
        }
      }
      if left < j {
        quicksort(left, j)
      }
      if i < right {
        quicksort(i, right)
      }
    }
  }

  if arr.length() > 1 {
    quicksort(0, arr.length() - 1)
  }
}

///|
/// 排序元组数组（按第二个元素排序）
fn sort_pairs_by_second(arr : Array[(Json, Json)]) -> Unit {
  fn quicksort(left : Int, right : Int) -> Unit {
    if left < right {
      let pivot = arr[(left + right) / 2].1
      let mut i = left
      let mut j = right
      while i <= j {
        while compare_json(arr[i].1, pivot) < 0 {
          i = i + 1
        }
        while compare_json(arr[j].1, pivot) > 0 {
          j = j - 1
        }
        if i <= j {
          let temp = arr[i]
          arr[i] = arr[j]
          arr[j] = temp
          i = i + 1
          j = j - 1
        }
      }
      if left < j {
        quicksort(left, j)
      }
      if i < right {
        quicksort(i, right)
      }
    }
  }

  if arr.length() > 1 {
    quicksort(0, arr.length() - 1)
  }
}

///|
/// 比较两个 JSON 值的大小
/// 返回: -1 表示 l < r，0 表示 l == r，1 表示 l > r
fn compare_json(l : Json, r : Json) -> Int {
  match (l, r) {
    (Number(a), Number(b)) => if a < b { -1 } else if a > b { 1 } else { 0 }
    (String(a), String(b)) => if a < b { -1 } else if a > b { 1 } else { 0 }
    (Bool(a), Bool(b)) => if a == b { 0 } else if a { 1 } else { -1 }
    (Null, Null) => 0
    (Null, _) => -1 // Null 最小
    (_, Null) => 1
    (Array(a), Array(b)) => {
      for i = 0; i < a.length() && i < b.length(); i = i + 1 {
        let cmp = compare_json(a[i], b[i])
        if cmp != 0 {
          return cmp
        }
      }
      if a.length() < b.length() {
        -1
      } else if a.length() > b.length() {
        1
      } else {
        0
      }
    }
    _ => 0 // 不同类型比较的简单回退
  }
}

///|
fn compare_values(l : Json, r : Json) -> Int {
  compare_json(l, r)
}
