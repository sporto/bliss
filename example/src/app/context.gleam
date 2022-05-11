pub type User {
  User(email: String, role: String)
}

pub type InitialContext {
  InitialContext(db: String)
}

pub type ContextAuthenticated {
  ContextAuthenticated(db: String, user: User)
}
