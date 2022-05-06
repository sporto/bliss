import gleam/http/response.{Response}
import gleam/http/request.{Request}
import gleam/option.{None, Option, Some}
import gleam/http
import path_parser as pp
import gleam/bit_builder.{BitBuilder}
import gleam/list
import gleam/io
import gleam/string

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
  fn(req, cxt) {
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

pub fn scope(
  route: pp.Parser(params),
  handler: Handler(req, res, ctx),
) -> Handler(req, res, ctx) {
  fn(req: Request(req), ctx) {
    // io.debug(route)
    case pp.parse(req.path, route, True) {
      Ok(response) -> {
        let next_path =
          response.left_over
          |> string.join("/")
        let next_req = Request(..req, path: next_path)
        handler(req, ctx)
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
  handler: EndPointHandler(req, res, ctx, params),
) -> Handler(req, res, ctx) {
  fn(req: Request(req), ctx) {
    let is_wanted_method = case wanted_method {
      http.Other("*") -> True
      _ -> req.method == wanted_method
    }
    case is_wanted_method {
      True ->
        case pp.parse(req.path, route, False) {
          Ok(response) -> Some(handler(req, ctx, response.parsed))
          Error(_) -> None
        }
      False -> None
    }
  }
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

pub fn service(
  handler: Handler(BitString, BitBuilder, context),
  context context: context,
) {
  fn(request: Request(BitString)) {
    case handler(request, context) {
      Some(resp) -> resp
      None -> {
        let body = bit_builder.from_string("Not Found")
        response.new(404)
        |> response.set_body(body)
      }
    }
  }
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
