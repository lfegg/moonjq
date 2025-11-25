///|
struct Parser {
  input : String
  mut pos : Int
  len : Int
}

///|
fn Parser::new(input : String) -> Parser {
  { input, pos: 0, len: input.length() }
}

///|
fn Parser::peek(self : Parser) -> Char? {
  if self.pos < self.len {
    Some(self.input[self.pos].unsafe_to_char())
  } else {
    None
  }
}

///|
fn Parser::advance(self : Parser) -> Unit {
  self.pos = self.pos + 1
}

///|
fn Parser::skip_whitespace(self : Parser) -> Unit {
  while self.pos < self.len {
    let c = self.input[self.pos].unsafe_to_char()
    match c {
      ' ' | '\t' | '\n' | '\r' => self.pos = self.pos + 1
      _ => break
    }
  }
}

///|
fn Parser::parse_string(self : Parser) -> Result[String, String] {
  if self.peek() != Some('"') {
    return Err("Expected '\"'")
  }
  self.advance()
  let buf = StringBuilder::new()
  while self.pos < self.len {
    let c = self.input[self.pos].unsafe_to_char()
    match c {
      '"' => {
        self.advance()
        return Ok(buf.to_string())
      }
      '\\' => {
        self.advance()
        if self.pos >= self.len {
          return Err("Unexpected EOF in string")
        }
        let escaped = self.input[self.pos].unsafe_to_char()
        match escaped {
          '"' => buf.write_char('"')
          '\\' => buf.write_char('\\')
          '/' => buf.write_char('/')
          'b' => buf.write_char('\b')
          'f' => buf.write_char('\f')
          'n' => buf.write_char('\n')
          'r' => buf.write_char('\r')
          't' => buf.write_char('\t')
          'u' => {
            // TODO: Handle unicode escapes properly
            self.advance()
            self.advance()
            self.advance()
            self.advance()
          }
          _ => return Err("Invalid escape sequence")
        }
        self.advance()
      }
      _ => {
        buf.write_char(c)
        self.advance()
      }
    }
  }
  Err("Unexpected EOF in string")
}

///|
fn Parser::parse_number(self : Parser) -> Result[Double, String] {
  let start = self.pos
  if self.pos < self.len && self.input[self.pos].unsafe_to_char() == '-' {
    self.advance()
  }
  while self.pos < self.len {
    let c = self.input[self.pos].unsafe_to_char()
    if c >= '0' && c <= '9' {
      self.advance()
    } else {
      break
    }
  }
  if self.pos < self.len && self.input[self.pos].unsafe_to_char() == '.' {
    self.advance()
    while self.pos < self.len {
      let c = self.input[self.pos].unsafe_to_char()
      if c >= '0' && c <= '9' {
        self.advance()
      } else {
        break
      }
    }
  }
  if self.pos < self.len {
    let c = self.input[self.pos].unsafe_to_char()
    if c == 'e' || c == 'E' {
      self.advance()
      if self.pos < self.len {
        let sign = self.input[self.pos].unsafe_to_char()
        if sign == '+' || sign == '-' {
          self.advance()
        }
      }
      while self.pos < self.len {
        let c = self.input[self.pos].unsafe_to_char()
        if c >= '0' && c <= '9' {
          self.advance()
        } else {
          break
        }
      }
    }
  }
  
  try {
    let num_str = self.input.view(start_offset=start, end_offset=self.pos).to_string()
    Ok(@strconv.parse_double(num_str))
  } catch {
    _ => Err("Invalid number format")
  }
}

///|
fn Parser::match_string(self : Parser, s : String) -> Bool {
  let len = s.length()
  if self.pos + len > self.len {
    return false
  }
  self.input.view(start_offset=self.pos, end_offset=self.pos+len).to_string() == s
}

///|
fn Parser::parse_json_value(self : Parser) -> Result[Json, String] {
  self.skip_whitespace()
  match self.peek() {
    Some('{') => self.parse_object()
    Some('[') => self.parse_array()
    Some('"') => {
      match self.parse_string() {
        Ok(s) => Ok(Json::String(s))
        Err(e) => Err(e)
      }
    }
    Some('t') => {
      if self.match_string("true") {
        self.pos = self.pos + 4
        Ok(Json::Bool(true))
      } else {
        Err("Expected 'true'")
      }
    }
    Some('f') => {
      if self.match_string("false") {
        self.pos = self.pos + 5
        Ok(Json::Bool(false))
      } else {
        Err("Expected 'false'")
      }
    }
    Some('n') => {
      if self.match_string("null") {
        self.pos = self.pos + 4
        Ok(Json::Null)
      } else {
        Err("Expected 'null'")
      }
    }
    Some(c) => {
      if c == '-' || (c >= '0' && c <= '9') {
        match self.parse_number() {
          Ok(n) => Ok(Json::Number(n))
          Err(e) => Err(e)
        }
      } else {
        Err("Unexpected character: " + c.to_string())
      }
    }
    None => Err("Unexpected EOF")
  }
}

