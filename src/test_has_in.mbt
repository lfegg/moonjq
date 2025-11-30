///|
/// has() 和 in() 函数测试

///|
test "has key in object" {
  let obj = {}
  obj["name"] = Json::String("John")
  obj["age"] = Json::Number(30.0)
  let json = Json::Object(obj)
  match parse_query("has(\"name\")") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[Bool(true)]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "has missing key in object" {
  let obj = {}
  obj["name"] = Json::String("John")
  let json = Json::Object(obj)
  match parse_query("has(\"email\")") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[Bool(false)]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "has index in array" {
  let json = Json::Array([
    Json::Number(1.0),
    Json::Number(2.0),
    Json::Number(3.0),
  ])
  match parse_query("has(1)") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[Bool(true)]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "has missing index in array" {
  let json = Json::Array([Json::Number(1.0), Json::Number(2.0)])
  match parse_query("has(5)") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[Bool(false)]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "has negative index in array" {
  let json = Json::Array([
    Json::Number(1.0),
    Json::Number(2.0),
    Json::Number(3.0),
  ])
  match parse_query("has(-1)") {
    Ok(query) => {
      let results = eval(json, query)
      // jq's has() does not support negative indices
      inspect(results, content="[Bool(false)]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "in array with number" {
  let json = Json::Number(2.0)
  match parse_query("in([1, 2, 3])") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[Bool(true)]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "not in array" {
  let json = Json::Number(5.0)
  match parse_query("in([1, 2, 3])") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[Bool(false)]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "string in array" {
  let json = Json::String("b")
  match parse_query("in([\"a\", \"b\", \"c\"])") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[Bool(true)]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "null in array" {
  let json = Json::Null
  match parse_query("in([1, null, 3])") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[Bool(true)]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "boolean in array" {
  let json = Json::Bool(true)
  match parse_query("in([false, true])") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[Bool(true)]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "has with pipe" {
  let obj = {}
  obj["user"] = Json::Object({
    "name": Json::String("John"),
    "age": Json::Number(30.0),
  })
  let json = Json::Object(obj)
  match parse_query(".user | has(\"name\")") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[Bool(true)]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "select with has" {
  let json = Json::Array([
    Json::Object({ "a": Json::Number(1.0) }),
    Json::Object({ "b": Json::Number(2.0) }),
    Json::Object({ "a": Json::Number(3.0) }),
  ])
  match parse_query(".[] | select(has(\"a\"))") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(
        results,
        content="[Object({\"a\": Number(1)}), Object({\"a\": Number(3)})]",
      )
    }
    Err(e) => fail("Query error: " + e)
  }
}
