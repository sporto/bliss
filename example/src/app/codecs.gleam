import app/store
import gleam/json

// Serialisers
pub fn json_of_language(language: store.Language) {
  json.object([
    #("code", json.string(language.code)),
    #("name", json.string(language.name)),
  ])
}

pub fn json_of_country(country: store.Country) {
  json.object([
    #("code", json.string(country.code)),
    #("name", json.string(country.name)),
  ])
}

pub fn json_of_city(city: store.City) {
  json.object([#("name", json.string(city.name))])
}
