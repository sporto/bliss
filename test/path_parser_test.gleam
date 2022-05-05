// import gleeunit
import gleeunit/should
import path_parser as p

pub fn top_test() {
  let parser = p.get0()

  p.parse("/", parser)
  |> should.equal(Ok(#()))
}

pub fn more_segments_test() {
  let parser = p.get0()

  p.parse("/users", parser)
  |> should.equal(Error(p.TooManySegments))
}

pub fn one_segment_test() {
  let parser =
    p.get0()
    |> p.seg("users")

  p.parse("/users", parser)
  |> should.equal(Ok(#()))
}

pub fn just_segments_test() {
  let parser =
    p.get0()
    |> p.seg("users")
    |> p.seg("active")

  p.parse("/users/active", parser)
  |> should.equal(Ok(#()))
}

pub fn get1_test() {
  let parser =
    p.get1()
    |> p.seg("users")
    |> p.int

  p.parse("/users/1", parser)
  |> should.equal(Ok(#(1)))
}

pub fn get2_test() {
  let parser =
    p.get2()
    |> p.seg("users")
    |> p.int
    |> p.seg("hobbies")
    |> p.str

  p.parse("/users/1/hobbies/art", parser)
  |> should.equal(Ok(#(1, "art")))
}

pub fn get3_test() {
  let parser =
    p.get3()
    |> p.seg("blog")
    |> p.int
    |> p.int
    |> p.int

  p.parse("/blog/2020/11/21", parser)
  |> should.equal(Ok(#(2020, 11, 21)))
}
