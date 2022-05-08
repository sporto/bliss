import gleam/list

pub type Language {
  Language(code: String, name: String)
}

pub type Country {
  Country(code: String, name: String, cities: List(City))
}

pub type City {
  City(name: String)
}

pub fn languages() -> List(Language) {
  [Language("en", "English"), Language("es", "Spanish")]
}

pub fn countries() -> List(Country) {
  [
    Country("au", "Australia", [City("Melbourne"), City("Sydney")]),
    Country("ar", "Argentina", [City("Buenos Aires")]),
  ]
}

pub fn cities() -> List(City) {
  countries()
  |> list.flat_map(fn(c) { c.cities })
}
