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
  Has(Query) // 检查对象是否有键或数组是否有索引 'has(key)'
  In(Query) // 检查值是否在数组中 'in(array)'
  Conditional(Query, Query, Query) // 条件表达式 'if cond then expr1 else expr2 end'
  Map(Query) // 对数组每个元素应用表达式 'map(expr)'
  Add // 数组求和或对象合并 'add'
  Min // 数组最小值 'min'
  Max // 数组最大值 'max'
  Sort // 数组排序 'sort'
  SortBy(Query) // 按表达式排序 'sort_by(expr)'
  GroupBy(Query) // 按表达式分组 'group_by(expr)'
  Unique // 数组去重 'unique'
  UniqueBy(Query) // 按表达式去重 'unique_by(expr)'
  Reverse // 数组反转 'reverse'
  Flatten // 数组扁平化 'flatten'
  FlattenDepth(Int) // 指定深度的数组扁平化 'flatten(depth)'
  Contains(Query) // 检查是否包含 'contains(value)'
  First // 获取第一个元素或结果 'first' 或 'first(expr)'
  FirstExpr(Query) // 获取表达式的第一个结果 'first(expr)'
  Last // 获取最后一个元素或结果 'last' 或 'last(expr)'
  LastExpr(Query) // 获取表达式的最后一个结果 'last(expr)'
  Exit // 退出 REPL 'exit' 或 'exit()'
} derive(Show, Eq)
