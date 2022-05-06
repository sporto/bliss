import example_app as app
import gleam/http.{Get, Head, Post}
import gleam/http/request
import gleam/hackney
import gleam/http/elli
import gleeunit/should
import gleeunit

pub fn main() {
  gleeunit.main()
}

// fn service(request: Request(BitString)) -> Response(BitBuilder) {
//   let body = case request.body {
//     <<>> -> bit_builder.from_string("Default body")
//     x -> bit_builder.from_bit_string(x)
//   }
//   response.new(200)
//   |> response.prepend_header("made-with", "Gleam")
//   |> response.set_body(body)
// }
// pub fn get_version_test() {
//   let port = 3078
//   assert Ok(_) = elli.start(app.app(), on_port: port)
//   let req =
//     request.new()
//     |> request.set_scheme(http.Http)
//     |> request.set_host("0.0.0.0")
//     |> request.set_port(port)
//     |> request.set_method(Get)
//     |> request.set_path("/version")
//   assert Ok(resp) = hackney.send(req)
//   assert 200 = resp.status
// }
pub fn blah_test() {
  1
  |> should.equal(1)
}
