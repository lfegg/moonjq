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
/// 比较操作符枚举。
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
} derive(Show, Eq)

///|
/// 查询 AST (抽象语法树) 枚举。
pub enum Query {
  Identity // 恒等查询 '.'
  Field(String) // 字段访问 '.foo'
  Index(Int) // 数组索引 '[0]'
  Slice(Int?, Int?) // 切片 '[start:end]' - start 和 end 都可以省略
  Iterator // 迭代器 '.[]'
  Recurse // 递归下降 '..'
  Optional(Query) // 可选操作符 'q?' - 安全访问，失败返回 null
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
  Has(String) // 检查对象是否有指定键 'has(key)'
  In(Query) // 检查值是否在数组中 'in(array)'
  Map(Query) // 数组映射 'map(expr)'
  Add // 数组求和/字符串连接 'add'
  Min // 最小值 'min'
  Max // 最大值 'max'
  Sort // 排序 'sort'
  SortBy(Query) // 按表达式排序 'sort_by(expr)'
  GroupBy(Query) // 分组 'group_by(expr)'
  Unique // 去重 'unique'
  UniqueBy(Query) // 按表达式去重 'unique_by(expr)'
  Split(String) // 字符串分割 'split(sep)'
  Join(String) // 数组连接为字符串 'join(sep)'
  StartsWith(String) // 检查字符串是否以指定前缀开始 'startswith(str)'
  EndsWith(String) // 检查字符串是否以指定后缀结束 'endswith(str)'
  Contains(String) // 检查字符串是否包含子串 'contains(str)'
  LTrimStr(String) // 去除字符串左侧前缀 'ltrimstr(str)'
  RTrimStr(String) // 去除字符串右侧后缀 'rtrimstr(str)'
  IfThenElse(Query, Query, Query) // 条件表达式 'if cond then expr1 else expr2 end'
  // 布尔运算符
  And(Query, Query) // 逻辑与 'a and b'
  Or(Query, Query) // 逻辑或 'a or b'
  Not(Query) // 逻辑非 'not(expr)'
  // 空值合并运算符
  Alternative(Query, Query) // 空值替代 'a // b'
  // 类型转换
  ToString // 转换为字符串 'tostring'
  ToNumber // 转换为数字 'tonumber'
  // 更多数组函数
  Reverse // 反转数组 'reverse'
  Flatten // 扁平化数组 'flatten'
  First // 第一个元素 'first'
  Last // 最后一个元素 'last'
} derive(Show, Eq)
