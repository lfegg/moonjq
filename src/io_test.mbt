///|
/// Test IO functions
test "read_line_from_stdin returns None in test environment" {
  // In test environment, stdin is not available
  let result = read_line_from_stdin()
  inspect(result, content="None")
}

///|
test "read_all_stdin returns empty in test environment" {
  // In test environment, stdin returns empty
  let result = read_all_stdin()
  inspect(result.length() == 0, content="true")
}

///|
test "has_stdin_data returns false in test environment" {
  // In test environment, no stdin data
  let result = has_stdin_data()
  inspect(result, content="false")
}
