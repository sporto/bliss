import app
import gleam/bit_string
import gleam/bit_builder
import gleam/json
import gleam/http
import gleam/http/request
import gleam/http/response
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

fn new_req() {
  request.new()
  |> request.set_method(http.Get)
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
    |> request.set_method(http.Options)

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

fn add_authorisation(req) {
  req
  |> request.prepend_header("Authorization", "Bearer 123")
}

fn set_admin(req) {
  req
  |> request.prepend_header("User-Role", "admin")
}

pub fn api_not_found_test() {
  let req =
    new_req()
    |> add_authorisation
    |> request.set_path("/api/whatever")

  assert 404 = run(req).status
}

pub fn api_unauthorised_test() {
  let req =
    new_req()
    |> request.set_path("/api/languages")

  assert 401 = run(req).status
}

pub fn api_countries_test() {
  let req =
    new_req()
    |> add_authorisation
    |> request.set_path("/api/countries")

  let resp = run(req)

  let body =
    "[{\"code\":\"au\",\"name\":\"Australia\"},{\"code\":\"ar\",\"name\":\"Argentina\"}]"
    |> bit_builder.from_string

  resp.body
  |> should.equal(body)
}

pub fn api_country_cities_test() {
  let req =
    new_req()
    |> add_authorisation
    |> request.set_path("/api/countries/au/cities")

  let resp = run(req)

  let body =
    "[{\"name\":\"Melbourne\"},{\"name\":\"Sydney\"}]"
    |> bit_builder.from_string

  resp.body
  |> should.equal(body)
}

pub fn api_admin_can_delete_test() {
  let req =
    new_req()
    |> add_authorisation
    |> set_admin
    |> request.set_path("/api/countries/au")
    |> request.set_method(http.Delete)

  let resp = run(req)

  assert 200 = resp.status
}

pub fn api_user_cannot_delete_test() {
  let req =
    new_req()
    |> add_authorisation
    |> request.set_path("/api/countries/au")
    |> request.set_method(http.Delete)

  let resp = run(req)

  assert 401 = resp.status
}

pub fn api_cities_test() {
  let req =
    new_req()
    |> add_authorisation
    |> request.set_path("/api/cities")

  let resp = run(req)

  assert 200 = resp.status

  let body =
    "[{\"name\":\"Melbourne\"},{\"name\":\"Sydney\"},{\"name\":\"Buenos Aires\"}]"
    |> bit_builder.from_string

  resp.body
  |> should.equal(body)
}

pub fn api_create_city_as_user_test() {
  // A user is not allowed to create
  let req =
    new_req()
    |> add_authorisation
    |> request.set_path("/api/cities")
    |> request.set_method(http.Post)

  let resp = run(req)

  assert 401 = resp.status
}

pub fn api_create_city_as_admin_test() {
  let req =
    new_req()
    |> add_authorisation
    |> set_admin
    |> request.set_path("/api/cities")
    |> request.set_method(http.Post)

  let resp = run(req)

  assert 201 = resp.status
}

pub fn api_cities_not_found() {
  let req =
    new_req()
    |> add_authorisation
    |> request.set_path("/api/cities")
    |> request.set_method(http.Patch)

  let resp = run(req)

  assert 404 = resp.status
}

pub fn api_get_city_test() {
  let req =
    new_req()
    |> add_authorisation
    |> request.set_path("/api/cities/Sydney")

  let resp = run(req)

  assert 200 = resp.status

  let body =
    "{\"name\":\"Sydney\"}"
    |> bit_builder.from_string

  resp.body
  |> should.equal(body)
}

pub fn api_languages_test() {
  let req =
    new_req()
    |> add_authorisation
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
    |> add_authorisation
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
    |> add_authorisation
    |> request.set_path("/api/languages/xx")

  let resp = run(req)

  assert 404 = resp.status
}

pub fn api_language_countries_test() {
  let req =
    new_req()
    |> add_authorisation
    |> request.set_path("/api/languages/es/countries")

  let resp = run(req)

  assert 200 = resp.status

  let expected_body =
    "[\"ar\"]"
    |> bit_builder.from_string

  resp.body
  |> should.equal(expected_body)
}
