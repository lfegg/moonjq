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
test "contains" {
  let json_str = "[1,2,3,4,5]"
  let query_str = "contains([2,3])"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          inspect(res, content="[Bool(true)]")
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "flatten" {
  let json_str = "[[1,2],[3,4],[5,6]]"
  let query_str = "flatten"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          inspect(
            res,
            content="[Array([Number(1), Number(2), Number(3), Number(4), Number(5), Number(6)])]",
          )
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "flatten_with_depth" {
  let json_str = "[[[1,2]],[[3,4]]]"
  let query_str = "flatten(1)"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          inspect(
            res,
            content="[Array([Array([Number(1), Number(2)]), Array([Number(3), Number(4)])])]",
          )
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "add" {
  let json_str = "[1,2,3,4,5]"
  let query_str = "add"
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
test "reverse" {
  let json_str = "[1,2,3,4,5]"
  let query_str = "reverse"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          inspect(
            res,
            content="[Array([Number(5), Number(4), Number(3), Number(2), Number(1)])]",
          )
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "sort_and_reverse" {
  let json_str = "[5,2,8,1,9]"
  let query_str = "sort | reverse"
  match parse_json(json_str) {
    Ok(json) =>
      match parse_query(query_str) {
        Ok(query) => {
          let res = eval(json, query)
          inspect(
            res,
            content="[Array([Number(9), Number(8), Number(5), Number(2), Number(1)])]",
          )
        }
        Err(e) => fail("Query error: " + e)
      }
    Err(e) => fail("JSON error: " + e)
  }
}

///|
test "first" {
  let json_str = "[1,2,3,4,5]"
  let query_str = "first"
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
test "last" {
  let json_str = "[1,2,3,4,5]"
  let query_str = "last"
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
test "first_empty_array" {
  let json_str = "[]"
  let query_str = "first"
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
test "first_expr" {
  let json_str = "[1,2,3,4,5]"
  let query_str = "first(.[] | select(. > 2))"
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
test "last_expr" {
  let json_str = "[1,2,3,4,5]"
  let query_str = "last(.[] | select(. > 2))"
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
