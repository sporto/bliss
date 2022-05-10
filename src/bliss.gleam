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
    params: Params,
    request: request.Request(BitString),
    unused_path: List(String),
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

fn is_wanted_method(wanted_method: http.Method, req: WebRequest) {
  case wanted_method {
    http.Other("*") -> True
    _ -> req.request.method == wanted_method
  }
}

/// Provide a function that returns a handler
/// The returned handler by your function will be called
pub fn chain(provide: fn(WebRequest, ctx) -> Handler(ctx)) -> Handler(ctx) {
  fn(req: WebRequest, ctx) {
    let handler = provide(req, ctx)
    handler(req, ctx)
  }
}

pub fn using_path(handler, unused_path) {
  fn(req, ctx) { handler(WebRequest(..req, unused_path: unused_path), ctx) }
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
pub fn not_found(_req, _ctx) {
  Ok(response_not_found())
}

pub fn unmatched(_req, _ctx) {
  Error(Unmatched)
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
    let segments = utils.segments(request.path)

    let web_request: WebRequest =
      WebRequest(request: request, unused_path: segments, params: params)

    case handler(web_request, context) {
      Ok(resp) -> resp
      Error(error) -> response_for_error(error)
    }
  }
}
