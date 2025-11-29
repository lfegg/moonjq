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
/// 尝试解析指定的关键字。
/// 如果当前位置的文本匹配关键字，则前进指针并返回 true，否则返回 false。
fn Parser::parse_keyword(self : Parser, keyword : String) -> Bool {
  let kw_len = keyword.length()
  // 检查是否有足够的字符
  if self.pos + kw_len > self.len {
    return false
  }
  // 检查关键字是否匹配
  let matched = self.input
    .view(start_offset=self.pos, end_offset=self.pos + kw_len)
    .to_string() ==
    keyword
  if not(matched) {
    return false
  }
  // 确保关键字后面不是标识符字符（避免 "then" 匹配 "thenx"）
  if self.pos + kw_len < self.len {
    let next_char = self.input[self.pos + kw_len].unsafe_to_char()
    if (next_char >= 'a' && next_char <= 'z') ||
      (next_char >= 'A' && next_char <= 'Z') ||
      (next_char >= '0' && next_char <= '9') ||
      next_char == '_' {
      return false
    }
  }
  // 匹配成功，前进指针
  self.pos = self.pos + kw_len
  true
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
  match self.parse_or() {
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
/// 解析逻辑或操作符 (or)。
fn Parser::parse_or(self : Parser) -> Result[Query, String] {
  match self.parse_and() {
    Ok(left) => {
      self.skip_whitespace()
      if self.parse_keyword("or") {
        self.skip_whitespace()
        match self.parse_or() {
          Ok(right) => Ok(Query::Or(left, right))
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
/// 解析逻辑与操作符 (and)。
fn Parser::parse_and(self : Parser) -> Result[Query, String] {
  match self.parse_alternative() {
    Ok(left) => {
      self.skip_whitespace()
      if self.parse_keyword("and") {
        self.skip_whitespace()
        match self.parse_and() {
          Ok(right) => Ok(Query::And(left, right))
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
/// 解析空值替代操作符 (//)。
fn Parser::parse_alternative(self : Parser) -> Result[Query, String] {
  match self.parse_compare() {
    Ok(left) => {
      self.skip_whitespace()
      if self.match_string("//") {
        self.pos = self.pos + 2
        self.skip_whitespace()
        match self.parse_alternative() {
          Ok(right) => Ok(Query::Alternative(left, right))
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
/// 解析加法和减法操作符 (+, -)。
fn Parser::parse_add_sub(self : Parser) -> Result[Query, String] {
  match self.parse_mul_div() {
    Ok(left) => {
      let mut current = left
      self.skip_whitespace()
      while true {
        if self.peek() == Some('+') {
          self.advance()
          match self.parse_mul_div() {
            Ok(right) => {
              current = Query::Binary(Op::Add, current, right)
              self.skip_whitespace()
            }
            Err(e) => return Err(e)
          }
        } else if self.peek() == Some('-') {
          self.advance()
          match self.parse_mul_div() {
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
/// 解析乘法和除法操作符 (*, /)。
fn Parser::parse_mul_div(self : Parser) -> Result[Query, String] {
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
        } else if self.peek() == Some('/') && not(self.match_string("//")) {
          self.advance()
          match self.parse_pipe() {
            Ok(right) => {
              current = Query::Binary(Op::Div, current, right)
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
  match self.parse_postfix() {
    Ok(left) => {
      let mut current = left
      self.skip_whitespace()
      while self.peek() == Some('|') {
        self.advance()
        match self.parse_postfix() {
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
/// 解析后缀操作符 (?)。
fn Parser::parse_postfix(self : Parser) -> Result[Query, String] {
  match self.parse_term() {
    Ok(expr) => {
      self.skip_whitespace()
      if self.peek() == Some('?') {
        self.advance()
        Ok(Query::Optional(expr))
      } else {
        Ok(expr)
      }
    }
    Err(e) => Err(e)
  }
}

///|
/// 解析基本项 (字段访问, 索引, 构造器, 字面量, select 等)。
fn Parser::parse_term(self : Parser) -> Result[Query, String] {
  self.skip_whitespace()
  match self.peek() {
    // 支持括号表达式
    Some('(') => {
      self.advance()
      self.skip_whitespace()
      match self.parse_query_expr() {
        Ok(expr) => {
          self.skip_whitespace()
          if self.peek() == Some(')') {
            self.advance()
            Ok(expr)
          } else {
            Err("Expected closing ')'")
          }
        }
        Err(e) => Err(e)
      }
    }
    Some('.') => {
      let mut current = Query::Identity
      let mut first = true
      while self.peek() == Some('.') {
        self.advance()

        // 检查是否是递归下降 '..'
        if self.peek() == Some('.') {
          self.advance()
          return Ok(Query::Recurse)
        }
        let next = match self.peek() {
          Some('[') => {
            self.advance()
            self.skip_whitespace()
            if self.peek() == Some(']') {
              self.advance()
              Ok(Query::Iterator)
            } else if self.peek() == Some(':') {
              // 切片 [:end]
              self.advance()
              self.skip_whitespace()
              if self.peek() == Some(']') {
                self.advance()
                Ok(Query::Slice(None, None)) // [:]
              } else {
                match self.parse_number() {
                  Ok(end) => {
                    self.skip_whitespace()
                    if self.peek() == Some(']') {
                      self.advance()
                      Ok(Query::Slice(None, Some(end.to_int())))
                    } else {
                      Err("Expected ']'")
                    }
                  }
                  Err(_) => Err("Expected number or ']'")
                }
              }
            } else {
              match self.parse_number() {
                Ok(n) => {
                  self.skip_whitespace()
                  if self.peek() == Some(']') {
                    self.advance()
                    Ok(Query::Index(n.to_int()))
                  } else if self.peek() == Some(':') {
                    // 切片 [start:end] 或 [start:]
                    self.advance()
                    self.skip_whitespace()
                    if self.peek() == Some(']') {
                      self.advance()
                      Ok(Query::Slice(Some(n.to_int()), None))
                    } else {
                      match self.parse_number() {
                        Ok(end) => {
                          self.skip_whitespace()
                          if self.peek() == Some(']') {
                            self.advance()
                            Ok(
                              Query::Slice(Some(n.to_int()), Some(end.to_int())),
                            )
                          } else {
                            Err("Expected ']'")
                          }
                        }
                        Err(_) => Err("Expected number or ']'")
                      }
                    }
                  } else {
                    Err("Expected ']' or ':'")
                  }
                }
                Err(_) => Err("Expected ']', number or ':'")
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
            // 使用 parse_compare 而不是 parse_query_expr，避免解析逗号作为序列操作符
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
      if c >= '0' && c <= '9' {
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
          "true" => Ok(Query::Literal(Json::Bool(true)))
          "false" => Ok(Query::Literal(Json::Bool(false)))
          "null" => Ok(Query::Literal(Json::Null))
          "if" => {
            self.skip_whitespace()
            match self.parse_query_expr() {
              Ok(cond) => {
                self.skip_whitespace()
                // 期望 "then" 关键字
                if not(self.parse_keyword("then")) {
                  return Err("Expected 'then' after if condition")
                }
                self.skip_whitespace()
                match self.parse_query_expr() {
                  Ok(then_expr) => {
                    self.skip_whitespace()
                    // 期望 "else" 关键字
                    if not(self.parse_keyword("else")) {
                      return Err("Expected 'else' after then expression")
                    }
                    self.skip_whitespace()
                    match self.parse_query_expr() {
                      Ok(else_expr) => {
                        self.skip_whitespace()
                        // 期望 "end" 关键字
                        if not(self.parse_keyword("end")) {
                          return Err("Expected 'end' to close if expression")
                        }
                        Ok(Query::IfThenElse(cond, then_expr, else_expr))
                      }
                      Err(e) => Err(e)
                    }
                  }
                  Err(e) => Err(e)
                }
              }
              Err(e) => Err(e)
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
              self.skip_whitespace()
              match self.parse_string() {
                Ok(key) => {
                  self.skip_whitespace()
                  if self.peek() == Some(')') {
                    self.advance()
                    Ok(Query::Has(key))
                  } else {
                    Err("Expected ')'")
                  }
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
              // 使用 parse_compare 避免解析括号内的逗号为序列操作符
              match self.parse_compare() {
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
          "map" => {
            self.skip_whitespace()
            if self.peek() == Some('(') {
              self.advance()
              // 使用 parse_compare 避免解析括号内的逗号为序列操作符
              match self.parse_compare() {
                Ok(q) =>
                  if self.peek() == Some(')') {
                    self.advance()
                    Ok(Query::Map(q))
                  } else {
                    Err("Expected ')'")
                  }
                Err(e) => Err(e)
              }
            } else {
              Err("Expected '(' after map")
            }
          }
          "add" => Ok(Query::Add)
          "min" => Ok(Query::Min)
          "max" => Ok(Query::Max)
          "sort" => Ok(Query::Sort)
          "sort_by" => {
            self.skip_whitespace()
            if self.peek() == Some('(') {
              self.advance()
              // 使用 parse_compare 避免解析括号内的逗号为序列操作符
              match self.parse_compare() {
                Ok(q) =>
                  if self.peek() == Some(')') {
                    self.advance()
                    Ok(Query::SortBy(q))
                  } else {
                    Err("Expected ')'")
                  }
                Err(e) => Err(e)
              }
            } else {
              Err("Expected '(' after sort_by")
            }
          }
          "group_by" => {
            self.skip_whitespace()
            if self.peek() == Some('(') {
              self.advance()
              // 使用 parse_compare 避免解析括号内的逗号为序列操作符
              match self.parse_compare() {
                Ok(q) =>
                  if self.peek() == Some(')') {
                    self.advance()
                    Ok(Query::GroupBy(q))
                  } else {
                    Err("Expected ')'")
                  }
                Err(e) => Err(e)
              }
            } else {
              Err("Expected '(' after group_by")
            }
          }
          "unique" => Ok(Query::Unique)
          // 新数组函数
          "reverse" => Ok(Query::Reverse)
          "flatten" => Ok(Query::Flatten)
          "first" => Ok(Query::First)
          "last" => Ok(Query::Last)
          // 类型转换
          "tostring" => Ok(Query::ToString)
          "tonumber" => Ok(Query::ToNumber)
          // 逻辑非
          "not" => {
            self.skip_whitespace()
            if self.peek() == Some('(') {
              self.advance()
              match self.parse_query_expr() {
                Ok(q) =>
                  if self.peek() == Some(')') {
                    self.advance()
                    Ok(Query::Not(q))
                  } else {
                    Err("Expected ')'")
                  }
                Err(e) => Err(e)
              }
            } else {
              Err("Expected '(' after not")
            }
          }
          "unique_by" => {
            self.skip_whitespace()
            if self.peek() == Some('(') {
              self.advance()
              // 使用 parse_compare 避免解析括号内的逗号为序列操作符
              match self.parse_compare() {
                Ok(q) =>
                  if self.peek() == Some(')') {
                    self.advance()
                    Ok(Query::UniqueBy(q))
                  } else {
                    Err("Expected ')'")
                  }
                Err(e) => Err(e)
              }
            } else {
              Err("Expected '(' after unique_by")
            }
          }
          "split" => {
            self.skip_whitespace()
            if self.peek() == Some('(') {
              self.advance()
              self.skip_whitespace()
              match self.parse_string() {
                Ok(sep) => {
                  self.skip_whitespace()
                  if self.peek() == Some(')') {
                    self.advance()
                    Ok(Query::Split(sep))
                  } else {
                    Err("Expected ')'")
                  }
                }
                Err(e) => Err(e)
              }
            } else {
              Err("Expected '(' after split")
            }
          }
          "join" => {
            self.skip_whitespace()
            if self.peek() == Some('(') {
              self.advance()
              self.skip_whitespace()
              match self.parse_string() {
                Ok(sep) => {
                  self.skip_whitespace()
                  if self.peek() == Some(')') {
                    self.advance()
                    Ok(Query::Join(sep))
                  } else {
                    Err("Expected ')'")
                  }
                }
                Err(e) => Err(e)
              }
            } else {
              Err("Expected '(' after join")
            }
          }
          "startswith" => {
            self.skip_whitespace()
            if self.peek() == Some('(') {
              self.advance()
              self.skip_whitespace()
              match self.parse_string() {
                Ok(prefix) => {
                  self.skip_whitespace()
                  if self.peek() == Some(')') {
                    self.advance()
                    Ok(Query::StartsWith(prefix))
                  } else {
                    Err("Expected ')'")
                  }
                }
                Err(e) => Err(e)
              }
            } else {
              Err("Expected '(' after startswith")
            }
          }
          "endswith" => {
            self.skip_whitespace()
            if self.peek() == Some('(') {
              self.advance()
              self.skip_whitespace()
              match self.parse_string() {
                Ok(suffix) => {
                  self.skip_whitespace()
                  if self.peek() == Some(')') {
                    self.advance()
                    Ok(Query::EndsWith(suffix))
                  } else {
                    Err("Expected ')'")
                  }
                }
                Err(e) => Err(e)
              }
            } else {
              Err("Expected '(' after endswith")
            }
          }
          "contains" => {
            self.skip_whitespace()
            if self.peek() == Some('(') {
              self.advance()
              self.skip_whitespace()
              match self.parse_string() {
                Ok(substr) => {
                  self.skip_whitespace()
                  if self.peek() == Some(')') {
                    self.advance()
                    Ok(Query::Contains(substr))
                  } else {
                    Err("Expected ')'")
                  }
                }
                Err(e) => Err(e)
              }
            } else {
              Err("Expected '(' after contains")
            }
          }
          "ltrimstr" => {
            self.skip_whitespace()
            if self.peek() == Some('(') {
              self.advance()
              self.skip_whitespace()
              match self.parse_string() {
                Ok(prefix) => {
                  self.skip_whitespace()
                  if self.peek() == Some(')') {
                    self.advance()
                    Ok(Query::LTrimStr(prefix))
                  } else {
                    Err("Expected ')'")
                  }
                }
                Err(e) => Err(e)
              }
            } else {
              Err("Expected '(' after ltrimstr")
            }
          }
          "rtrimstr" => {
            self.skip_whitespace()
            if self.peek() == Some('(') {
              self.advance()
              self.skip_whitespace()
              match self.parse_string() {
                Ok(suffix) => {
                  self.skip_whitespace()
                  if self.peek() == Some(')') {
                    self.advance()
                    Ok(Query::RTrimStr(suffix))
                  } else {
                    Err("Expected ')'")
                  }
                }
                Err(e) => Err(e)
              }
            } else {
              Err("Expected '(' after rtrimstr")
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
