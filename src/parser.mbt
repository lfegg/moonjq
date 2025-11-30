///|
/// 解析器结构体，用于维护解析状态。
struct Parser {
  input : String // 输入字符串
  mut pos : Int // 当前解析位置
  len : Int // 输入字符串长度
}

///|
/// 创建一个新的解析器实例。
fn Parser::new(input : String) -> Parser {
  { input, pos: 0, len: input.length() }
}

///|
/// 查看当前位置的字符，但不移动指针。
fn Parser::peek(self : Parser) -> Char? {
  if self.pos < self.len {
    Some(self.input[self.pos].unsafe_to_char())
  } else {
    None
  }
}

///|
/// 将解析指针向前移动一位。
fn Parser::advance(self : Parser) -> Unit {
  self.pos = self.pos + 1
}

///|
/// 跳过空白字符 (空格, tab, 换行, 回车)。
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
/// 解析 JSON 字符串。
/// 处理双引号包围的字符串，支持基本的转义字符。
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
/// 解析 JSON 数字。
/// 支持整数、浮点数和科学计数法。
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
    let num_str = self.input
      .view(start_offset=start, end_offset=self.pos)
      .to_string()
    Ok(@strconv.parse_double(num_str))
  } catch {
    _ => Err("Invalid number format")
  }
}

///|
/// 检查当前位置是否匹配给定的字符串。
fn Parser::match_string(self : Parser, s : String) -> Bool {
  let len = s.length()
  if self.pos + len > self.len {
    return false
  }
  self.input.view(start_offset=self.pos, end_offset=self.pos + len).to_string() ==
  s
}

///|
/// 解析任意 JSON 值 (对象, 数组, 字符串, 布尔值, null, 数字)。
fn Parser::parse_json_value(self : Parser) -> Result[Json, String] {
  self.skip_whitespace()
  match self.peek() {
    Some('{') => self.parse_object()
    Some('[') => self.parse_array()
    Some('"') =>
      match self.parse_string() {
        Ok(s) => Ok(Json::String(s))
        Err(e) => Err(e)
      }
    Some('t') =>
      if self.match_string("true") {
        self.pos = self.pos + 4
        Ok(Json::Bool(true))
      } else {
        Err("Expected 'true'")
      }
    Some('f') =>
      if self.match_string("false") {
        self.pos = self.pos + 5
        Ok(Json::Bool(false))
      } else {
        Err("Expected 'false'")
      }
    Some('n') =>
      if self.match_string("null") {
        self.pos = self.pos + 4
        Ok(Json::Null)
      } else {
        Err("Expected 'null'")
      }
    Some(c) =>
      if c == '-' || (c >= '0' && c <= '9') {
        match self.parse_number() {
          Ok(n) => Ok(Json::Number(n))
          Err(e) => Err(e)
        }
      } else {
        Err("Unexpected character: " + c.to_string())
      }
    None => Err("Unexpected EOF")
  }
}

///|
/// 解析 JSON 数组。
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
/// 解析 JSON 对象。
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
              Some(',') => self.advance()
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
/// 解析 JSON 字符串的入口函数。
pub fn parse_json(input : String) -> Result[Json, String] {
  let parser = Parser::new(input)
  parser.parse_json_value()
}

///|
/// 解析查询字符串的入口函数。
pub fn parse_query(input : String) -> Result[Query, String] {
  let parser = Parser::new(input)
  parser.parse_query_expr()
}

///|
/// 解析查询表达式。
fn Parser::parse_query_expr(self : Parser) -> Result[Query, String] {
  self.parse_sequence()
}

