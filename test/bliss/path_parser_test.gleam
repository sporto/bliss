// import gleeunit
import gleeunit/should
import bliss/path_parser as pp

pub fn top_test() {
  let parser = pp.get0()

  let expected = Ok(pp.ExactMatch(#()))

  pp.parse("/", parser)
  |> should.equal(expected)
}

pub fn more_segments_test() {
  let parser = pp.get0()

  let expected = Ok(pp.PartialMatch(#(), ["users"]))

  pp.parse("/users", parser)
  |> should.equal(expected)
}

pub fn one_segment_test() {
  let parser =
    pp.get0()
    |> pp.seg("users")

  let expected = Ok(pp.ExactMatch(#()))

  pp.parse("/users", parser)
  |> should.equal(expected)
}

pub fn just_segments_test() {
  let parser =
    pp.get0()
    |> pp.seg("users")
    |> pp.seg("active")

  let expected = Ok(pp.ExactMatch(#()))

  pp.parse("/users/active", parser)
  |> should.equal(expected)
}

pub fn get1_test() {
  let parser =
    pp.get1()
    |> pp.seg("users")
    |> pp.int

  let params = #(1)
  let expected = Ok(pp.ExactMatch(params))

  pp.parse("/users/1", parser)
  |> should.equal(expected)
}

pub fn get2_test() {
  let parser =
    pp.get2()
    |> pp.seg("users")
    |> pp.int
    |> pp.seg("hobbies")
    |> pp.str

  let params = #(1, "art")
  let expected = Ok(pp.ExactMatch(params))

  pp.parse("/users/1/hobbies/art", parser)
  |> should.equal(expected)
}

pub fn get3_test() {
  let parser =
    pp.get3()
    |> pp.seg("blog")
    |> pp.int
    |> pp.int
    |> pp.int

  let params = #(2020, 11, 21)
  let expected = Ok(pp.ExactMatch(params))

  pp.parse("/blog/2020/11/21", parser)
  |> should.equal(expected)
}
