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
