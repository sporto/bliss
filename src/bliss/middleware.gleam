import bliss.{WebRequest}
import gleam/result
import gleam/http
import gleam/http/response
import gleam/bit_builder

const ac_origin = "Access-Control-Allow-Origin"

const ac_methods = "Access-Control-Allow-Methods"

const ac_headers = "Access-Control-Allow-Headers"

const ac_credentials = "Access-Control-Allow-Credentials"

fn add_cors_headers(response, origin: String) {
  response
  |> response.prepend_header(ac_origin, origin)
  |> response.prepend_header(
    ac_methods,
    "DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT",
  )
  |> response.prepend_header(ac_headers, "Content-Type")
  |> response.prepend_header(ac_credentials, "true")
}

pub fn cors(handler, origin: String) {
  fn(req: WebRequest, ctx) {
    //   When OPTIONS we need to respond with the CORS headers
    let resp = case req.request.method {
      http.Options -> {
        let resp =
          response.new(202)
          |> response.set_body(bit_builder.from_string(""))
        Ok(resp)
      }
      _ -> handler(req, ctx)
    }

    resp
    |> result.map(add_cors_headers(_, origin))
  }
}
