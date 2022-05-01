import gleam/http/response.{Response}
import gleam/http/request.{Request}
import gleam/option.{None, Option, Some}

// A handler is a function that takes a request, context and returns a response
pub type Handler(req, res, ctx) =
  fn(Request(req), ctx) -> Option(Response(res))

pub type EndPointHandler(req, res, ctx) =
  fn(Request(req), ctx) -> Response(res)

pub fn one_of(handlers: List(Handler(req, res, ctx))) -> Handler(req, res, ctx) {
  // Call each handler, return if successful
  fn(req, cxt) { None }
}

pub fn scope(
  route: String,
  handlers: Handler(req, res, ctx),
) -> Handler(req, res, ctx) {
  fn(req, ctx) { None }
}

pub fn match(
  route: String,
  method: String,
  handler: EndPointHandler(req, res, ctx),
) -> Handler(req, res, ctx) {
  fn(req, ctx) { None }
}

pub fn get(
  route,
  handler: EndPointHandler(req, res, ctx),
) -> Handler(req, res, ctx) {
  match(route, "get", handler)
}

pub fn any(
  route: String,
  handler: EndPointHandler(req, res, ctx),
) -> Handler(req, res, ctx) {
  match(route, "*", handler)
}

pub fn serve(handler: Handler(req, res, ctx)) {
  None
}

pub type Middleware(req, res, ctx) =
  fn(Request(req), ctx, Handler(req, res, ctx)) -> Option(Response(res))

pub fn middleware(
  fun: Middleware(req, res, ctx),
) -> fn(Handler(req, res, ctx)) -> Handler(req, res, ctx) {
  fn(handler: Handler(req, res, ctx)) {
    fn(req: Request(req), ctx: ctx) { fun(req, ctx, handler) }
  }
}