///|
fn Parser::parse_array(self : Parser) -> Result[Json, String] {
  self.advance() // [
  self.skip_whitespace()
  if self.peek() == Some(']') {
    self.advance()
    return Ok(Json::Array([]))
  }
  let arr = []
  while true {
    match self.parse_json_value() {
      Ok(val) => {
        arr.push(val)
        self.skip_whitespace()
        match self.peek() {
          Some(',') => {
            self.advance()
            self.skip_whitespace()
          }
          Some(']') => {
            self.advance()
            break
          }
          _ => return Err("Expected ',' or ']'")
        }
      }
      Err(e) => return Err(e)
    }
  }
  Ok(Json::Array(arr))
}

///|
fn Parser::parse_object(self : Parser) -> Result[Json, String] {
  self.advance() // {
  self.skip_whitespace()
  if self.peek() == Some('}') {
    self.advance()
    return Ok(Json::Object(Map::new()))
  }
  let obj = Map::new()
  while true {
    self.skip_whitespace()
    match self.parse_string() {
      Ok(key) => {
        self.skip_whitespace()
        if self.peek() != Some(':') {
          return Err("Expected ':'")
        }
        self.advance()
        match self.parse_json_value() {
          Ok(val) => {
            obj.set(key, val)
            self.skip_whitespace()
            match self.peek() {
              Some(',') => {
                self.advance()
              }
              Some('}') => {
                self.advance()
                break
              }
              _ => return Err("Expected ',' or '}'")
            }
          }
          Err(e) => return Err(e)
        }
      }
      Err(e) => return Err(e)
    }
  }
  Ok(Json::Object(obj))
}

///|
pub fn parse_json(input : String) -> Result[Json, String] {
  let parser = Parser::new(input)
  parser.parse_json_value()
}

///|
pub fn parse_query(input : String) -> Result[Query, String] {
  let parser = Parser::new(input)
  parser.parse_query_expr()
}

///|
fn Parser::parse_query_expr(self : Parser) -> Result[Query, String] {
  self.parse_sequence()
}

///|
fn Parser::parse_sequence(self : Parser) -> Result[Query, String] {
  match self.parse_compare() {
    Ok(left) => {
      self.skip_whitespace()
      if self.peek() == Some(',') {
        self.advance()
        match self.parse_sequence() {
          Ok(right) => Ok(Query::Sequence(left, right))
          Err(e) => Err(e)
        }
      } else {
        Ok(left)
      }
    }
    Err(e) => Err(e)
  }
}

///|
fn Parser::parse_compare(self : Parser) -> Result[Query, String] {
  match self.parse_pipe() {
    Ok(left) => {
      self.skip_whitespace()
      if self.match_string("==") {
        self.pos = self.pos + 2
        match self.parse_pipe() {
          Ok(right) => Ok(Query::Binary(Op::Eq, left, right))
          Err(e) => Err(e)
        }
      } else if self.match_string("!=") {
        self.pos = self.pos + 2
        match self.parse_pipe() {
          Ok(right) => Ok(Query::Binary(Op::Neq, left, right))
          Err(e) => Err(e)
        }
      } else if self.match_string(">=") {
        self.pos = self.pos + 2
        match self.parse_pipe() {
          Ok(right) => Ok(Query::Binary(Op::Gte, left, right))
          Err(e) => Err(e)
        }
      } else if self.match_string("<=") {
        self.pos = self.pos + 2
        match self.parse_pipe() {
          Ok(right) => Ok(Query::Binary(Op::Lte, left, right))
          Err(e) => Err(e)
        }
      } else if self.peek() == Some('>') {
        self.advance()
        match self.parse_pipe() {
          Ok(right) => Ok(Query::Binary(Op::Gt, left, right))
          Err(e) => Err(e)
        }
      } else if self.peek() == Some('<') {
        self.advance()
        match self.parse_pipe() {
          Ok(right) => Ok(Query::Binary(Op::Lt, left, right))
          Err(e) => Err(e)
        }
      } else {
        Ok(left)
      }
    }
    Err(e) => Err(e)
  }
}

///|
fn Parser::parse_pipe(self : Parser) -> Result[Query, String] {
  match self.parse_term() {
    Ok(left) => {
      let mut current = left
      self.skip_whitespace()
      while self.peek() == Some('|') {
        self.advance()
        match self.parse_term() {
          Ok(right) => {
            current = Query::Pipe(current, right)
            self.skip_whitespace()
          }
          Err(e) => return Err(e)
        }
      }
      Ok(current)
    }
    Err(e) => Err(e)
  }
}

