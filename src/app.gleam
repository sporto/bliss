// Middleware
import gleam/http/response.{Response}
import gleam/http/request.{Request}
import gleam/option.{None, Option, Some}
import web.{Handler}
import middleware
import gleam/bit_builder.{BitBuilder}

type Context {
  Context(db: String)
}

type ContextAuthenticated {
  ContextAuthenticated(db: String, user: String)
}

fn middleware_track(req: Request(req), ctx: Context, handler) {
  // Track access to the app
  handler(req, ctx)
}

fn authenticate(req: Request(req), ctx: Context) {
  // Get cookie from request
  // Access the DB using the url in context
  // TODO, set session cookie
  Ok("sam@sample.com")
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
      //   Return unauthorised
      let resp =
        response.new(401)
        |> response.set_body(bit_builder.from_string(""))
      Some(resp)
    }
  }
}

// End points
// Params???
fn home(req: Request(req), ctx: ContextAuthenticated) -> Response(BitBuilder) {
  let body = bit_builder.from_string("")
  response.new(200)
  |> response.set_body(body)
}

fn language_list(
  req: Request(req),
  ctx: ContextAuthenticated,
) -> Response(BitBuilder) {
  let body = bit_builder.from_string("")
  response.new(200)
  |> response.set_body(body)
}

fn language_show(
  req: Request(req),
  ctx: ContextAuthenticated,
) -> Response(BitBuilder) {
  let body = bit_builder.from_string("")
  response.new(200)
  |> response.set_body(body)
}

fn language_delete(
  req: Request(req),
  ctx: ContextAuthenticated,
) -> Response(BitBuilder) {
  let body = bit_builder.from_string("")
  response.new(200)
  |> response.set_body(body)
}

fn version(req: Request(req), ctx: Context) -> Response(BitBuilder) {
  let body = bit_builder.from_string("1.0.0")
  response.new(200)
  |> response.set_body(body)
}

fn public_data(req: Request(req), ctx: Context) -> Response(BitBuilder) {
  let body = bit_builder.from_string("{\"message\":\"Hello World\"}")
  response.new(200)
  |> response.set_body(body)
  |> response.prepend_header("content-type", "application/json")
}

pub fn main() {
  let initial_context = Context("db_url")

  let public_api =
    web.route([web.get("/version", version), web.get("/data", public_data)])
    |> web.middleware(middleware.cors("*"))

  // TODO can we reverse the middleware, so it is more natural to write?
  let app_api =
    web.route([
      web.get("/", home),
      web.get("/languages", language_list),
      web.get("/language/:id", language_show),
      web.delete("/language/:id", language_delete),
    ])
    // Add CORS
    |> web.middleware(middleware.cors("https://app.com"))
    // Must be authenticated
    |> web.middleware(middleware_authenticate)

  web.route([web.scope("/", public_api), web.scope("/app", app_api)])
  // Add middleware to track accesss
  |> web.middleware(middleware_track)
  |> web.serve(initial_context)
}
