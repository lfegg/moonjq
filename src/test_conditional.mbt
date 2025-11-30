///|
/// Tests for conditional expressions (if-then-else-end)
test "simple if-then-else true" {
  let json = Json::Number(5.0)
  match parse_query("if . > 3 then \"big\" else \"small\" end") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[String(\"big\")]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "simple if-then-else false" {
  let json = Json::Number(2.0)
  match parse_query("if . > 3 then \"big\" else \"small\" end") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[String(\"small\")]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "if-elif-else first condition true" {
  let json = Json::Number(10.0)
  match
    parse_query(
      "if . > 5 then \"large\" elif . > 2 then \"medium\" else \"small\" end",
    ) {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[String(\"large\")]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "if-elif-else second condition true" {
  let json = Json::Number(4.0)
  match
    parse_query(
      "if . > 5 then \"large\" elif . > 2 then \"medium\" else \"small\" end",
    ) {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[String(\"medium\")]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "if-elif-else all false" {
  let json = Json::Number(1.0)
  match
    parse_query(
      "if . > 5 then \"large\" elif . > 2 then \"medium\" else \"small\" end",
    ) {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[String(\"small\")]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "conditional with null is falsy" {
  let json = Json::Null
  match parse_query("if . then \"truthy\" else \"falsy\" end") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[String(\"falsy\")]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "conditional with false is falsy" {
  let json = Json::Bool(false)
  match parse_query("if . then \"truthy\" else \"falsy\" end") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[String(\"falsy\")]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "conditional with zero is truthy" {
  let json = Json::Number(0.0)
  match parse_query("if . then \"truthy\" else \"falsy\" end") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[String(\"truthy\")]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "conditional with empty string is truthy" {
  let json = Json::String("")
  match parse_query("if . then \"truthy\" else \"falsy\" end") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(results, content="[String(\"truthy\")]")
    }
    Err(e) => fail("Query error: " + e)
  }
}

///|
test "conditional in pipe" {
  let json = Json::Array([
    Json::Number(1.0),
    Json::Number(5.0),
    Json::Number(3.0),
  ])
  match parse_query(".[] | if . > 3 then \"big\" else \"small\" end") {
    Ok(query) => {
      let results = eval(json, query)
      inspect(
        results,
        content="[String(\"small\"), String(\"big\"), String(\"small\")]",
      )
    }
    Err(e) => fail("Query error: " + e)
  }
}
