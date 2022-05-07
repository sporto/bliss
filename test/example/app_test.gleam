import example/app as app
import gleam/hackney
import gleam/bit_string
import gleam/bit_builder
import gleam/json
import gleam/http.{Get, Head, Options, Post}
import gleam/http/elli
import gleam/http/request
import gleam/http/response
import gleeunit
import gleeunit/should

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
fn new_req() {
  request.new()
  |> request.set_method(Get)
  |> request.set_body(bit_string.from_string(""))
}

fn run(req) {
  app.app()(req)
}

pub fn not_found_test() {
  let req =
    new_req()
    |> request.set_path("/whatever")

  let resp = run(req)

  assert 404 = resp.status
}

pub fn get_home_test() {
  let req =
    new_req()
    |> request.set_path("/")

  let resp = run(req)

  assert 200 = resp.status

  resp.body
  |> should.equal(bit_builder.from_string("Home"))
}

pub fn get_version_test() {
  let req =
    new_req()
    |> request.set_path("/version")

  let resp = run(req)

  assert 200 = resp.status

  resp.body
  |> should.equal(bit_builder.from_string("1.0.0"))
}

pub fn cors_for_public_test() {
  let req =
    new_req()
    |> request.set_path("/version")
    |> request.set_method(Options)

  let resp = run(req)

  assert 202 = resp.status

  resp.headers
  |> should.equal([
    #("access-control-allow-credentials", "true"),
    #("access-control-allow-headers", "Content-Type"),
    #("access-control-allow-methods", "DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT"),
    #("access-control-allow-origin", "*"),
  ])
}

pub fn status_returns_json_test() {
  let req =
    new_req()
    |> request.set_path("/status")

  let resp = run(req)

  assert 200 = resp.status

  assert Ok("application/json") = response.get_header(resp, "Content-Type")

  let body =
    json.object([
      #("message", json.string("Operational")),
      #("incidents", json.array([], of: json.string)),
    ])
    |> json.to_string
    |> bit_builder.from_string

  resp.body
  |> should.equal(body)
}

pub fn api_not_found_test() {
  let req =
    new_req()
    |> request.set_path("/api/whatever")

  assert 404 = run(req).status
}

pub fn api_languages_test() {
  let req =
    new_req()
    |> request.set_path("/api/languages")

  let resp = run(req)

  let body =
    "[{\"code\":\"en\",\"name\":\"English\"},{\"code\":\"es\",\"name\":\"Spanish\"}]"
    |> bit_builder.from_string

  resp.body
  |> should.equal(body)
}

pub fn api_language_test() {
  let req =
    new_req()
    |> request.set_path("/api/languages/es")

  let resp = run(req)

  assert 200 = resp.status

  let expected_body =
    "{\"code\":\"es\",\"name\":\"Spanish\"}"
    |> bit_builder.from_string

  resp.body
  |> should.equal(expected_body)
}

pub fn api_language_not_found_test() {
  let req =
    new_req()
    |> request.set_path("/api/languages/xx")

  let resp = run(req)

  assert 404 = resp.status
}