///|
/// 解析序列操作符 (逗号)。
/// 优先级最低。
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
/// 解析比较操作符 (==, !=, >, <, >=, <=)。
fn Parser::parse_compare(self : Parser) -> Result[Query, String] {
  match self.parse_add_sub() {
    Ok(left) => {
      self.skip_whitespace()
      if self.match_string("==") {
        self.pos = self.pos + 2
        match self.parse_add_sub() {
          Ok(right) => Ok(Query::Binary(Op::Eq, left, right))
          Err(e) => Err(e)
        }
      } else if self.match_string("!=") {
        self.pos = self.pos + 2
        match self.parse_add_sub() {
          Ok(right) => Ok(Query::Binary(Op::Neq, left, right))
          Err(e) => Err(e)
        }
      } else if self.match_string(">=") {
        self.pos = self.pos + 2
        match self.parse_add_sub() {
          Ok(right) => Ok(Query::Binary(Op::Gte, left, right))
          Err(e) => Err(e)
        }
      } else if self.match_string("<=") {
        self.pos = self.pos + 2
        match self.parse_add_sub() {
          Ok(right) => Ok(Query::Binary(Op::Lte, left, right))
          Err(e) => Err(e)
        }
      } else if self.peek() == Some('>') {
        self.advance()
        match self.parse_add_sub() {
          Ok(right) => Ok(Query::Binary(Op::Gt, left, right))
          Err(e) => Err(e)
        }
      } else if self.peek() == Some('<') {
        self.advance()
        match self.parse_add_sub() {
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
/// 解析加减操作符 (+, -)。
fn Parser::parse_add_sub(self : Parser) -> Result[Query, String] {
  match self.parse_mul_div_mod() {
    Ok(left) => {
      let mut current = left
      self.skip_whitespace()
      while true {
        if self.peek() == Some('+') {
          self.advance()
          match self.parse_mul_div_mod() {
            Ok(right) => {
              current = Query::Binary(Op::Add, current, right)
              self.skip_whitespace()
            }
            Err(e) => return Err(e)
          }
        } else if self.peek() == Some('-') {
          self.advance()
          match self.parse_mul_div_mod() {
            Ok(right) => {
              current = Query::Binary(Op::Sub, current, right)
              self.skip_whitespace()
            }
            Err(e) => return Err(e)
          }
        } else {
          break
        }
      }
      Ok(current)
    }
    Err(e) => Err(e)
  }
}

///|
/// 解析乘除模操作符 (*, /, %)。
fn Parser::parse_mul_div_mod(self : Parser) -> Result[Query, String] {
  match self.parse_pipe() {
    Ok(left) => {
      let mut current = left
      self.skip_whitespace()
      while true {
        if self.peek() == Some('*') {
          self.advance()
          match self.parse_pipe() {
            Ok(right) => {
              current = Query::Binary(Op::Mul, current, right)
              self.skip_whitespace()
            }
            Err(e) => return Err(e)
          }
        } else if self.peek() == Some('/') {
          self.advance()
          match self.parse_pipe() {
            Ok(right) => {
              current = Query::Binary(Op::Div, current, right)
              self.skip_whitespace()
            }
            Err(e) => return Err(e)
          }
        } else if self.peek() == Some('%') {
          self.advance()
          match self.parse_pipe() {
            Ok(right) => {
              current = Query::Binary(Op::Mod, current, right)
              self.skip_whitespace()
            }
            Err(e) => return Err(e)
          }
        } else {
          break
        }
      }
      Ok(current)
    }
    Err(e) => Err(e)
  }
}

///|
/// 解析管道操作符 (|)。
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
/// 解析基本项 (字段访问, 索引, 构造器, 字面量, select 等)。
fn Parser::parse_term(self : Parser) -> Result[Query, String] {
  self.skip_whitespace()
  match self.peek() {
    Some('(') => {
      // 括号表达式
      self.advance()
      match self.parse_query_expr() {
        Ok(q) => {
          self.skip_whitespace()
          if self.peek() == Some(')') {
            self.advance()
            Ok(q)
          } else {
            Err("Expected ')'")
          }
        }
        Err(e) => Err(e)
      }
    }
    Some('.') => {
      // Check for recursive descent ..
      if self.pos + 1 < self.len &&
        self.input[self.pos + 1].unsafe_to_char() == '.' {
        self.advance()
        self.advance()
        // After .., we expect either nothing (meaning all values) or a query
        self.skip_whitespace()
        // Recursive descent without filter: .. is equivalent to .. | .
        return Ok(Query::RecursiveDescent(Query::Identity))
      }
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
              // Try to parse slice [start:end] or index [n]
              self.skip_whitespace()
              let mut start : Int? = None
              let mut end : Int? = None

              // Check if starts with colon (means [:end])
              if self.peek() != Some(':') {
                match self.parse_number() {
                  Ok(n) => {
                    start = Some(n.to_int())
                    self.skip_whitespace()
                  }
                  Err(_) => return Err("Expected number or ':'")
                }
              }

              // Check for colon (slice operator)
              if self.peek() == Some(':') {
                self.advance()
                self.skip_whitespace()
                // Check if there's an end value
                if self.peek() != Some(']') {
                  match self.parse_number() {
                    Ok(n) => {
                      end = Some(n.to_int())
                      self.skip_whitespace()
                    }
                    Err(_) => return Err("Expected number or ']'")
                  }
                }
                // It's a slice
                if self.peek() == Some(']') {
                  self.advance()
                  Ok(Query::Slice(start, end))
                } else {
                  Err("Expected ']'")
                }
                // It's a single index
              } else if self.peek() == Some(']') {
                self.advance()
                match start {
                  Some(idx) => Ok(Query::Index(idx))
                  None => Err("Expected index")
                }
              } else {
                Err("Expected ']' or ':'")
              }
            }
          }
          Some('"') =>
            match self.parse_string() {
              Ok(s) => Ok(Query::Field(s))
              Err(e) => Err(e)
            }
          Some(c) =>
            if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_' {
              let start = self.pos
              while self.pos < self.len {
                let c = self.input[self.pos].unsafe_to_char()
                if (c >= 'a' && c <= 'z') ||
                  (c >= 'A' && c <= 'Z') ||
                  (c >= '0' && c <= '9') ||
                  c == '_' {
                  self.advance()
                } else {
                  break
                }
              }
              let field = self.input
                .view(start_offset=start, end_offset=self.pos)
                .to_string()
              Ok(Query::Field(field))
            } else {
              Ok(Query::Identity)
            }
          None => Ok(Query::Identity)
        }
        match next {
          Ok(n) =>
            if first {
              current = n
              first = false
            } else {
              match n {
                Query::Identity => ()
                _ => current = Query::Pipe(current, n)
              }
            }
          Err(e) => return Err(e)
        }
      }

      // After parsing .field, check for [index/slice] without a dot
      // This allows .field[0] or .field[1:3] syntax
      while self.peek() == Some('[') {
        self.advance()
        if self.peek() == Some(']') {
          self.advance()
          current = Query::Pipe(current, Query::Iterator)
        } else {
          // Try to parse slice [start:end] or index [n]
          self.skip_whitespace()
          let mut start : Int? = None
          let mut end : Int? = None

          // Check if starts with colon (means [:end])
          if self.peek() != Some(':') {
            match self.parse_number() {
              Ok(n) => {
                start = Some(n.to_int())
                self.skip_whitespace()
              }
              Err(_) => return Err("Expected number or ':'")
            }
          }

          // Check for colon (slice operator)
          if self.peek() == Some(':') {
            self.advance()
            self.skip_whitespace()
            // Check if there's an end value
            if self.peek() != Some(']') {
              match self.parse_number() {
                Ok(n) => {
                  end = Some(n.to_int())
                  self.skip_whitespace()
                }
                Err(_) => return Err("Expected number or ']'")
              }
            }
            // It's a slice
            if self.peek() == Some(']') {
              self.advance()
              current = Query::Pipe(current, Query::Slice(start, end))
            } else {
              return Err("Expected ']'")
            }
            // It's a single index
          } else if self.peek() == Some(']') {
            self.advance()
            match start {
              Some(idx) => current = Query::Pipe(current, Query::Index(idx))
              None => return Err("Expected index")
            }
          } else {
            return Err("Expected ']' or ':'")
          }
        }
      }

      // Check for optional operator ?
      self.skip_whitespace()
      if self.peek() == Some('?') {
        self.advance()
        current = Query::Optional(current)
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
          Ok(q) =>
            if self.peek() == Some(']') {
              self.advance()
              Ok(Query::ArrayConstructor(q))
            } else {
              Err("Expected ']'")
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
            // Use parse_compare instead of parse_query_expr to avoid comma being parsed as sequence
            match self.parse_compare() {
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
    Some('"') =>
      match self.parse_string() {
        Ok(s) => Ok(Query::Literal(Json::String(s)))
        Err(e) => Err(e)
      }
    Some(c) =>
      if c == '-' {
        // 负数字面量
        match self.parse_number() {
          Ok(n) => Ok(Query::Literal(Json::Number(n)))
          Err(e) => Err(e)
        }
      } else if c >= '0' && c <= '9' {
        match self.parse_number() {
          Ok(n) => Ok(Query::Literal(Json::Number(n)))
          Err(e) => Err(e)
        }
      } else if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_' {
        let start = self.pos
        while self.pos < self.len {
          let c = self.input[self.pos].unsafe_to_char()
          if (c >= 'a' && c <= 'z') ||
            (c >= 'A' && c <= 'Z') ||
            (c >= '0' && c <= '9') ||
            c == '_' {
            self.advance()
          } else {
            break
          }
        }
        let ident = self.input
          .view(start_offset=start, end_offset=self.pos)
          .to_string()
        match ident {
          "length" => Ok(Query::Length)
          "keys" => Ok(Query::Keys)
          "type" => Ok(Query::Type)
          "if" => self.parse_conditional()
          "true" => Ok(Query::Literal(Json::Bool(true)))
          "false" => Ok(Query::Literal(Json::Bool(false)))
          "null" => Ok(Query::Literal(Json::Null))
          "exit" => {
            // Check if followed by ()
            self.skip_whitespace()
            if self.peek() == Some('(') {
              self.advance()
              self.skip_whitespace()
              if self.peek() == Some(')') {
                self.advance()
                Ok(Query::Exit)
              } else {
                Err("Expected ')' after 'exit('")
              }
            } else {
              // exit without parentheses is also valid
              Ok(Query::Exit)
            }
          }
          "select" => {
            self.skip_whitespace()
            if self.peek() == Some('(') {
              self.advance()
              match self.parse_query_expr() {
                Ok(q) =>
                  if self.peek() == Some(')') {
                    self.advance()
                    Ok(Query::Select(q))
                  } else {
                    Err("Expected ')'")
                  }
                Err(e) => Err(e)
              }
            } else {
              Err("Expected '(' after select")
            }
          }
          "has" => {
            self.skip_whitespace()
            if self.peek() == Some('(') {
              self.advance()
              match self.parse_query_expr() {
                Ok(q) =>
                  if self.peek() == Some(')') {
                    self.advance()
                    Ok(Query::Has(q))
                  } else {
                    Err("Expected ')'")
                  }
                Err(e) => Err(e)
              }
            } else {
              Err("Expected '(' after has")
            }
          }
          "in" => {
            self.skip_whitespace()
            if self.peek() == Some('(') {
              self.advance()
              match self.parse_query_expr() {
                Ok(q) =>
                  if self.peek() == Some(')') {
                    self.advance()
                    Ok(Query::In(q))
                  } else {
                    Err("Expected ')'")
                  }
                Err(e) => Err(e)
              }
            } else {
              Err("Expected '(' after in")
            }
          }
          _ => Err("Unknown function or identifier: " + ident)
        }
      } else {
        Err("Unexpected token in query: " + c.to_string())
      }
    _ => Err("Unexpected token in query")
  }
}

///|
/// 解析条件表达式: if cond then expr1 else expr2 end
/// 也支持 elif 链条: if cond1 then expr1 elif cond2 then expr2 else expr3 end
fn Parser::parse_conditional(self : Parser) -> Result[Query, String] {
  // "if" keyword already consumed
  self.skip_whitespace()

  // Parse condition
  match self.parse_compare() {
    Ok(cond) => {
      self.skip_whitespace()

      // Expect "then"
      if not(self.match_keyword("then")) {
        return Err("Expected 'then' in conditional")
      }
      self.pos = self.pos + 4
      self.skip_whitespace()

      // Parse then branch
      match self.parse_compare() {
        Ok(then_branch) => {
          self.skip_whitespace()

          // Check for "elif" or "else"
          if self.match_keyword("elif") {
            // Convert elif to nested if: if c1 then e1 elif c2 then e2 else e3 end
            // becomes: if c1 then e1 else (if c2 then e2 else e3 end) end
            self.pos = self.pos + 4
            // Recursively parse elif as a new conditional (it will handle its own "end")
            match self.parse_conditional() {
              Ok(elif_chain) =>
                // The recursive call already consumed "end", so we're done
                Ok(Query::Conditional(cond, then_branch, elif_chain))
              Err(e) => Err(e)
            }
          } else if self.match_keyword("else") {
            self.pos = self.pos + 4
            self.skip_whitespace()

            // Parse else branch
            match self.parse_compare() {
              Ok(else_branch) => {
                self.skip_whitespace()

                // Expect "end"
                if not(self.match_keyword("end")) {
                  return Err("Expected 'end' to close conditional")
                }
                self.pos = self.pos + 3
                Ok(Query::Conditional(cond, then_branch, else_branch))
              }
              Err(e) => Err(e)
            }
          } else {
            Err("Expected 'elif' or 'else' in conditional")
          }
        }
        Err(e) => Err(e)
      }
    }
    Err(e) => Err(e)
  }
}

///|
/// 检查当前位置是否匹配关键字
fn Parser::match_keyword(self : Parser, keyword : String) -> Bool {
  let klen = keyword.length()
  if self.pos + klen > self.len {
    return false
  }
  let view = self.input.view(start_offset=self.pos, end_offset=self.pos + klen)
  let matches = view.to_string() == keyword
  // Also check that next char is not alphanumeric (to avoid matching "then" in "thenx")
  if matches && self.pos + klen < self.len {
    let next_char = self.input[self.pos + klen].unsafe_to_char()
    if (next_char >= 'a' && next_char <= 'z') ||
      (next_char >= 'A' && next_char <= 'Z') ||
      (next_char >= '0' && next_char <= '9') ||
      next_char == '_' {
      return false
    }
  }
  matches
}

///|
/// 解析标识符或字符串。
/// 用于对象构造中的键名。
fn Parser::parse_identifier_or_string(self : Parser) -> Result[String, String] {
  self.skip_whitespace()
  match self.peek() {
    Some('"') => self.parse_string()
    Some(c) =>
      if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_' {
        let start = self.pos
        while self.pos < self.len {
          let c = self.input[self.pos].unsafe_to_char()
          if (c >= 'a' && c <= 'z') ||
            (c >= 'A' && c <= 'Z') ||
            (c >= '0' && c <= '9') ||
            c == '_' {
            self.advance()
          } else {
            break
          }
        }
        let s = self.input
          .view(start_offset=start, end_offset=self.pos)
          .to_string()
        Ok(s)
      } else {
        Err("Expected identifier or string")
      }
    None => Err("Unexpected EOF")
  }
}
