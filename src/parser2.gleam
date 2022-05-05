import gleam/int
import gleam/string
import gleam/result
import gleam/pair

type Segments =
  List(String)

pub opaque type Parser(in, out) {
  Parser(fn(in, Segments) -> Result(#(out, Segments), String))
}

type CheckResult(a) {
  Keep(a)
  Discard
  CheckError
}

fn check_int(input: String) {
  case int.parse(input) {
    Ok(n) -> Keep(n)
    Error(_) -> CheckError
  }
}

fn check_str(input: String) {
  Ok(Keep(input))
}

fn check_segment(wanted: String) {
  fn(input: String) {
    case input == wanted {
      True -> Discard
      False -> CheckError
    }
  }
}

fn make_parse(check) -> Parser(int, out) {
  let p = fn(cons: fn(in) -> out, input: Segments) {
    case input {
      [] -> Error("Not enough segments")
      [first, ..rest] ->
        case check(first) {
          Keep(value) -> Ok(#(cons(value), rest))
          Discard -> Ok(#(cons, rest))
          CheckError -> Error(first)
        }
    }
  }
  Parser(p)
}

pub fn int() {
  make_parse(check_int)
}

pub fn str() {
  make_parse(check_str)
}

pub fn segment(wanted: String) {
  make_parse(check_segment(wanted))
}

fn tuple1(a) {
  #(a)
}

fn tuple2(a) {
  fn(b) { #(a, b) }
}

fn build(constructor) {
  Parser(fn(input: Segments) { Ok(#(Keep(constructor), input)) })
}

pub fn build1() {
  build(tuple1)
}

pub fn build2() {
  build(tuple2)
}

pub fn parse(input: String, parser: Parser(in, out)) -> Result(out, String) {
  let segments = string.split(input, "/")

  let Parser(p) = parser

  p(segments)
  |> result.map(pair.first)
}
