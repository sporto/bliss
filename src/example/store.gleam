pub type Language {
  Language(code: String, name: String)
}

pub fn languages() -> List(Language) {
  [Language("en", "English"), Language("es", "Spanish")]
}
