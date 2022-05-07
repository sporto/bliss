import gleeunit/should
import bliss/dict_path_parser as parser
import gleam/map

pub fn top_test() {
  let expected = Ok(parser.ExactMatch(map.from_list([])))

  parser.parse("/", "/")
  |> should.equal(expected)
}

pub fn left_over_test() {
  let expected_dict =
    [#("id", "12")]
    |> map.from_list

  let expected = Ok(parser.PartialMatch(expected_dict, ["hobbies"]))

  parser.parse("users/:id", "users/12/hobbies")
  |> should.equal(expected)
}

pub fn three_test() {
  let expected_dict =
    [#("year", "2020"), #("month", "3"), #("day", "15")]
    |> map.from_list

  let expected = Ok(parser.ExactMatch(expected_dict))

  parser.parse("blog/:year/:month/:day", "blog/2020/3/15")
  |> should.equal(expected)
}

pub fn no_match_test() {
  parser.parse("users/:id", "people/12")
  |> should.equal(Error(parser.Expected("users")))
}

pub fn not_enough_segments_test() {
  parser.parse("users/:id/hobbies", "users/12")
  |> should.equal(Error(parser.NotEnoughSegments))
}
