
test "string_view" {
  let s = "hello world"
  let v = s.view(start_offset=0, end_offset=5)
  inspect(v, content="hello")
  // inspect!(v == "hello", content="true") // Check equality
}
