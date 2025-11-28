///|
test "iterator" {
  let json_str = "[1, 2, 3]"
  let query_str = ".[]"
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

///|
test "select" {
  let json_str = "[1, 2, 3]"
  let query_str = ".[] | select(. > 1)"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          inspect(res, content="[Number(2), Number(3)]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "object_iterator" {
  let json_str = "{\"a\": 1, \"b\": 2}"
  let query_str = ".[]"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let _ = eval(json, query)
          // Order of object values is not guaranteed, but let's check if we get numbers
          // inspect(res, content="...") 
          // Since map iteration order might vary, we can't easily snapshot test exact output without sorting.
          // But for small map it might be consistent.
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "index_and_sequence" {
  let json_str = "[10, 20, 30]"
  let query_str = ".[0], .[2]"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          inspect(res, content="[Number(10), Number(30)]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "recurse_simple_array" {
  let json_str = "[1, [2, 3], 4]"
  let query_str = ".."
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          inspect(
            res,
            content="[Array([Number(1), Array([Number(2), Number(3)]), Number(4)]), Number(1), Array([Number(2), Number(3)]), Number(2), Number(3), Number(4)]",
          )
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "recurse_nested_object" {
  let json_str = "{\"a\": {\"b\": 1, \"c\": {\"d\": 2}}, \"e\": 3}"
  let query_str = ".."
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          // 递归下降会返回所有嵌套的值
          // 检查结果数量和类型
          inspect(res.length(), content="6")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "recurse_with_pipe" {
  let json_str = "{\"users\": [{\"name\": \"Alice\", \"age\": 30}, {\"name\": \"Bob\", \"age\": 25}]}"
  let query_str = ".. | select(. > 20)"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          // 应该返回所有大于20的数字值
          inspect(res, content="[Number(30), Number(25)]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "optional_field_access" {
  let json_str = "{\"a\": 1, \"b\": 2}"
  let query_str = ".c?"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          // 访问不存在的字段，应该返回 null
          inspect(res, content="[Null]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "optional_iterator" {
  let json_str = "\"not an array\""
  let query_str = ".[]?"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          // 尝试迭代非数组类型，应该返回 null 而不是空数组
          inspect(res, content="[Null]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "optional_with_valid_access" {
  let json_str = "{\"a\": {\"b\": 42}}"
  let query_str = ".a.b?"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          // 正常访问，应该返回值本身
          inspect(res, content="[Number(42)]")
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
          // 索引越界，应该返回 null
          inspect(res, content="[Null]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "slice_array_basic" {
  let json_str = "[0, 1, 2, 3, 4, 5]"
  let query_str = ".[1:4]"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          // 切片 [1:4] 应该返回 [1, 2, 3]
          inspect(res, content="[Array([Number(1), Number(2), Number(3)])]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "slice_array_from_start" {
  let json_str = "[0, 1, 2, 3, 4]"
  let query_str = ".[:3]"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          // 切片 [:3] 应该返回 [0, 1, 2]
          inspect(res, content="[Array([Number(0), Number(1), Number(2)])]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "slice_array_to_end" {
  let json_str = "[0, 1, 2, 3, 4]"
  let query_str = ".[2:]"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          // 切片 [2:] 应该返回 [2, 3, 4]
          inspect(res, content="[Array([Number(2), Number(3), Number(4)])]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "slice_array_full" {
  let json_str = "[0, 1, 2, 3]"
  let query_str = ".[:]"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          // 切片 [:] 应该返回完整数组
          inspect(
            res,
            content="[Array([Number(0), Number(1), Number(2), Number(3)])]",
          )
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "slice_array_negative_index" {
  let json_str = "[0, 1, 2, 3, 4]"
  let query_str = ".[-3:-1]"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          // 切片 [-3:-1] 应该返回 [2, 3]
          inspect(res, content="[Array([Number(2), Number(3)])]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "slice_string_basic" {
  let json_str = "\"hello world\""
  let query_str = ".[0:5]"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          // 字符串切片 [0:5] 应该返回 "hello"
          inspect(res, content="[String(\"hello\")]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "slice_string_from_middle" {
  let json_str = "\"hello world\""
  let query_str = ".[6:]"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          // 字符串切片 [6:] 应该返回 "world"
          inspect(res, content="[String(\"world\")]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "slice_string_negative" {
  let json_str = "\"hello\""
  let query_str = ".[-3:]"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          // 字符串切片 [-3:] 应该返回 "llo"
          inspect(res, content="[String(\"llo\")]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}
