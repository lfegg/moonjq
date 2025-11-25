///|
fn main {
  let args = @sys.get_cli_args()

  if args.length() < 2 || args[1] == "-h" || args[1] == "--help" {
    print_usage()
    return
  }

  let query_str = args[1]
  let json_str = if args.length() >= 3 {
    let arg = args[2]
    try {
      @fs.read_file_to_string(arg)
    } catch {
      _ => arg
    }
  } else {
    "{}"
  }
  
  match parse_query(query_str) {
    Ok(query) => {
      match parse_json(json_str) {
        Ok(json) => {
          let results = eval(json, query)
          for res in results {
            println(res.to_json_string())
          }
        }
        Err(e) => {
          println("Error parsing JSON input:")
          println(e)
          @sys.exit(1)
        }
      }
    }
    Err(e) => {
      println("Error parsing query '" + query_str + "':")
      println(e)
      @sys.exit(1)
    }
  }
}

fn print_usage() -> Unit {
  let usage =
    #|moonjq - A lightweight JSON processor written in MoonBit
    #|
    #|Usage: moonjq <query> [json_string | file_path]
    #|
    #|Arguments:
    #|  <query>       The jq-like filter to apply to the JSON input.
    #|  [json_string] The JSON string or file path to process. If omitted, defaults to '{}'.
    #|
    #|Options:
    #|  -h, --help    Show this help message and exit.
    #|
    #|Examples:
    #|  moonjq "." '{"a": 1}'
    #|  moonjq ".a" '{"a": 1}'
    #|  moonjq ".[]" '[1, 2, 3]'
    #|  moonjq ".[] | select(. > 1)" '[1, 2, 3]'
    #|
  println(usage)
}
