import gleam/int
import gleam/string
import gleam/result
import gleam/list

type Segments =
  List(String)

pub opaque type Parser(a) {
  Parser(fn(Segments) -> Result(#(a, Segments), Error))
}

pub type Error {
  NotEnoughSegments
  TooManySegments
  Expected(String)
}

fn then(parser: Parser(a), f: fn(a) -> Parser(b)) -> Parser(b) {
  let p = fn(input) {
    use_parser(parser, input)
    |> result.then(fn(result) {
      let #(value, rest) = result
      use_parser(f(value), rest)
    })
  }
  Parser(p)
}

fn map(parser: Parser(a), f: fn(a) -> b) -> Parser(b) {
  then(
    parser,
    fn(a) {
      f(a)
      |> initial
    },
  )
}

fn map2(parser_a: Parser(a), parser_b: Parser(b), f: fn(a, b) -> c) -> Parser(c) {
  then(parser_a, fn(a) { map(parser_b, fn(b) { f(a, b) }) })
}

pub fn parse(input: String, parser: Parser(a)) -> Result(a, Error) {
  let segments =
    input
    |> string.split("/")
    |> list.filter(fn(seg) { !string.is_empty(seg) })

  try res = use_parser(parser, segments)

  let #(parsed, remainder) = res

  case remainder {
    [] -> Ok(parsed)
    _ -> Error(TooManySegments)
  }
}

fn use_parser(
  parser: Parser(a),
  segments: Segments,
) -> Result(#(a, Segments), Error) {
  let Parser(p) = parser
  p(segments)
}

fn tuple1(a) {
  #(a)
}

fn tuple2(a) {
  fn(b) { #(a, b) }
}

fn tuple3(a) -> fn(b) -> fn(c) -> #(a, b, c) {
  fn(b) { fn(c) { #(a, b, c) } }
}

fn initial(constructor: cons) -> Parser(cons) {
  let p = fn(input: Segments) { Ok(#(constructor, input)) }
  Parser(p)
}

pub fn get0() -> Parser(#()) {
  initial(#())
}

pub fn get1() -> Parser(fn(a) -> #(a)) {
  initial(tuple1)
}

pub fn get2() -> Parser(fn(a) -> fn(b) -> #(a, b)) {
  initial(tuple2)
}

pub fn get3() -> Parser(fn(a) -> fn(b) -> fn(c) -> #(a, b, c)) {
  initial(tuple3)
}

fn check_int(input: String) {
  case int.parse(input) {
    Ok(n) -> Ok(n)
    Error(_) -> Error(Expected("Expected a number"))
  }
}

fn check_str(input: String) {
  Ok(input)
}

fn check_segment(wanted: String) {
  fn(input: String) {
    let expected = string.concat(["Expected ", wanted, ", given ", input, ""])
    case input == wanted {
      True -> Ok(input)
      False -> Error(Expected(expected))
    }
  }
}

fn make_parser(check: fn(String) -> Result(a, Error)) -> Parser(a) {
  Parser(fn(segments: Segments) {
    case segments {
      [] -> Error(NotEnoughSegments)
      [first, ..rest] ->
        case check(first) {
          Ok(value) -> Ok(#(value, rest))
          Error(e) -> Error(e)
        }
    }
  })
}

fn segment_parser(wanted: String) -> Parser(String) {
  make_parser(check_segment(wanted))
}

fn str_parser() -> Parser(String) {
  make_parser(check_str)
}

fn int_parser() -> Parser(Int) {
  make_parser(check_int)
}

fn discard(keeper: Parser(a), ignorer: Parser(b)) -> Parser(a) {
  map2(keeper, ignorer, fn(a, _) { a })
}

fn keep(mapper: Parser(fn(a) -> b), parser: Parser(a)) -> Parser(b) {
  map2(mapper, parser, fn(f, a) { f(a) })
}

pub fn seg(previous, wanted: String) {
  discard(previous, segment_parser(wanted))
}

pub fn int(previous) {
  keep(previous, int_parser())
}

pub fn str(previous) {
  keep(previous, str_parser())
}
