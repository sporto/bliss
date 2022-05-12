import gleam/http/request
import gleam/http/response
import gleam/bit_string
import gleam/bit_builder

pub fn fixture_response(status: Int) {
  let body = bit_builder.from_string("Hello")

  response.new(status)
  |> response.set_body(body)
}

pub fn make_handler(resp) {
  fn(_req, _ctx) { Ok(resp) }
}

pub fn request() {
  request.new()
  |> request.set_body(bit_string.from_string(""))
}