///|
fn Parser::parse_term(self : Parser) -> Result[Query, String] {
  self.skip_whitespace()
  match self.peek() {
    Some('.') => {
      let mut current = Query::Identity
      let mut first = true
      
      while self.peek() == Some('.') {
        self.advance()
        let next = match self.peek() {
          Some('[') => {
            self.advance()
            if self.peek() == Some(']') {
              self.advance()
              Ok(Query::Iterator)
            } else {
              match self.parse_number() {
                Ok(n) => {
                  self.skip_whitespace()
                  if self.peek() == Some(']') {
                    self.advance()
                    Ok(Query::Index(n.to_int()))
                  } else {
                    Err("Expected ']'")
                  }
                }
                Err(_) => Err("Expected ']' or number")
              }
            }
          }
          Some('"') => {
            match self.parse_string() {
              Ok(s) => Ok(Query::Field(s))
              Err(e) => Err(e)
            }
          }
          Some(c) => {
            if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_' {
              let start = self.pos
              while self.pos < self.len {
                let c = self.input[self.pos].unsafe_to_char()
                if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_' {
                  self.advance()
                } else {
                  break
                }
              }
              let field = self.input.view(start_offset=start, end_offset=self.pos).to_string()
              Ok(Query::Field(field))
            } else {
              Ok(Query::Identity)
            }
          }
          None => Ok(Query::Identity)
        }
        
        match next {
          Ok(n) => {
            if first {
              current = n
              first = false
            } else {
              match n {
                Query::Identity => ()
                _ => current = Query::Pipe(current, n)
              }
            }
          }
          Err(e) => return Err(e)
        }
      }
      Ok(current)
    }
    Some('[') => {
      self.advance()
      self.skip_whitespace()
      if self.peek() == Some(']') {
        self.advance()
        Ok(Query::ArrayConstructor(Query::Identity))
      } else {
        match self.parse_query_expr() {
          Ok(q) => {
            if self.peek() == Some(']') {
              self.advance()
              Ok(Query::ArrayConstructor(q))
            } else {
              Err("Expected ']'")
            }
          }
          Err(e) => Err(e)
        }
      }
    }
    Some('{') => {
      self.advance()
      self.skip_whitespace()
      let fields = []
      while true {
        if self.peek() == Some('}') {
          self.advance()
          break
        }
        match self.parse_identifier_or_string() {
          Ok(key) => {
            self.skip_whitespace()
            if self.peek() != Some(':') {
              return Err("Expected ':'")
            }
            self.advance()
            match self.parse_query_expr() {
              Ok(val) => {
                fields.push((key, val))
                self.skip_whitespace()
                if self.peek() == Some(',') {
                  self.advance()
                  self.skip_whitespace()
                } else if self.peek() == Some('}') {
                  self.advance()
                  break
                } else {
                  return Err("Expected ',' or '}'")
                }
              }
              Err(e) => return Err(e)
            }
          }
          Err(e) => return Err(e)
        }
      }
      Ok(Query::ObjectConstructor(fields))
    }
    Some('s') => {
      if self.match_string("select") {
        self.pos = self.pos + 6
        self.skip_whitespace()
        if self.peek() == Some('(') {
          self.advance()
          match self.parse_query_expr() {
            Ok(q) => {
              if self.peek() == Some(')') {
                self.advance()
                Ok(Query::Select(q))
              } else {
                Err("Expected ')'")
              }
            }
            Err(e) => Err(e)
          }
        } else {
          Err("Expected '(' after select")
        }
      } else {
        Err("Unexpected token starting with 's'")
      }
    }
    Some('"') => {
      match self.parse_string() {
        Ok(s) => Ok(Query::Literal(Json::String(s)))
        Err(e) => Err(e)
      }
    }
    Some(c) => {
      if c >= '0' && c <= '9' {
        match self.parse_number() {
          Ok(n) => Ok(Query::Literal(Json::Number(n)))
          Err(e) => Err(e)
        }
      } else {
        Err("Unexpected token in query")
      }
    }
    _ => Err("Unexpected token in query")
  }
}

///|
fn Parser::parse_identifier_or_string(self : Parser) -> Result[String, String] {
  self.skip_whitespace()
  match self.peek() {
    Some('"') => self.parse_string()
    Some(c) => {
      if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_' {
        let start = self.pos
        while self.pos < self.len {
          let c = self.input[self.pos].unsafe_to_char()
          if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_' {
            self.advance()
          } else {
            break
          }
        }
        let s = self.input.view(start_offset=start, end_offset=self.pos).to_string()
        Ok(s)
      } else {
        Err("Expected identifier or string")
      }
    }
    None => Err("Unexpected EOF")
  }
}
