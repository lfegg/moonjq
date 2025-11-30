///|
/// JSON 数据类型枚举。
pub enum Json {
  Null
  Bool(Bool)
  Number(Double)
  String(String)
  Array(Array[Json])
  Object(Map[String, Json])
} derive(Show, Eq)

///|
/// 操作符枚举（比较和算术）。
pub enum Op {
  // 比较操作符
  Eq // ==
  Neq // !=
  Gt // >
  Lt // <
  Gte // >=
  Lte // <=
  // 算术操作符
  Add // +
  Sub // -
  Mul // *
  Div // /
  Mod // %
} derive(Show, Eq)

///|
/// 查询 AST (抽象语法树) 枚举。
pub enum Query {
  Identity // 恒等查询 '.'
  Field(String) // 字段访问 '.foo'
  Index(Int) // 数组索引 '[0]'
  Slice(Int?, Int?) // 切片 '[start:end]', start 和 end 可选
  Iterator // 迭代器 '.[]'
  RecursiveDescent(Query) // 递归下降 '.. | query'
  Optional(Query) // 可选操作符 'query?'
  Pipe(Query, Query) // 管道 'q1 | q2'
  Sequence(Query, Query) // 序列 'q1, q2'
  ArrayConstructor(Query) // 数组构造 '[q]'
  ObjectConstructor(Array[(String, Query)]) // 对象构造 '{k: v}'
  Literal(Json) // 字面量 '1', '"s"', 'true'
  Binary(Op, Query, Query) // 二元操作 'a == b'
  Select(Query) // 选择/过滤 'select(q)'
  Length // 获取长度 'length'
  Keys // 获取键名 'keys'
  Type // 获取类型 'type'
  Exit // 退出 REPL 'exit' 或 'exit()'
} derive(Show, Eq)
