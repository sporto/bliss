import bliss.{WebRequest, WebResponse}
import bliss/middleware
import example/store
import example/handlers
import example/middlewares
import example/context.{ContextAuthenticated, InitialContext}
import gleam/bit_builder
import gleam/http
import gleam/http/elli
import gleam/http/request
import gleam/http/response
import gleam/json
import gleam/list
import gleam/map
import gleam/result

pub fn app() {
  // The initial context can be any custom type defined by the application
  let initial_context = InitialContext("db_url")

  let public_handlers =
    bliss.one_of([
      bliss.get("/", handlers.public_home),
      bliss.get("/version", handlers.public_version),
      bliss.get("/status", handlers.public_status),
    ])
    |> middleware.cors("*")

  // It is possible to match route by using pattern matching
  // on the path segments
  let city_handlers =
    bliss.using_pattern_matching(fn(
      segments: List(String),
      req: WebRequest,
      _ctx: ContextAuthenticated,
    ) {
      case segments {
        [] ->
          case req.request.method {
            http.Get -> handlers.city_list
            http.Post ->
              handlers.city_create
              |> middlewares.must_be_admin
            _ -> bliss.not_found
          }
        [id] ->
          case req.request.method {
            http.Get -> handlers.city_show(id)
            http.Delete ->
              handlers.city_delete(id)
              |> middlewares.must_be_admin
            _ -> bliss.not_found
          }
        _ -> bliss.not_found
      }
    })

  let api_handlers =
    bliss.one_of([
      bliss.get("/languages", handlers.language_list),
      bliss.get("/languages/:id", handlers.language_show),
      bliss.get("/countries", handlers.country_list),
      bliss.get("/countries/:id", handlers.country_show),
      bliss.get("/countries/:id/cities", handlers.country_city_list),
      // Some routes can only be used by an admin
      bliss.delete(
        "/countries/:id",
        handlers.language_delete
        |> middlewares.must_be_admin,
      ),
      bliss.scope("/cities", city_handlers),
    ])
    // The middlewares at the bottom of the
    // pipeline are executed first.
    // Middlewares wrap the request,
    // they can modify the request in the way in
    // and the response in the way out.
    //
    // Handle CORS
    |> middleware.cors("https://app.com")
    // Must be authenticated in order to access any app endpoint
    |> middlewares.authenticate

  bliss.one_of([
    bliss.scope("/", public_handlers),
    bliss.scope("/api", api_handlers),
  ])
  // Add middleware to track accesss
  |> middlewares.track
  |> bliss.service(initial_context)
}

pub fn main() {
  elli.become(app(), on_port: 3000)
}
