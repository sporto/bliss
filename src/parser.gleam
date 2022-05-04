import gleam/option.{None, Option, Some}
import gleam/int
import gleam/string
import gleam/list
import gleam/result

type SegmentParser {
  SegmentParserInt
  SegmentParserStatic(String)
  SegmentParserString
}

pub const int = SegmentParserInt

type ParseResult {
  ParseResultInt(Int)
  ParseResultString(String)
  ParseResultDiscard
}

type Parameter {
  ParameterInt(Int)
  ParameterString(String)
}

pub fn check_static(
  wanted: String,
  given: String,
) -> Result(ParseResult, String) {
  case given == wanted {
    True -> Ok(ParseResultDiscard)
    False -> Error("given")
  }
}

fn check_int(input: String) -> Result(ParseResult, String) {
  int.parse(input)
  |> result.replace_error(input)
  |> result.map(ParseResultInt)
}

fn parse_pair(tuple: #(String, SegmentParser)) -> Result(ParseResult, String) {
  let #(segment, segment_parser) = tuple
  case segment_parser {
    SegmentParserInt -> check_int(segment)
    SegmentParserStatic(wanted) -> check_static(wanted, segment)
    SegmentParserString -> Ok(ParseResultString(segment))
  }
}

fn result_to_parameter(result: ParseResult) -> Result(Parameter, Nil) {
  case result {
    ParseResultDiscard -> Error(Nil)
    ParseResultString(str) -> Ok(ParameterString(str))
    ParseResultInt(int) -> Ok(ParameterInt(int))
  }
}

fn parse(
  input: String,
  parsers: List(SegmentParser),
) -> Result(List(Parameter), String) {
  let segments = string.split(input, "/")
  // The should be a parser for each segment
  try pairs =
    list.strict_zip(segments, parsers)
    |> result.replace_error("Segments length don't match parsers length")

  try results =
    pairs
    |> list.map(parse_pair)
    |> result.all

  let params =
    results
    |> list.filter_map(result_to_parameter)

  Ok(params)
}

pub fn expect1(input, parsers) -> Result(#(a), String) {
  try results = parse(input, parsers)
  case results {
    [one] ->
      case one {
        ParameterInt(int) -> #(int)
        ParameterString(str) -> #(str)
      }
    _ -> Error("Didn't return one")
  }
}
