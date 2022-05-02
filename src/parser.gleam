import gleam/option.{None, Option, Some}
import gleam/int
import gleam/string

type Pair(a, b) =
  #(Result(#(a, b), String), List(String))

pub fn check_segment(wanted: String) -> fn(String) -> Option(Nil) {
  fn(input: String) {
    case input == wanted {
      True -> Some(Nil)
      False -> None
    }
  }
}

pub fn check_int() -> fn(String) -> Option(Int) {
  fn(input: String) {
    case int.parse(input) {
      Ok(num) -> Some(num)
      Error(_) -> None
    }
  }
}

pub fn seg(wanted: String) {
  check_segment(wanted)
  |> step
}

pub fn int() {
  check_int()
  |> step
}

fn step(check: fn(String) -> Option(parsed)) {
  fn(acc_and_input: Pair(previous, parsed)) {
    let #(acc, segments) = acc_and_input
    case acc {
      Ok(previous_tuple) ->
        case segments {
          [] -> #(Error("No more segments to parse"), [])
          [next_segment, ..rest] ->
            case check(next_segment) {
              Some(res) -> #(Ok(#(previous_tuple, res)), rest)
              None -> #(Error(next_segment), rest)
            }
        }

      Error(err) -> #(Error(err), segments)
    }
  }
}

pub fn start(input: String) -> Pair(Nil, Nil) {
  let segments = string.split(input, "/")
  let acc = Ok(#(Nil, Nil))
  #(acc, segments)
}

pub fn end(acc_and_input) {
  let #(res, _) = acc_and_input
  res
}
