import gleam/list

pub type Language {
  Language(code: String, name: String)
}

pub type Country {
  Country(
    code: String,
    name: String,
    cities: List(City),
    language_codes: List(String),
  )
}

pub type City {
  City(name: String)
}

pub fn languages() -> List(Language) {
  [Language("en", "English"), Language("es", "Spanish")]
}

pub fn countries() -> List(Country) {
  [
    Country(
      code: "au",
      name: "Australia",
      cities: [City("Melbourne"), City("Sydney")],
      language_codes: ["en"],
    ),
    Country(
      code: "ar",
      name: "Argentina",
      cities: [City("Buenos Aires")],
      language_codes: ["es"],
    ),
  ]
}

pub fn cities() -> List(City) {
  countries()
  |> list.flat_map(fn(c) { c.cities })
}
