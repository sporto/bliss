import bliss/dict_path_parser as dpp
import bliss/static_path_parser as spp
import gleam/bit_builder.{BitBuilder}
import gleam/http
import gleam/http/request
import gleam/http/response.{Response}
import gleam/io
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/string

pub type WebRequest(p) {
  WebRequest(
    request: request.Request(BitString),
    partial_path: String,
    params: p,
  )
}

pub type WebResponse =
  Response(BitBuilder)

// A handler is a function that takes a request, context and returns a response
pub type Handler(ctx, params) =
  fn(WebRequest(params), ctx) -> Option(WebResponse)

pub type EndPointHandler(ctx, params) =
  fn(WebRequest(params), ctx) -> WebResponse

pub fn route(handlers: List(Handler(ctx, params))) -> Handler(ctx, params) {
  // Call each handler, return if successful
  fn(req: WebRequest(params), cxt: ctx) {
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

fn make_next_request(
  request_in: WebRequest(params_in),
  params: params_out,
  left_over_path: List(String),
) -> WebRequest(#(params_in, params_out)) {
  let next_path =
    left_over_path
    |> string.join("/")

  let next_params = #(request_in.params, params)

  WebRequest(
    request: request_in.request,
    partial_path: next_path,
    params: next_params,
  )
}

pub fn scope(
  route: spp.Parser(params_out),
  handler: Handler(ctx, #(params_in, params_out)),
) -> Handler(ctx, params_in) {
  fn(req: WebRequest(params_in), ctx) {
    // We take the path from partial_path instead of request.path
    // Because ancestor scopes can consume part of the path
    // We only want to match on the left over path segments
    let call_next_handler = fn(params: params_out, left_over: List(String)) {
      let next_req = make_next_request(req, params, left_over)
      handler(next_req, ctx)
    }

    let path = req.partial_path
    case spp.parse(path, route) {
      Ok(spp.ExactMatch(params)) ->
        // The whole path has been consumed by the parser
        call_next_handler(params, [])
      Ok(spp.PartialMatch(params, left_over)) ->
        call_next_handler(params, left_over)
      Error(_) -> {
        io.debug("Scope didn't match")
        None
      }
    }
  }
}

fn is_wanted_method(wanted_method: http.Method, req: WebRequest(p)) {
  case wanted_method {
    http.Other("*") -> True
    _ -> req.request.method == wanted_method
  }
}

pub fn match_static(
  route: spp.Parser(params_out),
  wanted_method: http.Method,
  handler: EndPointHandler(ctx, #(params_in, params_out)),
) -> Handler(ctx, params_in) {
  fn(req: WebRequest(params_in), ctx) {
    let path = req.partial_path

    let call_handler = fn(params: params_out) {
      let next_req = make_next_request(req, params, [])
      Some(handler(next_req, ctx))
    }

    case is_wanted_method(wanted_method, req) {
      True ->
        case spp.parse(path, route) {
          Ok(spp.ExactMatch(params)) -> call_handler(params)
          _ -> None
        }
      False -> None
    }
  }
}

pub fn match_dict(
  route: String,
  wanted_method: http.Method,
  handler: EndPointHandler(ctx, #(params_in, params_out)),
) {
  fn(req: WebRequest(params_in), ctx) {
    let path = req.partial_path

    let call_handler = fn(params: params_out) {
      let next_req = make_next_request(req, params, [])
      Some(handler(next_req, ctx))
    }

    case is_wanted_method(wanted_method, req) {
      True ->
        case dpp.parse(path, route) {
          Ok(dpp.ExactMatch(params)) -> call_handler(params)
          _ -> None
        }
      False -> None
    }
  }
}

pub fn get(
  route: spp.Parser(params_out),
  handler: EndPointHandler(ctx, #(params_in, params_out)),
) -> Handler(ctx, params_in) {
  match_static(route, http.Get, handler)
}

pub fn post(
  route: spp.Parser(params_out),
  handler: EndPointHandler(ctx, #(params_in, params_out)),
) -> Handler(ctx, params_in) {
  match_static(route, http.Post, handler)
}

pub fn delete(
  route: spp.Parser(params_out),
  handler: EndPointHandler(ctx, #(params_in, params_out)),
) -> Handler(ctx, params_in) {
  match_static(route, http.Delete, handler)
}

pub fn any(
  route: spp.Parser(params_out),
  handler: EndPointHandler(ctx, #(params_in, params_out)),
) -> Handler(ctx, params_in) {
  match_static(route, http.Other("*"), handler)
}

pub fn get_dict(
  route: String,
  handler: EndPointHandler(ctx, #(params_in, params_out)),
) -> Handler(ctx, params_in) {
  match_dict(route, http.Get, handler)
}

pub fn service(handler: Handler(context, #()), context context: context) {
  fn(request: request.Request(BitString)) {
    let web_request: WebRequest(#()) =
      WebRequest(request: request, partial_path: request.path, params: #())

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

pub type Middleware(ctx_in, ctx_out, params_in, params_out) =
  fn(WebRequest(params_in), ctx_in, Handler(ctx_out, params_out)) ->
    Option(WebResponse)

pub fn middleware(
  middleware_handler: Middleware(ctx_in, ctx_out, params_in, params_out),
) -> fn(Handler(ctx_out, params_out)) -> Handler(ctx_in, params_in) {
  fn(handler: Handler(ctx_out, params_out)) {
    fn(req: WebRequest(params_in), ctx: ctx_in) {
      middleware_handler(req, ctx, handler)
    }
  }
}
