import gleeunit
import gleeunit/should
import parser as p
import gleam/function.{compose}

// pub fn main() {
//   gleeunit.main()
// }
pub fn parse_test() {
  let parser =
    p.start
    |> compose(p.seg("users"))
    |> compose(p.int())
    |> compose(p.end)

  // p.parse("/users/1", parser)
  let expected = #(#(#(Nil, Nil), Nil), 1)
  parser("/users/1")
  |> should.equal(Ok(expected))
}
