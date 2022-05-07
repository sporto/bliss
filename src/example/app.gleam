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

fn middleware_track(req: WebRequest(params), ctx: Context, handler) {
  // Track access to the app
  handler(req, ctx)
}

fn authenticate(req: WebRequest(params), ctx: Context) -> Result(User, String) {
  // Get cookie from request
  // Access the DB using the url in context
  // TODO, set session cookie
  let user = User(email: "sam@sample.com", role: "user")
  Ok(user)
}

fn middleware_authenticate(
  req: WebRequest(params),
  ctx: Context,
  handler,
) -> WebResponse {
  case authenticate(req, ctx) {
    Ok(user) -> {
      let context_authenticated = ContextAuthenticated(db: ctx.db, user: user)
      handler(req, context_authenticated)
    }
    Error(_) -> Error(bliss.ResponseErrorUnauthorised)
  }
}

fn middleware_must_be_admin(
  req: WebRequest(params),
  ctx: ContextAuthenticated,
  handler,
) {
  // io.debug("middleware_must_be_admin")
  // Check that the user is admin
  let is_admin = ctx.user.role == "admin"
  case is_admin {
    True -> handler(req, ctx)
    False -> Error(bliss.ResponseErrorUnauthorised)
  }
}

// Serialisers
fn json_of_language(language: store.Language) {
  json.object([
    #("code", json.string(language.code)),
    #("name", json.string(language.name)),
  ])
}

// End points
fn public_home(req: WebRequest(params), ctx: Context) -> WebResponse {
  let body = bit_builder.from_string("Home")
  let resp =
    response.new(200)
    |> response.set_body(body)

  Ok(resp)
}

fn handler_language_list(
  _req: WebRequest(params),
  _ctx: ContextAuthenticated,
) -> WebResponse {
  let data =
    store.languages()
    |> json.array(of: json_of_language)

  Ok(bliss.json_response(data))
}

fn handler_language_show(
  req: WebRequest(#(a, #(String))),
  _ctx: ContextAuthenticated,
) -> WebResponse {
  let params = req.params

  let #(_, #(code)) = params

  try language =
    store.languages()
    |> list.find(fn(lang) { lang.code == code })
    |> result.replace_error(bliss.ResponseErrorNotFound)

  let data = json_of_language(language)

  Ok(bliss.json_response(data))
}

fn language_delete(
  _req: WebRequest(params),
  _ctx: ContextAuthenticated,
) -> WebResponse {
  let body = bit_builder.from_string("")
  let resp =
    response.new(200)
    |> response.set_body(body)
  Ok(resp)
}

fn country_show(
  _req: WebRequest(params),
  _ctx: ContextAuthenticated,
) -> WebResponse {
  let body = bit_builder.from_string("")
  let resp =
    response.new(200)
    |> response.set_body(body)
  Ok(resp)
}

fn country_cities_list(
  _req: WebRequest(params),
  _ctx: ContextAuthenticated,
) -> WebResponse {
  let body = bit_builder.from_string("")
  let resp =
    response.new(200)
    |> response.set_body(body)
  Ok(resp)
}

fn public_version(req: WebRequest(params), ctx: Context) -> WebResponse {
  let body = bit_builder.from_string("1.0.0")
  let resp =
    response.new(200)
    |> response.set_body(body)
  Ok(resp)
}

fn public_status(req: WebRequest(params), ctx: Context) -> WebResponse {
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

  // Define some application paths
  // Using the static path parser
  // This parser yields tuples with known types
  // e.g. #(Int, String, Int) depending on how the parser is constructed
  // This parser yields #()
  let path_version =
    spp.yield0()
    |> spp.seg("version")

  let path_status =
    spp.yield0()
    |> spp.seg("status")

  let path_top = spp.yield0()

  let path_languages =
    spp.yield0()
    |> spp.seg("languages")

  // This parser yields #(Int)
  let path_language =
    spp.yield1()
    |> spp.seg("languages")
    |> spp.str

  let path_api =
    spp.yield0()
    |> spp.seg("api")

  let public_api =
    bliss.route([
      bliss.get(path_top, public_home),
      bliss.get(path_version, public_version),
      bliss.get(path_status, public_status),
    ])
    |> bliss.middleware(middleware.cors("*"))

  let app_api =
    bliss.route([
      bliss.get(path_languages, handler_language_list),
      bliss.get(path_language, handler_language_show),
      // We can also match using a simple string parser
      // This yield a dictionary for the parameters
      bliss.get_dict("/countries/:id", country_show),
      bliss.get_dict("/countries/:id/cities", country_cities_list),
      // Some routes can only be used by an admin
      bliss.delete(
        path_language,
        language_delete
        |> bliss.middleware(middleware_must_be_admin),
      ),
    ])
    // Add middlewares
    // The middlewares at the bottom of the pipeline are executed first
    // Middleware wrap the request, they can modify the request in the way in
    // and the response in the way out
    //
    // Handle CORS
    |> bliss.middleware(middleware.cors("https://app.com"))
    // Must be authenticated in order to access any app endpoint
    |> bliss.middleware(middleware_authenticate)

  bliss.route([
    bliss.scope(path_top, public_api),
    bliss.scope(path_api, app_api),
  ])
  // Add middleware to track accesss
  |> bliss.middleware(middleware_track)
  |> bliss.service(initial_context)
}

pub fn main() {
  elli.become(app(), on_port: 3000)
}
