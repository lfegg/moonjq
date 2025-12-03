///|
/// 测试切片操作符
test "slice_array" {
  let json_str = "[0, 1, 2, 3, 4, 5]"
  let query_str = ".[1:4]"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          inspect(res, content="[Array([Number(1), Number(2), Number(3)])]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "slice_array_negative_index" {
  let json_str = "[0, 1, 2, 3, 4]"
  let query_str = ".[-2:]"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          inspect(res, content="[Array([Number(3), Number(4)])]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "slice_string" {
  let json_str = "\"hello world\""
  let query_str = ".[0:5]"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          inspect(res, content="[String(\"hello\")]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
/// 测试递归下降操作符
test "recursive_descent" {
  let json_str = "{\"a\": {\"b\": 1}, \"c\": {\"b\": 2}}"
  let query_str = ".. | .b?"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          // 应该找到所有的 .b 值
          inspect(res, content="[Null, Number(1), Null, Number(2), Null]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "recursive_descent_simple" {
  let json_str = "{\"a\": 1, \"b\": {\"c\": 2}}"
  let query_str = ".."
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          // 应该返回所有值：根对象、1、内部对象、2
          inspect(res.length(), content="4")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
/// 测试可选操作符
test "optional_field" {
  let json_str = "{\"a\": 1}"
  let query_str = ".b?"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          // 字段不存在但使用了 ?，应该返回 null（不是空数组）
          inspect(res, content="[Null]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "optional_array_index" {
  let json_str = "[1, 2, 3]"
  let query_str = ".[10]?"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          // 索引越界但使用了 ?，应该返回空数组
          inspect(res, content="[Null]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "slice_open_end" {
  let json_str = "[1, 2, 3, 4, 5]"
  let query_str = ".[2:]"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          inspect(res, content="[Array([Number(3), Number(4), Number(5)])]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "slice_open_start" {
  let json_str = "[1, 2, 3, 4, 5]"
  let query_str = ".[:3]"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          inspect(res, content="[Array([Number(1), Number(2), Number(3)])]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "field_with_slice" {
  let json_str = "{\"items\": [1, 2, 3, 4, 5]}"
  let query_str = ".items[1:3]"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          inspect(res, content="[Array([Number(2), Number(3)])]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "field_with_index" {
  let json_str = "{\"items\": [10, 20, 30]}"
  let query_str = ".items[1]"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          inspect(res, content="[Number(20)]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "field_with_iterator" {
  let json_str = "{\"items\": [1, 2, 3]}"
  let query_str = ".items[]"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          inspect(res, content="[Number(1), Number(2), Number(3)]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}
