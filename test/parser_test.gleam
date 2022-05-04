import gleeunit
import gleeunit/should
import parser as p
import gleam/function.{compose}

// pub fn main() {
//   gleeunit.main()
// }
pub fn parse_test() {
  let expected = #(1)

  p.expect1("/users/1", [p.int])
  |> should.equal(Ok(expected))
}
