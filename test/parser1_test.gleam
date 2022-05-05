// import gleeunit
import gleeunit/should
import parser2 as p

// pub fn main() {
//   gleeunit.main()
// }
pub fn parse_test() {
  let expected = #(1)

  let parser =
    p.succeed1()
    |> p.segment("users")
    |> p.int

  p.parse("/users/1", parser)
  |> should.equal(Ok(expected))
}
