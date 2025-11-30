///| Main entry point - starts REPL mode
fn main {
  repl()
}

///|
fn repl() -> Unit {
  println("moonjq - Interactive JSON processor (jq-compatible)")
  println("Type jq filters or shell commands (e.g., 'echo {...} | jq .')")
  println("Ctrl+C or Ctrl+D to exit.")
  println("")
  
  // Default JSON (will be used if user doesn't provide one in command)
  let json = Json::Null
  
  while true {
    println("jq> ")
    match read_line() {
      Some(input) => {
        let input = input.trim(chars=" \t\r\n").to_string()
        
        // Skip empty lines
        if input == "" {
          continue
        }
        
        // Check if it's a shell-style command (contains pipe)
        match parse_command_line(input) {
          Ok((json_source, query_str)) => {
            // Get JSON data from source (string or file)
            let json_str = match json_source {
              JsonSource::JsonString(s) => s
              JsonSource::JsonFile(filename) => {
                let content = @fs.read_file_to_string(filename) catch {
                  e => {
                    println("Error reading file '" + filename + "': " + e.to_string())
                    "" // Return empty string as fallback
                  }
                }
                if content == "" {
                  continue  // Skip this iteration if file read failed
                }
                content
              }
            }
            
            // Parse JSON from command or file
            match parse_json(json_str) {
              Ok(cmd_json) => {
                // Parse and execute query
                match parse_query(query_str) {
                  Ok(query) => {
                    let results = eval(cmd_json, query)
                    // Check for exit signal
                    if results.length() == 1 {
                      match results[0] {
                        Json::String(s) =>
                          if s == "__EXIT__" {
                            println("Goodbye!")
                            return
                          }
                        _ => ()
                      }
                    }
                    for res in results {
                      println(res.to_json_string())
                    }
                  }
                  Err(e) => println("jq: error: " + e)
                }
              }
              Err(e) => println("Error parsing JSON: " + e)
            }
          }
          Err(_) => {
            // Not a pipe command, treat as normal jq query
            match parse_query(input) {
              Ok(query) => {
                let results = eval(json, query)
                // Check for exit signal
                if results.length() == 1 {
                  match results[0] {
                    Json::String(s) =>
                      if s == "__EXIT__" {
                        println("Goodbye!")
                        return
                      }
                    _ => ()
                  }
                }
                for res in results {
                  println(res.to_json_string())
                }
              }
              Err(e) => println("jq: error: " + e)
            }
          }
        }
      }
      None => break  // EOF (Ctrl+D)
    }
  }
}

///|
fn read_line() -> String? {
  read_line_from_stdin()
}
