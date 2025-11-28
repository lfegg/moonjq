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

    // 二元操作，如 ==, !=, >, <
    Binary(op, left, right) => {
      let l_res = eval(json, left)
      let r_res = eval(json, right)
      let res = []
      // 笛卡尔积：左侧每个结果与右侧每个结果进行比较
      for l in l_res {
        for r in r_res {
          res.push(Json::Bool(compare(op, l, r)))
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
/// 执行比较操作。
fn compare(op : Op, l : Json, r : Json) -> Bool {
  match op {
    Eq => l == r
    Neq => l != r
    Gt => compare_values(l, r) > 0
    Lt => compare_values(l, r) < 0
    Gte => compare_values(l, r) >= 0
    Lte => compare_values(l, r) <= 0
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
