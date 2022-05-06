import bliss/path_parser as pp
import gleam/bit_builder.{BitBuilder}
import gleam/http
import gleam/http/request
import gleam/http/response.{Response}
import gleam/io
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/string

pub type WebRequest {
  WebRequest(request: request.Request(BitString), partial_path: String)
}

pub type WebResponse =
  Response(BitBuilder)

// A handler is a function that takes a request, context and returns a response
pub type Handler(ctx) =
  fn(WebRequest, ctx) -> Option(WebResponse)

pub type EndPointHandler(ctx, params) =
  fn(WebRequest, ctx, params) -> WebResponse

pub fn route(handlers: List(Handler(ctx))) -> Handler(ctx) {
  // Call each handler, return if successful
  fn(req: WebRequest, cxt: ctx) {
    list.fold_until(
      handlers,
      None,
      fn(acc, handler) {
        case handler(req, cxt) {
          None -> list.Continue(None)
          Some(resp) -> list.Stop(Some(resp))
        }
      },
    )
  }
}

pub fn scope(route: pp.Parser(params), handler: Handler(ctx)) -> Handler(ctx) {
  fn(req: WebRequest, ctx) {
    // We take the path from partial_path instead of request.path
    // Because ancestor scopes can consume part of the path
    // We only want to match on the left over path segments
    let path = req.partial_path
    case pp.parse(path, route) {
      Ok(pp.ExactMatch(params)) -> {
        // TODO, we need to pass the params
        // The whole path has been consumed
        let next_req = WebRequest(..req, partial_path: "")
        handler(next_req, ctx)
      }
      Ok(pp.PartialMatch(params, left_over)) -> {
        let next_path =
          left_over
          |> string.join("/")
        let next_req = WebRequest(..req, partial_path: next_path)
        // TODO, we need to pass the params
        handler(next_req, ctx)
      }
      Error(_) -> {
        io.debug("Scope didn't match")
        None
      }
    }
  }
}

pub fn match(
  route: pp.Parser(params),
  wanted_method: http.Method,
  handler: EndPointHandler(ctx, params),
) -> Handler(ctx) {
  fn(req: WebRequest, ctx) {
    let path = req.partial_path
    let is_wanted_method = case wanted_method {
      http.Other("*") -> True
      _ -> req.request.method == wanted_method
    }
    case is_wanted_method {
      True ->
        case pp.parse(path, route) {
          Ok(pp.ExactMatch(params)) -> Some(handler(req, ctx, params))
          _ -> None
        }
      False -> None
    }
  }
}

pub fn get(
  route: pp.Parser(params),
  handler: EndPointHandler(ctx, params),
) -> Handler(ctx) {
  match(route, http.Get, handler)
}

pub fn post(
  route: pp.Parser(params),
  handler: EndPointHandler(ctx, params),
) -> Handler(ctx) {
  match(route, http.Post, handler)
}

pub fn delete(
  route: pp.Parser(params),
  handler: EndPointHandler(ctx, params),
) -> Handler(ctx) {
  match(route, http.Delete, handler)
}

pub fn any(
  route: pp.Parser(params),
  handler: EndPointHandler(ctx, params),
) -> Handler(ctx) {
  match(route, http.Other("*"), handler)
}

pub fn service(handler: Handler(context), context context: context) {
  fn(request: request.Request(BitString)) {
    let web_request = WebRequest(request: request, partial_path: request.path)
    case handler(web_request, context) {
      Some(resp) -> resp
      None -> {
        let body = bit_builder.from_string("Not Found")
        response.new(404)
        |> response.set_body(body)
      }
    }
  }
}

pub type Middleware(ctx_in, ctx_out) =
  fn(WebRequest, ctx_in, Handler(ctx_out)) -> Option(WebResponse)

pub fn middleware(
  middleware_handler: Middleware(ctx_in, ctx_out),
) -> fn(Handler(ctx_out)) -> Handler(ctx_in) {
  fn(handler: Handler(ctx_out)) {
    fn(req: WebRequest, ctx: ctx_in) { middleware_handler(req, ctx, handler) }
  }
}
