///|
/// 测试命令解析器的转义字符处理

///|
test "unescape double quotes" {
  let input = "\\\"hello\\\""
  let result = unescape_string(input)
  inspect(result, content="\"hello\"")
}

///|
test "unescape single quotes" {
  let input = "\\'hello\\'"
  let result = unescape_string(input)
  inspect(result, content="'hello'")
}

///|
test "unescape backslash" {
  let input = "path\\\\to\\\\file"
  let result = unescape_string(input)
  inspect(result, content="path\\to\\file")
}

///|
test "unescape newline" {
  let input = "line1\\nline2"
  let result = unescape_string(input)
  inspect(result, content="line1\nline2")
}

///|
test "unescape tab" {
  let input = "col1\\tcol2"
  let result = unescape_string(input)
  inspect(result, content="col1\tcol2")
}

///|
test "unescape mixed" {
  let input = "{\\\"name\\\":\\\"John\\\"}"
  let result = unescape_string(input)
  inspect(result, content="{\"name\":\"John\"}")
}

///|
test "no escape sequences" {
  let input = "hello world"
  let result = unescape_string(input)
  inspect(result, content="hello world")
}

///|
test "extract quoted string with escapes" {
  let input = "'{\\\"a\\\":1}'"
  match extract_quoted_string(input) {
    Some(result) => inspect(result, content="{\"a\":1}")
    None => fail("Failed to extract quoted string")
  }
}

///|
test "parse echo command with escapes" {
  let cmd = "echo '{\\\"name\\\":\\\"test\\\"}'"
  match parse_echo_command(cmd) {
    Some(result) => inspect(result, content="{\"name\":\"test\"}")
    None => fail("Failed to parse echo command")
  }
}

///|
test "parse command line with escaped JSON" {
  let input = "echo '{\\\"a\\\":1,\\\"b\\\":2}' | jq 'has(\\\"a\\\")'"
  match parse_command_line(input) {
    Ok((json_source, query)) =>
      match json_source {
        JsonSource::JsonString(json) => {
          inspect(json, content="{\"a\":1,\"b\":2}")
          inspect(query, content="has(\"a\")")
        }
        _ => fail("Expected JsonString")
      }
    Err(e) => fail("Parse error: " + e)
  }
}

///|
test "parse jq file command with escapes" {
  let input = "jq 'has(\\\"name\\\")' test.json"
  match parse_command_line(input) {
    Ok((json_source, query)) =>
      match json_source {
        JsonSource::JsonFile(filename) => {
          inspect(filename, content="test.json")
          inspect(query, content="has(\"name\")")
        }
        _ => fail("Expected JsonFile")
      }
    Err(e) => fail("Parse error: " + e)
  }
}

///|
test "complex nested escapes" {
  let input = "echo '[{\\\"x\\\":1},{\\\"y\\\":2}]' | jq '.[0].x'"
  match parse_command_line(input) {
    Ok((json_source, query)) =>
      match json_source {
        JsonSource::JsonString(json) => {
          inspect(json, content="[{\"x\":1},{\"y\":2}]")
          inspect(query, content=".[0].x")
        }
        _ => fail("Expected JsonString")
      }
    Err(e) => fail("Parse error: " + e)
  }
}
