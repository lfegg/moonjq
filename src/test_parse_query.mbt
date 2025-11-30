///|
/// Test command parser  
test "parse jq file command with array iterator" {
  let input = "jq '.projects[].title' test.json"
  println("Testing: " + input)
  match parse_command_line(input) {
    Ok((JsonSource::JsonFile(file), query)) => {
      println("  File: " + file)
      println("  Query: [" + query + "]")
      println("  Query length: " + query.length().to_string())
      if query == ".projects[].title" {
        println("  ✓ Query matches!")
      } else {
        println("  ✗ Query mismatch!")
        println("  Expected: [.projects[].title]")
      }
    }
    Err(e) => println("  Error: " + e)
    _ => println("  Unexpected result type")
  }
}
