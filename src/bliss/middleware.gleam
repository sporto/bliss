import bliss.{Handler, WebRequest}
import gleam/result
import gleam/http
import gleam/http/response
import gleam/bit_builder
import gleam/list
import gleam/string

const ac_origin = "Access-Control-Allow-Origin"

const ac_methods = "Access-Control-Allow-Methods"

const ac_headers = "Access-Control-Allow-Headers"

const ac_credentials = "Access-Control-Allow-Credentials"

fn add_cors_headers(response, origin: String, with_credentials: Bool) {
  let add_credentials = fn(resp) {
    case with_credentials {
      True ->
        resp
        |> response.prepend_header(ac_credentials, "true")
      False -> resp
    }
  }

  let allowed_methods = [
    http.Delete,
    http.Get,
    http.Head,
    http.Options,
    http.Patch,
    http.Post,
    http.Put,
  ]

  response
  |> response.prepend_header(ac_origin, origin)
  |> add_cors_allowed_methods(allowed_methods)
  |> response.prepend_header(ac_headers, "Content-Type")
  |> add_credentials
}

fn add_cors_allowed_methods(resp, allowed_methods: List(http.Method)) {
  let methods_str =
    allowed_methods
    |> list.map(http.method_to_string)
    |> list.map(string.uppercase)
    |> string.join(",")

  resp
  |> response.prepend_header(ac_methods, methods_str)
}

pub fn cors(
  handler: Handler(ctx),
  origin: String,
  with_credentials: Bool,
) -> Handler(ctx) {
  fn(req: WebRequest, ctx) {
    // When OPTIONS we need to respond with the CORS headers
    let resp = case req.method {
      http.Options ->
        response.new(202)
        |> response.set_body(bit_builder.new())
        |> Ok
      _ -> handler(req, ctx)
    }

    resp
    |> result.map(add_cors_headers(_, origin, with_credentials))
  }
}
