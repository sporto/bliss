import gleam/list
import gleam/map.{Map}
import gleam/string
import bliss/utils

pub type Error {
  NotEnoughSegments
  Expected(String)
}

pub type Response {
  ExactMatch(parsed: Map(String, String))
  PartialMatch(parsed: Map(String, String), left_over: List(String))
}

fn do_parse(acc, pattern_segments, path_segments) -> Result(Response, Error) {
  case pattern_segments {
    [] ->
      case list.is_empty(path_segments) {
        True -> Ok(ExactMatch(acc))
        False -> Ok(PartialMatch(acc, path_segments))
      }
    [first_pattern, ..rest_pattern] ->
      case path_segments {
        [] -> Error(NotEnoughSegments)
        [first_segment, ..rest_path] ->
          case string.starts_with(first_pattern, ":") {
            True -> {
              let key = string.drop_left(first_pattern, 1)
              let next_acc =
                acc
                |> map.insert(key, first_segment)
              do_parse(next_acc, rest_pattern, rest_path)
            }
            False ->
              case first_pattern == first_segment {
                True -> do_parse(acc, rest_pattern, rest_path)
                False -> Error(Expected(first_pattern))
              }
          }
      }
  }
}

pub fn parse(
  pattern pattern: String,
  path path: String,
) -> Result(Response, Error) {
  let pattern_segments = utils.segments(pattern)

  let path_segments = utils.segments(path)

  do_parse(map.new(), pattern_segments, path_segments)
}
