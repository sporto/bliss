// import gleeunit
import gleeunit/should
import path_parser as p

pub fn top_test() {
  let parser = p.get0()

  let expected = Ok(p.Response(#(), []))

  p.parse("/", parser, False)
  |> should.equal(expected)
}

pub fn more_segments_test() {
  let parser = p.get0()

  let expected = Error(p.TooManySegments)

  p.parse("/users", parser, False)
  |> should.equal(expected)
}

pub fn more_segments_allowed_test() {
  let parser = p.get0()

  let expected = Ok(p.Response(#(), ["users"]))

  p.parse("/users", parser, True)
  |> should.equal(expected)
}

pub fn one_segment_test() {
  let parser =
    p.get0()
    |> p.seg("users")

  let expected = Ok(p.Response(#(), []))

  p.parse("/users", parser, False)
  |> should.equal(expected)
}

pub fn just_segments_test() {
  let parser =
    p.get0()
    |> p.seg("users")
    |> p.seg("active")

  let expected = Ok(p.Response(#(), []))

  p.parse("/users/active", parser, False)
  |> should.equal(expected)
}

pub fn get1_test() {
  let parser =
    p.get1()
    |> p.seg("users")
    |> p.int

  let params = #(1)
  let expected = Ok(p.Response(params, []))

  p.parse("/users/1", parser, False)
  |> should.equal(expected)
}

pub fn get2_test() {
  let parser =
    p.get2()
    |> p.seg("users")
    |> p.int
    |> p.seg("hobbies")
    |> p.str

  let params = #(1, "art")
  let expected = Ok(p.Response(params, []))

  p.parse("/users/1/hobbies/art", parser, False)
  |> should.equal(expected)
}

pub fn get3_test() {
  let parser =
    p.get3()
    |> p.seg("blog")
    |> p.int
    |> p.int
    |> p.int

  let params = #(2020, 11, 21)
  let expected = Ok(p.Response(params, []))

  p.parse("/blog/2020/11/21", parser, False)
  |> should.equal(expected)
}
