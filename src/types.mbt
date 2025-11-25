///|
pub enum Json {
  Null
  Bool(Bool)
  Number(Double)
  String(String)
  Array(Array[Json])
  Object(Map[String, Json])
} derive(Show, Eq)

///|
pub enum Op {
  Eq
  Neq
  Gt
  Lt
  Gte
  Lte
} derive(Show, Eq)

pub enum Query {
  Identity // .
  Field(String) // .foo
  Index(Int) // [0]
  Iterator // .[]
  Pipe(Query, Query) // q1 | q2
  Sequence(Query, Query) // q1, q2
  ArrayConstructor(Query) // [q]
  ObjectConstructor(Array[(String, Query)]) // {k: v}
  Literal(Json) // 1, "s", true
  Binary(Op, Query, Query) // a == b
  Select(Query) // select(q)
} derive(Show, Eq)
