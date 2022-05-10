import bliss.{WebRequest, WebResponse}
import example/context.{ContextAuthenticated, InitialContext, User}
import gleam/http/request
import gleam/result

pub fn track(handler) {
  fn(req: WebRequest, ctx: InitialContext) {
    // Track access to the app
    handler(req, ctx)
  }
}

fn check_token(token) {
  case token == "Bearer 123" {
    True -> Ok(True)
    False -> Error(Nil)
  }
}

fn try_authenticate(req: WebRequest, _ctx: InitialContext) -> Result(User, Nil) {
  // This would check using the cookie and the DB
  // But for the example just use a header
  try token = request.get_header(req, "Authorization")

  try _ = check_token(token)

  let role =
    request.get_header(req, "User-Role")
    |> result.unwrap("user")
  // Get cookie from request
  // Access the DB using the url in context
  // TODO, set session cookie
  let user = User(email: "sam@sample.com", role: role)
  Ok(user)
}

pub fn authenticate(handler) {
  fn(req: WebRequest, ctx: InitialContext) -> WebResponse {
    case try_authenticate(req, ctx) {
      Ok(user) -> {
        let context_authenticated = ContextAuthenticated(db: ctx.db, user: user)
        handler(req, context_authenticated)
      }
      Error(_) -> Error(bliss.Unauthorised)
    }
  }
}

pub fn must_be_admin(handler) {
  fn(req: WebRequest, ctx: ContextAuthenticated) -> WebResponse {
    // io.debug("middleware_must_be_admin")
    // Check that the user is admin
    let is_admin = ctx.user.role == "admin"
    case is_admin {
      True -> handler(req, ctx)
      False -> Error(bliss.Unauthorised)
    }
  }
}
