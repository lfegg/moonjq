///|
/// 新功能测试：负数字面量、括号表达式、type() 函数

///|
test "negative number literal" {
  let json = Json::Null
  match parse_query("-5") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[Number(-5)]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "negative number in expression" {
  let json = Json::Null
  match parse_query("-5 + 3") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[Number(-2)]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "negative number multiplication" {
  let json = Json::Null
  match parse_query("-3 * 4") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[Number(-12)]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "double negative" {
  let json = Json::Null
  match parse_query("0 - (-5)") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[Number(5)]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "parentheses simple" {
  let json = Json::Null
  match parse_query("(2 + 3) * 4") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[Number(20)]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "parentheses nested" {
  let json = Json::Null
  match parse_query("((2 + 3) * 4) - 10") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[Number(10)]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "parentheses precedence override" {
  let json = Json::Null
  match parse_query("2 * (3 + 4)") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[Number(14)]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "type function null" {
  let json = Json::Null
  match parse_query("type") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[String(\"null\")]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "type function boolean" {
  let json = Json::Bool(true)
  match parse_query("type") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[String(\"boolean\")]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "type function number" {
  let json = Json::Number(42.0)
  match parse_query("type") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[String(\"number\")]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "type function string" {
  let json = Json::String("hello")
  match parse_query("type") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[String(\"string\")]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "type function array" {
  let json = Json::Array([Json::Number(1.0), Json::Number(2.0)])
  match parse_query("type") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[String(\"array\")]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "type function object" {
  let obj = {}
  obj["key"] = Json::String("value")
  let json = Json::Object(obj)
  match parse_query("type") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[String(\"object\")]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "type with pipe" {
  let obj = {}
  obj["name"] = Json::String("test")
  let json = Json::Object(obj)
  match parse_query(".name | type") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[String(\"string\")]")
    }
    Err(e) => fail("Query error: " + e)
  }
}
