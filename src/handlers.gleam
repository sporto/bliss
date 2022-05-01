/////

import gleam/option.{None, Option, Some}

// pub type Handler{
//   Handler(
//   )
// }
pub type Request =
  String

pub type Context =
  String

pub type Response =
  String

// A handler is a function that takes a request, context and returns a response
pub type Handler =
  fn(Request, Context) -> Option(Response)

pub type EndPointHandler =
  fn(Request, Context) -> Response

pub fn one_of(handlers: List(Handler)) -> Handler {
  // Call each handler, return if successful
  fn(req, cxt) { None }
}

pub fn scope(route: String, handlers: Handler) -> Handler {
  fn(req, ctx) { None }
}

pub fn match(route: String, method: String, handler: EndPointHandler) -> Handler {
  fn(req, ctx) { None }
}

pub fn get(route, handler: EndPointHandler) -> Handler {
  match(route, "get", handler)
}

pub fn any(route: String, handler: EndPointHandler) -> Handler {
  match(route, "*", handler)
}

pub fn serve(handler: Handler) {
  None
}

type Middleware =
  fn(Request, Context, Handler) -> Option(Response)

pub fn middleware(fun: Middleware) -> fn(Handler) -> Handler {
  fn(handler: Handler) {
    fn(req: Request, ctx: Context) { fun(req, ctx, handler) }
  }
}

// Middleware
fn public_cors(req: Request, ctx: Context, handler: Handler) -> Option(Response) {
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

// End points
// Params???
fn home(req, ctx) {
  ""
}

fn users(req, ctx) {
  ""
}

fn version(req, ctx) {
  ""
}

pub fn main() {
  // Initial context???
  // public not auth, CORS for everyone
  // private must be auth, set user in context and CORS only one site
  let public_cors_middleware = middleware(public_cors)

  let public_api =
    one_of([get("/version", version)])
    |> public_cors_middleware

  let app_api = one_of([match("/", "get", home), match("/users", "get", users)])

  let api =
    [scope("/", public_api), scope("/app", app_api)]
    |> one_of
    |> middleware(middleware_track)

  serve(api)
}
