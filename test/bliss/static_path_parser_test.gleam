// import gleeunit
import gleeunit/should
import bliss/static_path_parser as spp

pub fn top_test() {
  let parser = spp.get0()

  let expected = Ok(spp.ExactMatch(#()))

  spp.parse("/", parser)
  |> should.equal(expected)
}

pub fn more_segments_test() {
  let parser = spp.get0()

  let expected = Ok(spp.PartialMatch(#(), ["users"]))

  spp.parse("/users", parser)
  |> should.equal(expected)
}

pub fn one_segment_test() {
  let parser =
    spp.get0()
    |> spp.seg("users")

  let expected = Ok(spp.ExactMatch(#()))

  spp.parse("/users", parser)
  |> should.equal(expected)
}

pub fn just_segments_test() {
  let parser =
    spp.get0()
    |> spp.seg("users")
    |> spp.seg("active")

  let expected = Ok(spp.ExactMatch(#()))

  spp.parse("/users/active", parser)
  |> should.equal(expected)
}

pub fn get1_test() {
  let parser =
    spp.get1()
    |> spp.seg("users")
    |> spp.int

  let params = #(1)
  let expected = Ok(spp.ExactMatch(params))

  spp.parse("/users/1", parser)
  |> should.equal(expected)
}

pub fn get2_test() {
  let parser =
    spp.get2()
    |> spp.seg("users")
    |> spp.int
    |> spp.seg("hobbies")
    |> spp.str

  let params = #(1, "art")
  let expected = Ok(spp.ExactMatch(params))

  spp.parse("/users/1/hobbies/art", parser)
  |> should.equal(expected)
}

pub fn get3_test() {
  let parser =
    spp.get3()
    |> spp.seg("blog")
    |> spp.int
    |> spp.int
    |> spp.int

  let params = #(2020, 11, 21)
  let expected = Ok(spp.ExactMatch(params))

  spp.parse("/blog/2020/11/21", parser)
  |> should.equal(expected)
}
