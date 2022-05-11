import bliss
import bliss/middleware
import app/handlers
import app/middlewares
import app/context.{ContextAuthenticated, InitialContext}
import gleam/http.{Delete, Get, Post}
import gleam/http/request
import gleam/http/elli

pub fn main() {
  elli.become(app(), on_port: 3000)
}

pub fn app() {
  // The initial context can be any custom type defined by the application
  let initial_context = InitialContext("db_url")

  bliss.use_handler(fn(req, _cxt) {
    case request.path_segments(req) {
      ["api", ..rest] -> api_routes(rest)
      rest -> public_routes(rest)
    }
  })
  // Add middleware to track accesss
  |> middlewares.track
  |> bliss.service(initial_context)
}

fn public_routes(path) {
  bliss.use_handler(fn(_req, _ctx) {
    case path {
      [] -> handlers.public_home
      ["version"] -> handlers.public_version
      ["status"] -> handlers.public_status
      _ -> bliss.unmatched
    }
  })
  |> middleware.cors("*")
}

// These routes are scope to /api
fn api_routes(path) {
  bliss.use_handler(fn(req, _ctx) {
    case path {
      // Countries
      ["countries"] -> handlers.country_list
      ["countries", id] ->
        case req.method {
          Get -> handlers.country_show(id)
          Delete ->
            handlers.country_delete(id)
            |> middlewares.must_be_admin
          _ -> bliss.unmatched
        }
      ["countries", id, "cities"] -> handlers.country_city_list(id)
      // Cities
      ["cities"] ->
        case req.method {
          Get -> handlers.city_list
          Post ->
            handlers.city_create
            |> middlewares.must_be_admin
          _ -> bliss.unmatched
        }
      ["cities", id] ->
        case req.method {
          Get -> handlers.city_show(id)
          Delete ->
            handlers.city_delete(id)
            |> middlewares.must_be_admin
          _ -> bliss.unmatched
        }
      // Languages
      ["languages"] -> handlers.language_list
      ["languages", id] -> handlers.language_show(id)
      ["languages", id, "countries"] -> handlers.language_countries(id)
      _ -> bliss.unmatched
    }
  })
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
