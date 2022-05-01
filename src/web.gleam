import gleam/http/response.{Response}
import gleam/http/request.{Request}
import gleam/option.{None, Option, Some}

pub type Context =
  String

// A handler is a function that takes a request, context and returns a response
pub type Handler(req, res) =
  fn(Request(req), Context) -> Option(Response(res))

pub type EndPointHandler(req, res) =
  fn(Request(req), Context) -> Response(res)

pub fn one_of(handlers: List(Handler(req, res))) -> Handler(req, res) {
  // Call each handler, return if successful
  fn(req, cxt) { None }
}

pub fn scope(route: String, handlers: Handler(req, res)) -> Handler(req, res) {
  fn(req, ctx) { None }
}

pub fn match(
  route: String,
  method: String,
  handler: EndPointHandler(req, res),
) -> Handler(req, res) {
  fn(req, ctx) { None }
}

pub fn get(route, handler: EndPointHandler(req, res)) -> Handler(req, res) {
  match(route, "get", handler)
}

pub fn any(
  route: String,
  handler: EndPointHandler(req, res),
) -> Handler(req, res) {
  match(route, "*", handler)
}

pub fn serve(handler: Handler(req, res)) {
  None
}

type Middleware(req, res) =
  fn(Request(req), Context, Handler(req, res)) -> Option(Response(res))

pub fn middleware(
  fun: Middleware(req, res),
) -> fn(Handler(req, res)) -> Handler(req, res) {
  fn(handler: Handler(req, res)) {
    fn(req: Request(req), ctx: Context) { fun(req, ctx, handler) }
  }
}

// Middleware
fn middleware_public_cors(
  req: Request(req),
  ctx: Context,
  handler: Handler(req, res),
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
    one_of([get("/version", version)])
    |> middleware(middleware_public_cors)

  let app_api =
    one_of([match("/", "get", home), match("/users", "get", users)])
    // Add CORS
    |> middleware(middleware_private_cors)
    // Must be authenticated
    |> middleware(middleware_authenticate)

  one_of([scope("/", public_api), scope("/app", app_api)])
  // Add middleware to track accesss
  |> middleware(middleware_track)
  |> serve
}
