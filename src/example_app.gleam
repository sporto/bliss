// Middleware
import gleam/http/response.{Response}
import gleam/http/request.{Request}
import gleam/option.{None, Option, Some}
import web_server.{Handler} as web
import middleware
import gleam/bit_builder.{BitBuilder}
import path_parser as pp
import gleam/http/elli

type Context {
  Context(db: String)
}

type ContextAuthenticated {
  ContextAuthenticated(db: String, user: User)
}

type User {
  User(email: String, role: String)
}

fn middleware_track(req: Request(req), ctx: Context, handler) {
  // Track access to the app
  handler(req, ctx)
}

fn authenticate(req: Request(req), ctx: Context) -> Result(User, String) {
  // Get cookie from request
  // Access the DB using the url in context
  // TODO, set session cookie
  let user = User(email: "sam@sample.com", role: "user")
  Ok(user)
}

fn middleware_authenticate(
  req: Request(req),
  ctx: Context,
  handler,
) -> Option(Response(BitBuilder)) {
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

fn middleware_must_be_admin(req, ctx: ContextAuthenticated, handler) {
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
fn home(req: Request(req), ctx: ContextAuthenticated, _) -> Response(BitBuilder) {
  let body = bit_builder.from_string("")
  response.new(200)
  |> response.set_body(body)
}

fn language_list(
  req: Request(req),
  ctx: ContextAuthenticated,
  _,
) -> Response(BitBuilder) {
  let body = bit_builder.from_string("")
  response.new(200)
  |> response.set_body(body)
}

fn language_show(
  req: Request(req),
  ctx: ContextAuthenticated,
  params,
) -> Response(BitBuilder) {
  let body = bit_builder.from_string("")
  response.new(200)
  |> response.set_body(body)
}

fn language_delete(
  req: Request(req),
  ctx: ContextAuthenticated,
  params,
) -> Response(BitBuilder) {
  let body = bit_builder.from_string("")
  response.new(200)
  |> response.set_body(body)
}

fn version(req: Request(req), ctx: Context, _) -> Response(BitBuilder) {
  let body = bit_builder.from_string("1.0.0")
  response.new(200)
  |> response.set_body(body)
}

fn public_data(req: Request(req), ctx: Context, _) -> Response(BitBuilder) {
  let body = bit_builder.from_string("{\"message\":\"Hello World\"}")
  response.new(200)
  |> response.set_body(body)
  |> response.prepend_header("content-type", "application/json")
}

pub fn app() {
  let initial_context = Context("db_url")

  // Define application paths
  let path_version =
    pp.get0()
    |> pp.seg("version")

  let path_data =
    pp.get0()
    |> pp.seg("data")

  let path_top = pp.get0()

  let path_languages =
    pp.get0()
    |> pp.seg("languages")

  let path_language =
    pp.get1()
    |> pp.seg("languages")
    |> pp.int

  let path_app =
    pp.get0()
    |> pp.seg("app")

  let public_api =
    web.route([web.get(path_version, version), web.get(path_data, public_data)])
    |> web.middleware(middleware.cors("*"))

  let app_api =
    web.route([
      web.get(path_top, home),
      web.get(path_languages, language_list),
      web.get(path_language, language_show),
      // Some routes can only be used by an admin
      web.route([web.delete(path_language, language_delete)])
      |> web.middleware(middleware_must_be_admin),
    ])
    // Add middlewares
    // The middlewares at the bottom of the pipeline are executed first
    // Middleware wrap the request, they can modify the request in the way in
    // and the response in the way out
    //
    // Handle CORS
    |> web.middleware(middleware.cors("https://app.com"))
    // Must be authenticated in order to access any app endpoint
    |> web.middleware(middleware_authenticate)

  web.route([web.scope(path_top, public_api), web.scope(path_app, app_api)])
  // Add middleware to track accesss
  |> web.middleware(middleware_track)
  // Start the server
  |> web.service(initial_context)
}

pub fn main() {
  elli.become(app(), on_port: 3000)
}
