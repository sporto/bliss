import bliss
import bliss/middleware
import gleam/http/request
import gleam/http/response
import gleam/http
import shared
import gleeunit/should

pub fn cors_when_options_test() {
  let handler =
    shared.fixture_response(200)
    |> shared.make_handler
    |> middleware.cors("*", False)

  let req =
    shared.request()
    |> request.set_method(http.Options)

  let resp_result = handler(req, Nil)

  assert Ok(resp) = resp_result
  assert 202 = resp.status

  // It has the CORS headers
  response.get_header(resp, "Access-Control-Allow-Origin")
  |> should.equal(Ok("*"))
}

pub fn cors_when_request_test() {
  let handler =
    shared.fixture_response(418)
    |> shared.make_handler
    |> middleware.cors("*", False)

  let req =
    shared.request()
    |> request.set_method(http.Get)

  let resp_result = handler(req, Nil)

  assert Ok(resp) = resp_result
  assert 418 = resp.status

  // It has the CORS headers
  response.get_header(resp, "Access-Control-Allow-Origin")
  |> should.equal(Ok("*"))

  response.get_header(resp, "Access-Control-Allow-Methods")
  |> should.equal(Ok("DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT"))
}
