import bliss.{Handler, WebRequest, WebResponse}
import bliss/middleware
import bliss/static_path_parser as spp
import gleam/bit_builder.{BitBuilder}
import gleam/http/elli
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/option.{None, Option, Some}

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
) -> Option(WebResponse) {
  case authenticate(req, ctx) {
    Ok(user) -> {
      let context_authenticated = ContextAuthenticated(db: ctx.db, user: user)
      handler(req, context_authenticated)
    }
    Error(_) -> {
      // Return unauthorised
      let resp =
        response.new(401)
        |> response.set_body(bit_builder.from_string(""))
      Some(resp)
    }
  }
}

fn middleware_must_be_admin(
  req: WebRequest(params),
  ctx: ContextAuthenticated,
  handler,
) {
  // Check that the user is admin
  let is_admin = ctx.user.role == "admin"
  case is_admin {
    True -> handler(req, ctx)
    False -> {
      let resp =
        response.new(401)
        |> response.set_body(bit_builder.from_string(""))
      Some(resp)
    }
  }
}

// End points
fn home(req: WebRequest(params), ctx: ContextAuthenticated) -> WebResponse {
  let body = bit_builder.from_string("")
  response.new(200)
  |> response.set_body(body)
}

fn language_list(
  req: WebRequest(params),
  ctx: ContextAuthenticated,
) -> WebResponse {
  let body = bit_builder.from_string("")
  response.new(200)
  |> response.set_body(body)
}

fn language_show(
  req: WebRequest(params),
  ctx: ContextAuthenticated,
) -> WebResponse {
  let body = bit_builder.from_string("")
  response.new(200)
  |> response.set_body(body)
}

fn language_delete(
  req: WebRequest(params),
  ctx: ContextAuthenticated,
) -> WebResponse {
  let body = bit_builder.from_string("")
  response.new(200)
  |> response.set_body(body)
}

fn country_show(
  req: WebRequest(params),
  ctx: ContextAuthenticated,
) -> WebResponse {
  let body = bit_builder.from_string("")
  response.new(200)
  |> response.set_body(body)
}

fn country_cities_list(
  req: WebRequest(params),
  ctx: ContextAuthenticated,
) -> WebResponse {
  let body = bit_builder.from_string("")
  response.new(200)
  |> response.set_body(body)
}

fn version(req: WebRequest(params), ctx: Context) -> WebResponse {
  let body = bit_builder.from_string("1.0.0")
  response.new(200)
  |> response.set_body(body)
}

fn public_data(req: WebRequest(params), ctx: Context) -> WebResponse {
  let body = bit_builder.from_string("{\"message\":\"Hello World\"}")
  response.new(200)
  |> response.set_body(body)
  |> response.prepend_header("content-type", "application/json")
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
    spp.get0()
    |> spp.seg("version")

  let path_data =
    spp.get0()
    |> spp.seg("data")

  let path_top = spp.get0()

  let path_languages =
    spp.get0()
    |> spp.seg("languages")

  // This parser yields #(Int)
  let path_language =
    spp.get1()
    |> spp.seg("languages")
    |> spp.int

  let path_app =
    spp.get0()
    |> spp.seg("app")

  let public_api =
    bliss.route([
      bliss.get(path_version, version),
      bliss.get(path_data, public_data),
    ])
    |> bliss.middleware(middleware.cors("*"))

  let app_api =
    bliss.route([
      bliss.get(path_top, home),
      bliss.get(path_languages, language_list),
      bliss.get(path_language, language_show),
      // We can also match using a simple string parser
      // This yield a dictionary for the parameters
      bliss.get_dict("/countries/:id", country_show),
      bliss.get_dict("/countries/:id/cities", country_cities_list),
      // Some routes can only be used by an admin
      bliss.route([bliss.delete(path_language, language_delete)])
      |> bliss.middleware(middleware_must_be_admin),
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
    bliss.scope(path_app, app_api),
  ])
  // Add middleware to track accesss
  |> bliss.middleware(middleware_track)
  // Start the server
  |> bliss.service(initial_context)
}

pub fn main() {
  elli.become(app(), on_port: 3000)
}
