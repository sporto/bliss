// import gleeunit
import gleeunit/should
import parser as pp

// pub fn main() {
//   gleeunit.main()
// }
pub fn parse_test() {
  let expected = #(1)

  let parser =
    pp.succeed1()
    |> pp.segment("users")
    |> pp.int

  pp.parse("/users/1", parser)
  |> should.equal(Ok(expected))
}
