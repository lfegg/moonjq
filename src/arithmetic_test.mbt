///|
/// 测试算术运算符
test "arithmetic_add_numbers" {
  let json_str = "null"
  let query_str = "1 + 2"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          inspect(res, content="[Number(3)]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "arithmetic_sub_numbers" {
  let json_str = "null"
  let query_str = "10 - 3"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          inspect(res, content="[Number(7)]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "arithmetic_mul_numbers" {
  let json_str = "null"
  let query_str = "4 * 5"
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
test "arithmetic_div_numbers" {
  let json_str = "null"
  let query_str = "20 / 4"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          inspect(res, content="[Number(5)]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "arithmetic_mod_numbers" {
  let json_str = "null"
  let query_str = "10 % 3"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          inspect(res, content="[Number(1)]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "arithmetic_complex_expression" {
  let json_str = "null"
  let query_str = "2 + 3 * 4"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          inspect(res, content="[Number(14)]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "arithmetic_with_fields" {
  let json_str = "{\"a\": 10, \"b\": 5}"
  let query_str = ".a + .b"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          inspect(res, content="[Number(15)]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "arithmetic_string_concat" {
  let json_str = "null"
  let query_str = "\"hello\" + \" \" + \"world\""
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          inspect(res, content="[String(\"hello world\")]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "arithmetic_array_concat" {
  let json_str = "null"
  let query_str = "[1, 2] + [3, 4]"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          inspect(
            res,
            content="[Array([Number(1), Number(2), Number(3), Number(4)])]",
          )
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "arithmetic_string_repeat" {
  let json_str = "null"
  let query_str = "\"ab\" * 3"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          inspect(res, content="[String(\"ababab\")]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "arithmetic_div_by_zero" {
  let json_str = "null"
  let query_str = "10 / 0"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          inspect(res, content="[Null]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "arithmetic_precedence" {
  let json_str = "null"
  let query_str = "10 - 2 * 3"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          inspect(res, content="[Number(4)]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}
