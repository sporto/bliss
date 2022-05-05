import gleam/option.{None, Option, Some}
import gleam/int
import gleam/string
import gleam/list
import gleam/result
import gleam/pair
import gleam/function

pub opaque type Parser(a) {
  Parser(fn(List(String)) -> Result(#(a, List(String)), String))
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
      |> succeed
    },
  )
}

fn map2(parser_a: Parser(a), parser_b: Parser(b), f: fn(a, b) -> c) -> Parser(c) {
  then(parser_a, fn(a) { map(parser_b, fn(b) { f(a, b) }) })
}

pub fn parse(input: String, parser: Parser(a)) -> Result(a, String) {
  let segments = string.split(input, "/")

  use_parser(parser, segments)
  |> result.map(pair.first)
}

fn use_parser(
  parser: Parser(a),
  segments: List(String),
) -> Result(#(a, List(String)), String) {
  let Parser(p) = parser
  p(segments)
}

fn tuple1(a) {
  #(a)
}

fn tuple2(a) {
  fn(b) { #(a, b) }
}

fn succeed(constructor: cons) -> Parser(cons) {
  let p = fn(input: List(String)) { Ok(#(constructor, input)) }
  Parser(p)
}

pub fn succeed1() -> Parser(fn(a) -> #(a)) {
  succeed(tuple1)
}

pub fn succeed2() -> Parser(fn(a) -> fn(b) -> #(a, b)) {
  succeed(tuple2)
}

pub fn segment_parser(wanted: String) -> Parser(String) {
  let p = fn(input: List(String)) {
    case input {
      [] -> Error("Not enough segments")
      [first, ..rest] ->
        case first == wanted {
          True -> Ok(#(first, rest))
          False -> Error(first)
        }
    }
  }
  Parser(p)
}

pub fn string_parser() -> Parser(String) {
  let p = fn(input: List(String)) {
    case input {
      [] -> Error("Not enough segments")
      [first, ..rest] -> Ok(#(first, rest))
    }
  }
  Parser(p)
}

fn int_parser() -> Parser(Int) {
  let p = fn(input: List(String)) {
    case input {
      [] -> Error("Not enough segments")
      [first, ..rest] ->
        case int.parse(first) {
          Ok(n) -> Ok(#(n, rest))
          Error(_) -> Error("Not a number")
        }
    }
  }
  Parser(p)
}

pub fn discard(keeper: Parser(a), ignorer: Parser(b)) -> Parser(a) {
  map2(keeper, ignorer, fn(a, _) { a })
}

pub fn keep(mapper: Parser(fn(a) -> b), parser: Parser(a)) -> Parser(b) {
  map2(mapper, parser, fn(f, a) { f(a) })
}

pub fn segment(previous, wanted: String) {
  discard(previous, segment_parser(wanted))
}

pub fn int(previous) {
  keep(previous, int_parser())
}
