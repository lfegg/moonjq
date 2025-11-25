///|
pub fn eval(json : Json, query : Query) -> Array[Json] {
  match query {
    Identity => [json]
    Field(key) => {
      match json {
        Object(m) => {
          match m.get(key) {
            Some(v) => [v]
            None => [Json::Null]
          }
        }
        _ => [Json::Null]
      }
    }
    Index(idx) => {
      match json {
        Array(arr) => {
          if idx >= 0 && idx < arr.length() {
            [arr[idx]]
          } else {
            [Json::Null]
          }
        }
        _ => [Json::Null]
      }
    }
    Iterator => {
      match json {
        Array(arr) => arr
        Object(obj) => {
          let res = []
          for v in obj.values() {
            res.push(v)
          }
          res
        }
        _ => []
      }
    }
    Literal(v) => [v]
    Binary(op, left, right) => {
      let l_res = eval(json, left)
      let r_res = eval(json, right)
      let res = []
      for l in l_res {
        for r in r_res {
          res.push(Json::Bool(compare(op, l, r)))
        }
      }
      res
    }
    Select(cond) => {
      let cond_res = eval(json, cond)
      for c in cond_res {
        if is_truthy(c) {
          return [json]
        }
      }
      []
    }
    Pipe(left, right) => {
      let results = []
      let left_results = eval(json, left)
      for val in left_results {
        let right_results = eval(val, right)
        results.append(right_results)
      }
      results
    }
    Sequence(left, right) => {
      let results = []
      results.append(eval(json, left))
      results.append(eval(json, right))
      results
    }
    ArrayConstructor(q) => {
      let results = eval(json, q)
      [Json::Array(results)]
    }
    ObjectConstructor(fields) => {
      fn cartesian(index : Int, current_obj : Map[String, Json]) -> Array[Json] {
        if index >= fields.length() {
          return [Json::Object(current_obj)]
        }
        let (key, q) = fields[index]
        let val_results = eval(json, q)
        let results = []
        for val in val_results {
          let new_obj = Map::new()
          current_obj.each(fn(k, v) { new_obj.set(k, v) })
          new_obj.set(key, val)
          results.append(cartesian(index + 1, new_obj))
        }
        results
      }
      cartesian(0, Map::new())
    }
  }
}

///|
fn is_truthy(j : Json) -> Bool {
  match j {
    Null => false
    Bool(false) => false
    _ => true
  }
}

///|
fn compare(op : Op, l : Json, r : Json) -> Bool {
  match op {
    Eq => l == r
    Neq => l != r
    Gt => compare_values(l, r) > 0
    Lt => compare_values(l, r) < 0
    Gte => compare_values(l, r) >= 0
    Lte => compare_values(l, r) <= 0
  }
}

///|
fn compare_values(l : Json, r : Json) -> Int {
  match (l, r) {
    (Number(a), Number(b)) => if a < b { -1 } else if a > b { 1 } else { 0 }
    (String(a), String(b)) => if a < b { -1 } else if a > b { 1 } else { 0 }
    (Bool(a), Bool(b)) => if a == b { 0 } else if a { 1 } else { -1 }
    (Null, Null) => 0
    (Null, _) => -1
    (_, Null) => 1
    _ => 0 // Fallback
  }
}
