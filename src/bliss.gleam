import gleam/bit_builder.{BitBuilder}
import gleam/http
import gleam/http/request
import gleam/http/response.{Response}
import gleam/list
import gleam/json

pub const header_content_type = "Content-Type"

/// A Request
pub type WebRequest =
  request.Request(BitString)

/// Standard response errors
/// Use Unmatched to signal that the current path hasn't match
pub type ResponseError {
  Unmatched
  NotFound
  Unauthorised
}

/// Expected response by handlers
pub type WebResponse =
  Result(Response(BitBuilder), ResponseError)

/// Everything is a handler in Bliss
/// A handler is a function that takes a WebRequest and a context and returns a WebResponse
/// A context is your own type, which could hold any data e.g. current_user, db_pool
pub type Handler(ctx) =
  fn(WebRequest, ctx) -> WebResponse

/// A middleware is a function that wraps a handler
/// Middlewares can change the request in the way in
/// and the response in the way out
pub type Middleware(ctx_in, ctx_out) =
  fn(Handler(ctx_out)) -> Handler(ctx_in)

/// Take the request and context and return a handler to call
/// Use this for routing
///
/// ```
/// bliss.user_hander(fn(req, ctx) {
///   case request.path_segments(req) {
///     ["api", ..rest] -> api_routes(rest)
///     rest -> public_routes(rest)
///   }
/// })
/// ```
pub fn use_handler(provide: fn(WebRequest, ctx) -> Handler(ctx)) -> Handler(ctx) {
  fn(req: WebRequest, ctx) {
    let handler = provide(req, ctx)
    handler(req, ctx)
  }
}

fn is_wanted_method(wanted_method: http.Method, req: WebRequest) {
  case wanted_method {
    http.Other("*") -> True
    _ -> req.method == wanted_method
  }
}

fn has_wanted_method(wanted_methods: List(http.Method), req: WebRequest) {
  list.any(wanted_methods, is_wanted_method(_, req))
}

/// *********************
/// Basic Middlewares
/// *********************
///
/// A middleware that only calls the wrapped handler
/// if the request uses the allowed methods
///
/// ```
/// ["users", id] -> delete_user(id) |> bliss.if_methods([Delete])
/// ```
///
pub fn if_methods(wanted_methods: List(http.Method)) -> Middleware(ctx, ctx) {
  fn(handler: Handler(ctx)) -> Handler(ctx) {
    fn(req: WebRequest, ctx) {
      let has_wanted = has_wanted_method(wanted_methods, req)
      case has_wanted {
        True -> handler(req, ctx)
        False -> Error(Unmatched)
      }
    }
  }
}

/// A middleware that only calls the wrapped handler
/// if the request uses Get
pub fn if_get(handler: Handler(ctx)) -> Handler(ctx) {
  if_methods([http.Get])(handler)
}

/// A middleware that only calls the wrapped handler
/// if the request uses Post
pub fn if_post(handler: Handler(ctx)) -> Handler(ctx) {
  if_methods([http.Post])(handler)
}

/// A middleware that only calls the wrapped handler
/// if the request uses Delete
pub fn if_delete(handler: Handler(ctx)) -> Handler(ctx) {
  if_methods([http.Delete])(handler)
}

/// *********************
/// Basic handlers
/// *********************
///
/// A handler that always responds with not found
pub fn not_found(_req: WebRequest, _ctx) -> WebResponse {
  Ok(response_not_found())
}

/// A handler that returns Unmatched
/// Use the to indicate that the framework should keep
/// trying to match a route
///
/// ```
/// case path {
///  ["users"] -> ...
///  _ -> bliss.unmatched
/// }
/// ```
///
pub fn unmatched(_req: WebRequest, _ctx) -> WebResponse {
  Error(Unmatched)
}

/// *********************
/// Common responses
/// *********************
///
/// Create a JSON response
pub fn json_response(data: json.Json) -> Response(BitBuilder) {
  let body =
    data
    |> json.to_string
    |> bit_builder.from_string

  response.new(200)
  |> response.set_body(body)
  |> response.prepend_header(header_content_type, "application/json")
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

/// Create the web service
/// Pass this to a web server
pub fn service(handler: Handler(context), context: context) {
  fn(request: request.Request(BitString)) {
    case handler(request, context) {
      Ok(resp) -> resp
      Error(error) -> response_for_error(error)
    }
  }
}
