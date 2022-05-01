// Middleware
import gleam/http/response.{Response}
import gleam/http/request.{Request}
import gleam/option.{None, Option, Some}
import web.{Handler}

pub type Context =
  String

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

fn middleware_track(req, ctx, handler) {
  // Track access
  handler(req, ctx)
}

fn middleware_authenticate(req, ctx, handler) {
  // Do some authentication
  // Pass the new context
  // TODO
  handler(req, ctx)
}

fn middleware_private_cors(req, ctx, handler) {
  handler(req, ctx)
}

// End points
// Params???
fn home(req: Request(req), ctx: Context) -> Response(String) {
  response.new(200)
}

fn users(req: Request(req), ctx: Context) -> Response(String) {
  response.new(200)
}

fn version(req: Request(req), ctx: Context) -> Response(String) {
  response.new(200)
}

pub fn main() {
  // Initial context???
  let public_api =
    web.one_of([web.get("/version", version)])
    |> web.middleware(middleware_public_cors)

  let app_api =
    web.one_of([web.get("/", home), web.get("/users", users)])
    // Add CORS
    |> web.middleware(middleware_private_cors)
    // Must be authenticated
    |> web.middleware(middleware_authenticate)

  web.one_of([web.scope("/", public_api), web.scope("/app", app_api)])
  // Add middleware to track accesss
  |> web.middleware(middleware_track)
  |> web.serve
}
