import gleam/http/response.{Response}
import gleam/http/request.{Request}
import gleam/option.{None, Option, Some}
import gleam/http
import path_parser as pp

// pub type Response{
//   ResponseString(),
//   ResponseJSON(response.Response),
// }
// A handler is a function that takes a request, context and returns a response
pub type Handler(req, res, ctx) =
  fn(Request(req), ctx) -> Option(Response(res))

pub type EndPointHandler(req, res, ctx, params) =
  fn(Request(req), ctx, params) -> Response(res)

pub fn route(handlers: List(Handler(req, res, ctx))) -> Handler(req, res, ctx) {
  // Call each handler, return if successful
  fn(req, cxt) { None }
}

pub fn scope(
  route: pp.Parser(params),
  handlers: Handler(req, res, ctx),
) -> Handler(req, res, ctx) {
  fn(req, ctx) { None }
}

pub fn match(
  route: pp.Parser(params),
  method: http.Method,
  handler: EndPointHandler(req, res, ctx, params),
) -> Handler(req, res, ctx) {
  fn(req, ctx) { None }
}

pub fn get(
  route: pp.Parser(params),
  handler: EndPointHandler(req, res, ctx, params),
) -> Handler(req, res, ctx) {
  match(route, http.Get, handler)
}

pub fn post(
  route: pp.Parser(params),
  handler: EndPointHandler(req, res, ctx, params),
) -> Handler(req, res, ctx) {
  match(route, http.Post, handler)
}

pub fn delete(
  route: pp.Parser(params),
  handler: EndPointHandler(req, res, ctx, params),
) -> Handler(req, res, ctx) {
  match(route, http.Delete, handler)
}

pub fn any(
  route: pp.Parser(params),
  handler: EndPointHandler(req, res, ctx, params),
) -> Handler(req, res, ctx) {
  match(route, http.Other("*"), handler)
}

pub fn serve(context: ctx) {
  fn(handler: Handler(req, res, ctx)) { None }
}

pub type Middleware(req, res, ctx_in, ctx_out) =
  fn(Request(req), ctx_in, Handler(req, res, ctx_out)) -> Option(Response(res))

pub fn middleware(
  middleware_handler: Middleware(req, res, ctx_in, ctx_out),
) -> fn(Handler(req, res, ctx_out)) -> Handler(req, res, ctx_in) {
  fn(handler: Handler(req, res, ctx_out)) {
    fn(req: Request(req), ctx: ctx_in) { middleware_handler(req, ctx, handler) }
  }
}
