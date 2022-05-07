pub type Response(a) {
  ExactMatch(parsed: a)
  PartialMatch(parsed: a, left_over: String)
}

pub fn parse(path, route) {
  todo
}
