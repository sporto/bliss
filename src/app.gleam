// Middleware
import gleam/http/response.{Response}
import gleam/http/request.{Request}
import gleam/option.{None, Option, Some}
import web.{Handler}

type Context {
  Context(db: String)
}

type ContextAuthenticated {
  ContextAuthenticated(db: String, user: String)
}

fn middleware_public_cors(
  req: Request(req),
  ctx: Context,
  handler: Handler(req, res, Context),
) -> Option(Response(res)) {
  // Add something to the request or context
  // Then pass that
  let response = handler(req, ctx)
  // Do something with the response
  response
}

fn middleware_track(req: Request(req), ctx: Context, handler) {
  // Track access to the app
  handler(req, ctx)
}

fn authenticate(req: Request(req), ctx: Context) {
  // Get cookie from request
  // Access the DB using the url in context
  // TODO, set session
  Ok("sam@sample.com")
}

fn middleware_authenticate(
  req: Request(req),
  ctx: Context,
  handler,
) -> Option(Response(String)) {
  case authenticate(req, ctx) {
    Ok(user) -> {
      let context_authenticated = ContextAuthenticated(db: ctx.db, user: user)
      handler(req, context_authenticated)
    }
    Error(_) ->
      //   Return unauthorised
      Some(response.new(401))
  }
}

fn middleware_private_cors(req, ctx, handler) {
  handler(req, ctx)
}

// End points
// Params???
fn home(req: Request(req), ctx: ContextAuthenticated) -> Response(String) {
  response.new(200)
}

fn users(req: Request(req), ctx: ContextAuthenticated) -> Response(String) {
  response.new(200)
}

fn version(req: Request(req), ctx: Context) -> Response(String) {
  response.new(200)
}

pub fn main() {
  let initial_context = Context("db_url")

  let public_api =
    web.one_of([web.get("/version", version)])
    |> web.middleware(middleware_public_cors)

  // TODO can we reverse the middleware, so it natural to write?
  let app_api =
    web.one_of([web.get("/", home), web.get("/users", users)])
    // Add CORS
    |> web.middleware(middleware_private_cors)
    // Must be authenticated
    |> web.middleware(middleware_authenticate)

  web.one_of([web.scope("/", public_api), web.scope("/app", app_api)])
  // Add middleware to track accesss
  |> web.middleware(middleware_track)
  |> web.serve(initial_context)
}
