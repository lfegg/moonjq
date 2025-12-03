///| Command line parser for jq-style commands

///| Parses commands like: echo '{"name":"John"}' | jq '.'

///|
/// Input source for JSON data
pub enum JsonSource {
  JsonString(String) // Direct JSON string
  JsonFile(String) // Filename to read JSON from
}

///| Parse a command line input and extract JSON source and query

///|
/// Returns (JsonSource, query_string)
pub fn parse_command_line(
  input : String,
) -> Result[(JsonSource, String), String] {
  let trimmed = input.trim(chars=" \t\r\n").to_string()

  // Priority 1: Check if it's just "echo '...'" (output JSON)
  if trimmed.has_prefix("echo ") && not(trimmed.contains("|")) {
    match parse_echo_command(trimmed) {
      Some(json_str) => Ok((JsonSource::JsonString(json_str), "."))
      None => Err("Invalid echo command")
    }
  } else if trimmed.contains("|") && trimmed.contains("jq") {
    // Priority 2: Check if it's a pipe command (echo ... | jq ...)
    parse_pipe_command(trimmed)
  } else if trimmed.has_prefix("jq ") {
    // Priority 3: Check if it's jq 'query' filename format
    parse_jq_file_command(trimmed)
  } else {
    // Just a query - not a shell command
    Err("Not a shell command")
  }
}

///|
/// Parse jq file command: jq 'query' filename
fn parse_jq_file_command(
  input : String,
) -> Result[(JsonSource, String), String] {
  let trimmed = input.trim(chars=" \t\r\n").to_string()
  if trimmed.length() <= 3 {
    return Err("Invalid jq command")
  }

  // Skip "jq "
  let after_jq = trimmed
    .view(start_offset=3, end_offset=trimmed.length())
    .to_string()
    .trim(chars=" \t\r\n")
    .to_string()

  // Check if starts with a quote
  if after_jq.length() < 2 {
    return Err("Invalid jq file command")
  }
  let quote_char = after_jq[0].unsafe_to_char()
  if quote_char != '\'' && quote_char != '"' {
    return Err("Query must be quoted")
  }

  // Find the closing quote
  let mut end_quote_pos = 1
  let mut found = false
  while end_quote_pos < after_jq.length() {
    if after_jq[end_quote_pos].unsafe_to_char() == quote_char {
      found = true
      break
    }
    end_quote_pos = end_quote_pos + 1
  }
  if not(found) {
    return Err("Unclosed quote in query")
  }

  // Extract query (without quotes and unescape)
  let query = unescape_string(
    after_jq.view(start_offset=1, end_offset=end_quote_pos).to_string(),
  )

  // Extract filename (after closing quote)
  if end_quote_pos + 1 < after_jq.length() {
    let filename = after_jq
      .view(start_offset=end_quote_pos + 1, end_offset=after_jq.length())
      .to_string()
      .trim(chars=" \t\r\n")
      .to_string()
    if filename.length() > 0 {
      Ok((JsonSource::JsonFile(filename), query))
    } else {
      Err("Missing filename")
    }
  } else {
    Err("Missing filename")
  }
}

///|
/// Parse pipe command: echo '...' | jq '...'
fn parse_pipe_command(input : String) -> Result[(JsonSource, String), String] {
  // Find the pipe character
  let pipe_pos = match find_pipe_position(input) {
    Some(pos) => pos
    None => return Err("Invalid pipe command")
  }
  let left_part = input
    .view(start_offset=0, end_offset=pipe_pos)
    .to_string()
    .trim(chars=" \t\r\n")
    .to_string()
  let right_part = input
    .view(start_offset=pipe_pos + 1, end_offset=input.length())
    .to_string()
    .trim(chars=" \t\r\n")
    .to_string()

  // Parse left part (echo '...')
  let json_str = match parse_echo_command(left_part) {
    Some(json) => json
    None => return Err("Invalid echo command")
  }

  // Parse right part (jq '...')
  let query_str = match parse_jq_command(right_part) {
    Some(query) => query
    None => return Err("Invalid jq command")
  }
  Ok((JsonSource::JsonString(json_str), query_str))
}

