import bliss.{WebRequest}
import bliss/middleware
import example/handlers
import example/middlewares
import example/context.{ContextAuthenticated, InitialContext}
import gleam/http
import gleam/http/elli

pub fn main() {
  elli.become(app(), on_port: 3000)
}

pub fn app() {
  // The initial context can be any custom type defined by the application
  let initial_context = InitialContext("db_url")

  bliss.one_of([
    bliss.scope("/", public_routes()),
    bliss.scope("/api", api_routes()),
  ])
  // Add middleware to track accesss
  |> middlewares.track
  |> bliss.service(initial_context)
}

fn public_routes() {
  bliss.one_of([
    bliss.get("/", handlers.public_home),
    bliss.get("/version", handlers.public_version),
    bliss.get("/status", handlers.public_status),
  ])
  |> middleware.cors("*")
}

// These routes are scope to /api
fn api_routes() {
  bliss.one_of([
    bliss.get("/countries", handlers.country_list),
    bliss.get("/countries/:id", handlers.country_show),
    bliss.get("/countries/:id/cities", handlers.country_city_list),
    // Some routes can only be used by an admin
    bliss.delete(
      "/countries/:id",
      handlers.language_delete
      |> middlewares.must_be_admin,
    ),
    bliss.scope("/cities", city_routes()),
    bliss.scope("/languages", language_route()),
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
}

// It is possible to match route by using pattern matching
// on the path segments, instead of the path parser.
//
// This allows to avoid using the Params dictionary as
// you can pass the matched params directly
//
// These routes are scopes to /cities
fn city_routes() {
  bliss.chain(fn(req: WebRequest, _ctx: ContextAuthenticated) {
    case req.unused_path {
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
}

fn language_route() {
  bliss.chain(fn(req, _ctx) {
    case req.unused_path {
      [] -> handlers.language_list
      [id] -> handlers.language_show(id)
      [id, ..rest] ->
        language_sub_route(id)
        |> bliss.using_path(rest)
    }
  })
}

fn language_sub_route(language_code) {
  bliss.chain(fn(req, _ctx) {
    case req.unused_path {
      ["countries"] -> handlers.language_countries(language_code)
      _ -> bliss.not_found
    }
  })
}
