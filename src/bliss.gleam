import bliss/dict_path_parser as dpp
import bliss/utils
import gleam/bit_builder.{BitBuilder}
import gleam/http
import gleam/http/request
import gleam/http/response.{Response}
import gleam/list
import gleam/map.{Map}
import gleam/string
import gleam/json

pub const header_content_type = "Content-Type"

pub type Params =
  Map(String, String)

pub type WebRequest {
  WebRequest(
    request: request.Request(BitString),
    partial_path: String,
    params: Params,
  )
}

pub type ResponseError {
  Unmatched
  NotFound
  Unauthorised
}

pub type WebResponse =
  Result(Response(BitBuilder), ResponseError)

// A handler is a function that takes a request, context and returns a response
pub type Handler(ctx) =
  fn(WebRequest, ctx) -> WebResponse

pub type Middleware(ctx_in, ctx_out) =
  fn(Handler(ctx_out)) -> Handler(ctx_in)

pub fn one_of(handlers: List(Handler(ctx))) -> Handler(ctx) {
  // Call each handler, return if successful
  fn(req: WebRequest, cxt: ctx) {
    list.fold_until(
      handlers,
      Error(Unmatched),
      fn(_acc, handler) {
        case handler(req, cxt) {
          Error(Unmatched) -> list.Continue(Error(Unmatched))
          Error(err) -> list.Stop(Error(err))
          Ok(resp) -> list.Stop(Ok(resp))
        }
      },
    )
  }
}

fn make_next_request(
  request_in: WebRequest,
  additional_params: Params,
  left_over_path: List(String),
) -> WebRequest {
  let next_path =
    left_over_path
    |> string.join("/")

  let next_params = map.merge(into: request_in.params, from: additional_params)

  WebRequest(
    request: request_in.request,
    partial_path: next_path,
    params: next_params,
  )
}

pub fn scope(pattern: String, handler: Handler(ctx)) -> Handler(ctx) {
  fn(req: WebRequest, ctx) {
    // We take the path from partial_path instead of request.path
    // Because ancestor scopes can consume part of the path
    // We only want to match on the left over path segments
    let call_next_handler = fn(params: Params, left_over: List(String)) {
      let next_req = make_next_request(req, params, left_over)
      handler(next_req, ctx)
    }

    let path = req.partial_path

    case dpp.parse(pattern: pattern, path: path) {
      Ok(dpp.ExactMatch(params)) ->
        // The whole path has been consumed by the parser
        call_next_handler(params, [])
      Ok(dpp.PartialMatch(params, left_over)) ->
        call_next_handler(params, left_over)
      Error(_) -> Error(Unmatched)
    }
  }
}

fn is_wanted_method(wanted_method: http.Method, req: WebRequest) {
  case wanted_method {
    http.Other("*") -> True
    _ -> req.request.method == wanted_method
  }
}

pub fn route(
  matcher: fn(List(String), WebRequest, ctx) -> Handler(ctx),
) -> Handler(ctx) {
  fn(req: WebRequest, ctx) {
    let path = utils.segments(req.partial_path)
    let handler = matcher(path, req, ctx)
    handler(req, ctx)
  }
}

pub fn if_method(wanted_method: http.Method, handler) -> Handler(ctx) {
  fn(req: WebRequest, ctx) {
    let is_wanted = is_wanted_method(wanted_method, req)
    case is_wanted {
      True -> handler(req, ctx)
      False -> Error(Unmatched)
    }
  }
}

pub fn if_get(handler: Handler(ctx)) -> Handler(ctx) {
  if_method(http.Get, handler)
}

pub fn match(
  pattern: String,
  wanted_method: http.Method,
  handler: Handler(ctx),
) -> Handler(ctx) {
  fn(req: WebRequest, ctx) {
    let path = req.partial_path

    let call_handler = fn(params: Map(String, String)) {
      let next_req = make_next_request(req, params, [])
      handler(next_req, ctx)
    }

    let is_wanted = is_wanted_method(wanted_method, req)

    case is_wanted {
      True ->
        case dpp.parse(pattern: pattern, path: path) {
          Ok(dpp.ExactMatch(params)) -> call_handler(params)
          _ -> Error(Unmatched)
        }
      False -> Error(Unmatched)
    }
  }
}

pub fn get(pattern: String, handler: Handler(ctx)) -> Handler(ctx) {
  match(pattern, http.Get, handler)
}

pub fn post(pattern: String, handler: Handler(ctx)) -> Handler(ctx) {
  match(pattern, http.Post, handler)
}

pub fn delete(pattern: String, handler: Handler(ctx)) -> Handler(ctx) {
  match(pattern, http.Delete, handler)
}

pub fn any(pattern: String, handler: Handler(ctx)) -> Handler(ctx) {
  match(pattern, http.Other("*"), handler)
}

pub fn json_response(data: json.Json) -> Response(BitBuilder) {
  let body =
    data
    |> json.to_string
    |> bit_builder.from_string

  response.new(200)
  |> response.set_body(body)
  |> response.prepend_header(header_content_type, "application/json")
}

/// A handler that always responds with not found
pub fn not_found(req, ctx) {
  Ok(response_not_found())
}

fn response_not_found() {
  let body = bit_builder.from_string("Not Found")

  response.new(404)
  |> response.set_body(body)
}

fn response_unauthorised() {
  response.new(401)
  |> response.set_body(bit_builder.from_string("Unauthorized"))
}

fn response_for_error(error: ResponseError) {
  case error {
    NotFound -> response_not_found()
    Unauthorised -> response_unauthorised()
    Unmatched -> response_not_found()
  }
}

pub fn service(handler: Handler(context), context context: context) {
  fn(request: request.Request(BitString)) {
    let params = map.new()

    let web_request: WebRequest =
      WebRequest(request: request, partial_path: request.path, params: params)

    case handler(web_request, context) {
      Ok(resp) -> resp
      Error(error) -> response_for_error(error)
    }
  }
}