///|
/// Find pipe position (not inside quotes)
fn find_pipe_position(input : String) -> Int? {
  let mut in_single_quote = false
  let mut in_double_quote = false
  let mut i = 0
  while i < input.length() {
    let c = input[i].unsafe_to_char()
    match c {
      '\'' => if not(in_double_quote) { in_single_quote = not(in_single_quote) }
      '"' => if not(in_single_quote) { in_double_quote = not(in_double_quote) }
      '|' => if not(in_single_quote) && not(in_double_quote) { return Some(i) }
      _ => ()
    }
    i = i + 1
  }
  None
}

///|
/// Parse echo command: echo '...' or echo "..."
fn parse_echo_command(cmd : String) -> String? {
  let trimmed = cmd.trim(chars=" \t\r\n").to_string()

  // Check if starts with "echo"
  if not(trimmed.has_prefix("echo")) {
    return None
  }
  if trimmed.length() <= 4 {
    return None
  }
  let after_echo = trimmed
    .view(start_offset=4, end_offset=trimmed.length())
    .to_string()
    .trim(chars=" \t\r\n")
    .to_string()

  // Extract quoted string
  extract_quoted_string(after_echo)
}

///|
/// Parse jq command: jq '...' or just '...'
fn parse_jq_command(cmd : String) -> String? {
  let trimmed = cmd.trim(chars=" \t\r\n").to_string()

  // Check if starts with "jq"
  let query_part = if trimmed.has_prefix("jq") {
    if trimmed.length() <= 2 {
      return None
    }
    trimmed
    .view(start_offset=2, end_offset=trimmed.length())
    .to_string()
    .trim(chars=" \t\r\n")
    .to_string()
  } else {
    trimmed
  }

  // Extract quoted string or return as-is
  match extract_quoted_string(query_part) {
    Some(s) => Some(s)
    None => if query_part.length() > 0 { Some(query_part) } else { None }
  }
}

///|
/// Extract string from quotes (single or double) and unescape
fn extract_quoted_string(s : String) -> String? {
  let trimmed = s.trim(chars=" \t\r\n").to_string()
  if trimmed.length() < 2 {
    return None
  }
  let first = trimmed[0].unsafe_to_char()
  let last = trimmed[trimmed.length() - 1].unsafe_to_char()

  // Check for matching quotes
  if (first == '\'' && last == '\'') || (first == '"' && last == '"') {
    let content = trimmed
      .view(start_offset=1, end_offset=trimmed.length() - 1)
      .to_string()
    // Unescape backslash sequences
    Some(unescape_string(content))
  } else {
    None
  }
}

///|
/// Unescape common backslash sequences
fn unescape_string(s : String) -> String {
  let buf = StringBuilder::new()
  let mut i = 0
  while i < s.length() {
    let c = s[i].unsafe_to_char()
    if c == '\\' && i + 1 < s.length() {
      let next = s[i + 1].unsafe_to_char()
      match next {
        '"' => {
          buf.write_char('"')
          i = i + 2
        }
        '\'' => {
          buf.write_char('\'')
          i = i + 2
        }
        '\\' => {
          buf.write_char('\\')
          i = i + 2
        }
        'n' => {
          buf.write_char('\n')
          i = i + 2
        }
        't' => {
          buf.write_char('\t')
          i = i + 2
        }
        'r' => {
          buf.write_char('\r')
          i = i + 2
        }
        _ => {
          // Not a recognized escape, keep the backslash
          buf.write_char(c)
          i = i + 1
        }
      }
    } else {
      buf.write_char(c)
      i = i + 1
    }
  }
  buf.to_string()
}
