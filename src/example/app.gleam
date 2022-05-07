import bliss.{Handler, WebRequest, WebResponse}
import bliss/middleware
import bliss/static_path_parser as spp
import example/store
import gleam/bit_builder.{BitBuilder}
import gleam/http/elli
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/io
import gleam/json
import gleam/list
import gleam/map
import gleam/option.{None, Option, Some}
import gleam/result

type Context {
  Context(db: String)
}

type ContextAuthenticated {
  ContextAuthenticated(db: String, user: User)
}

type User {
  User(email: String, role: String)
}

fn middleware_track(handler) {
  fn(req: WebRequest, ctx: Context) {
    // Track access to the app
    handler(req, ctx)
  }
}

fn check_token(token) {
  case token == "Bearer 123" {
    True -> Ok(True)
    False -> Error(Nil)
  }
}

fn authenticate(req: WebRequest, ctx: Context) -> Result(User, Nil) {
  // This would check using the cookie and the DB
  // But for the example just use a header
  try token = request.get_header(req.request, "Authorization")

  try _ = check_token(token)

  let role =
    request.get_header(req.request, "User-Role")
    |> result.unwrap("user")
  // Get cookie from request
  // Access the DB using the url in context
  // TODO, set session cookie
  let user = User(email: "sam@sample.com", role: role)
  Ok(user)
}

fn middleware_authenticate(handler) {
  fn(req: WebRequest, ctx: Context) -> WebResponse {
    case authenticate(req, ctx) {
      Ok(user) -> {
        let context_authenticated = ContextAuthenticated(db: ctx.db, user: user)
        handler(req, context_authenticated)
      }
      Error(_) -> Error(bliss.Unauthorised)
    }
  }
}

fn middleware_must_be_admin(handler) {
  fn(req: WebRequest, ctx: ContextAuthenticated) -> WebResponse {
    // io.debug("middleware_must_be_admin")
    // Check that the user is admin
    let is_admin = ctx.user.role == "admin"
    case is_admin {
      True -> handler(req, ctx)
      False -> Error(bliss.Unauthorised)
    }
  }
}

// Serialisers
fn json_of_language(language: store.Language) {
  json.object([
    #("code", json.string(language.code)),
    #("name", json.string(language.name)),
  ])
}

fn json_of_country(country: store.Country) {
  json.object([
    #("code", json.string(country.code)),
    #("name", json.string(country.name)),
  ])
}

fn json_of_city(city: store.City) {
  json.object([#("name", json.string(city.name))])
}

// End points
fn public_home(req: WebRequest, ctx: Context) -> WebResponse {
  let body = bit_builder.from_string("Home")
  let resp =
    response.new(200)
    |> response.set_body(body)

  Ok(resp)
}

fn handler_language_list(
  _req: WebRequest,
  _ctx: ContextAuthenticated,
) -> WebResponse {
  let data =
    store.languages()
    |> json.array(of: json_of_language)

  Ok(bliss.json_response(data))
}

fn handler_language_show(
  req: WebRequest,
  _ctx: ContextAuthenticated,
) -> WebResponse {
  try code =
    map.get(req.params, "id")
    |> result.replace_error(bliss.NotFound)

  try language =
    store.languages()
    |> list.find(fn(lang) { lang.code == code })
    |> result.replace_error(bliss.NotFound)

  let data = json_of_language(language)

  Ok(bliss.json_response(data))
}

fn language_delete(_req: WebRequest, _ctx: ContextAuthenticated) -> WebResponse {
  let body = bit_builder.from_string("")
  let resp =
    response.new(200)
    |> response.set_body(body)
  Ok(resp)
}

fn handler_country_list(
  _req: WebRequest,
  _ctx: ContextAuthenticated,
) -> WebResponse {
  let data =
    store.countries()
    |> json.array(of: json_of_country)

  Ok(bliss.json_response(data))
}

fn handler_country_show(
  req: WebRequest,
  _ctx: ContextAuthenticated,
) -> WebResponse {
  try code =
    map.get(req.params, "id")
    |> result.replace_error(bliss.NotFound)

  try country =
    store.countries()
    |> list.find(fn(country) { country.code == code })
    |> result.replace_error(bliss.NotFound)

  let data = json_of_country(country)

  Ok(bliss.json_response(data))
}

fn handler_country_cities_list(
  req: WebRequest,
  _ctx: ContextAuthenticated,
) -> WebResponse {
  try code =
    map.get(req.params, "id")
    |> result.replace_error(bliss.NotFound)

  try country =
    store.countries()
    |> list.find(fn(country) { country.code == code })
    |> result.replace_error(bliss.NotFound)

  let data = json.array(country.cities, of: json_of_city)

  Ok(bliss.json_response(data))
}

fn public_version(_req: WebRequest, _ctx: Context) -> WebResponse {
  let body = bit_builder.from_string("1.0.0")
  let resp =
    response.new(200)
    |> response.set_body(body)
  Ok(resp)
}

fn public_status(_req: WebRequest, _ctx: Context) -> WebResponse {
  let data =
    json.object([
      #("message", json.string("Operational")),
      #("incidents", json.array([], of: json.string)),
    ])
  Ok(bliss.json_response(data))
}

pub fn app() {
  // The initial context can be any custom type defined by the application
  let initial_context = Context("db_url")

  let public_handlers =
    bliss.one_of([
      bliss.get("/", public_home),
      bliss.get("/version", public_version),
      bliss.get("/status", public_status),
    ])
    |> middleware.cors("*")

  let api_handlers =
    bliss.one_of([
      bliss.get("/languages", handler_language_list),
      bliss.get("/languages/:id", handler_language_show),
      bliss.get("/countries", handler_country_list),
      bliss.get("/countries/:id", handler_country_show),
      bliss.get("/countries/:id/cities", handler_country_cities_list),
      // Some routes can only be used by an admin
      bliss.delete(
        "/countries/:id",
        language_delete
        |> middleware_must_be_admin,
      ),
    ])
    // The middlewares at the bottom of the
    // pipeline are executed first.
    // Middlewares wrap the request,
    // they can modify the request in the way in
    // and the response in the way out.
    //
    // Handle CORS
    |> middleware.cors("https://app.com")
    // Must be authenticated in order to access any app endpoint
    |> middleware_authenticate

  bliss.one_of([
    bliss.scope("/", public_handlers),
    bliss.scope("/api", api_handlers),
  ])
  // Add middleware to track accesss
  |> middleware_track
  |> bliss.service(initial_context)
}

pub fn main() {
  elli.become(app(), on_port: 3000)
}
