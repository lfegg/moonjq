///|
fn main {
  // 获取命令行参数
  let args = @sys.get_cli_args()

  // 检查参数数量或是否请求帮助
  if args.length() < 2 || args[1] == "-h" || args[1] == "--help" {
    print_usage()
    return
  }
  let query_str = args[1]
  // 获取 JSON 输入：可以是直接的 JSON 字符串，也可以是文件路径
  let json_str = if args.length() >= 3 {
    let arg = args[2]
    // 尝试作为文件读取
    @fs.read_file_to_string(arg) catch {
      // 如果读取失败（例如不是文件），则将其视为 JSON 字符串
      _ => arg
    }
  } else {
    "{}" // 默认为空对象
  }

  // 解析查询字符串
  match parse_query(query_str) {
    Ok(query) =>
      // 解析 JSON 输入
      match parse_json(json_str) {
        Ok(json) => {
          // 执行查询
          let results = eval(json, query)
          // 打印结果
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
    Err(e) => {
      println("Error parsing query '" + query_str + "':")
      println(e)
      @sys.exit(1)
    }
  }
}

///|
/// 打印使用说明。
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
