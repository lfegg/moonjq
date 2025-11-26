
///|
fn escape_string(s : String) -> String {
  let buf = StringBuilder::new()
  buf.write_char('"')
  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i].unsafe_to_char()
    match c {
      '"' => buf.write_string("\\\"")
      '\\' => buf.write_string("\\\\")
      '\b' => buf.write_string("\\b")
      '\f' => buf.write_string("\\f")
      '\n' => buf.write_string("\\n")
      '\r' => buf.write_string("\\r")
      '\t' => buf.write_string("\\t")
      _ => {
        let code = c.to_int()
        if code < 0x20 {
          buf.write_string("\\u00")
          let hex = "0123456789abcdef"
          buf.write_char(hex[(code >> 4) & 0xF].unsafe_to_char())
          buf.write_char(hex[code & 0xF].unsafe_to_char())
        } else {
          buf.write_char(c)
        }
      }
    }
  }
  buf.write_char('"')
  buf.to_string()
}

/// 将 Json 值转换为 JSON 字符串表示。
pub fn Json::to_json_string(self : Json) -> String {
  match self {
    Null => "null"
    Bool(true) => "true"
    Bool(false) => "false"
    Number(n) => n.to_string()
    String(s) => escape_string(s)
    Array(arr) => {
      let buf = StringBuilder::new()
      buf.write_char('[')
      for i = 0; i < arr.length(); i = i + 1 {
        if i > 0 {
          buf.write_string(", ")
        }
        buf.write_string(arr[i].to_json_string())
      }
      buf.write_char(']')
      buf.to_string()
    }
    Object(obj) => {
      let buf = StringBuilder::new()
      buf.write_char('{')
      let mut first = true
      for k, v in obj {
        if not(first) {
          buf.write_string(", ")
        }
        first = false
        buf.write_string(escape_string(k))
        buf.write_string(": ")
        buf.write_string(v.to_json_string())
      }
      buf.write_char('}')
      buf.to_string()
    }
  }
}
