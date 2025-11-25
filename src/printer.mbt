
///|
pub fn Json::to_json_string(self : Json) -> String {
  match self {
    Null => "null"
    Bool(true) => "true"
    Bool(false) => "false"
    Number(n) => n.to_string()
    String(s) => "\"" + s + "\"" // TODO: Escape string
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
        buf.write_char('"')
        buf.write_string(k) // TODO: Escape key
        buf.write_string("\": ")
        buf.write_string(v.to_json_string())
      }
      buf.write_char('}')
      buf.to_string()
    }
  }
}
