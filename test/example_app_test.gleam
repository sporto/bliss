import example_app as app
import gleam/http.{Get, Head, Post}
import gleam/http/request
import gleam/hackney

pub fn get_version_test() {
  assert Ok(_) = app.main()

  let req =
    request.new()
    |> request.set_method(Get)
    |> request.set_scheme(http.Http)
    |> request.set_host("0.0.0.0")
    |> request.set_port(3000)
    |> request.set_path("/version")

  assert Ok(resp) = hackney.send(req)
  assert 200 = resp.status
}
