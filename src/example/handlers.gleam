import bliss.{WebRequest, WebResponse}
import example/codecs
import example/context.{ContextAuthenticated, InitialContext}
import example/store
import gleam/bit_builder
import gleam/http/response
import gleam/json
import gleam/list
import gleam/map
import gleam/result

pub fn public_home(_req: WebRequest, _ctx: InitialContext) -> WebResponse {
  let body = bit_builder.from_string("Home")
  let resp =
    response.new(200)
    |> response.set_body(body)

  Ok(resp)
}

pub fn public_version(_req: WebRequest, _ctx: InitialContext) -> WebResponse {
  let body = bit_builder.from_string("1.0.0")
  let resp =
    response.new(200)
    |> response.set_body(body)
  Ok(resp)
}

pub fn public_status(_req: WebRequest, _ctx: InitialContext) -> WebResponse {
  let data =
    json.object([
      #("message", json.string("Operational")),
      #("incidents", json.array([], of: json.string)),
    ])
  Ok(bliss.json_response(data))
}

pub fn country_list(_req: WebRequest, _ctx: ContextAuthenticated) -> WebResponse {
  let data =
    store.countries()
    |> json.array(of: codecs.json_of_country)

  Ok(bliss.json_response(data))
}

pub fn country_show(req: WebRequest, _ctx: ContextAuthenticated) -> WebResponse {
  try code =
    map.get(req.params, "id")
    |> result.replace_error(bliss.NotFound)

  try country =
    store.countries()
    |> list.find(fn(country) { country.code == code })
    |> result.replace_error(bliss.NotFound)

  let data = codecs.json_of_country(country)

  Ok(bliss.json_response(data))
}

pub fn country_city_list(
  req: WebRequest,
  _ctx: ContextAuthenticated,
) -> WebResponse {
  try code =
    map.get(req.params, "id")
    |> result.replace_error(bliss.NotFound)

  try country =
    store.countries()
    |> list.find(fn(country) { country.code == code })
    |> result.replace_error(bliss.NotFound)

  let data = json.array(country.cities, of: codecs.json_of_city)

  Ok(bliss.json_response(data))
}

pub fn city_list(_req: WebRequest, _ctx: ContextAuthenticated) -> WebResponse {
  let cities = store.cities()
  let data = json.array(cities, of: codecs.json_of_city)

  Ok(bliss.json_response(data))
}

pub fn city_show(id: String) {
  fn(_req: WebRequest, _ctx: ContextAuthenticated) {
    let cities = store.cities()

    try city =
      list.find(cities, fn(c) { c.name == id })
      |> result.replace_error(bliss.NotFound)

    let data = codecs.json_of_city(city)
    Ok(bliss.json_response(data))
  }
}

pub fn city_delete(_id: String) {
  fn(_req: WebRequest, _ctx: ContextAuthenticated) {
    let body = bit_builder.from_string("Deleted")
    let resp =
      response.new(200)
      |> response.set_body(body)
    Ok(resp)
  }
}

pub fn language_list(
  _req: WebRequest,
  _ctx: ContextAuthenticated,
) -> WebResponse {
  let data =
    store.languages()
    |> json.array(of: codecs.json_of_language)

  Ok(bliss.json_response(data))
}

pub fn language_show(req: WebRequest, _ctx: ContextAuthenticated) -> WebResponse {
  try code =
    map.get(req.params, "id")
    |> result.replace_error(bliss.NotFound)

  try language =
    store.languages()
    |> list.find(fn(lang) { lang.code == code })
    |> result.replace_error(bliss.NotFound)

  let data = codecs.json_of_language(language)

  Ok(bliss.json_response(data))
}

pub fn language_delete(
  _req: WebRequest,
  _ctx: ContextAuthenticated,
) -> WebResponse {
  let body = bit_builder.from_string("Deleted")
  let resp =
    response.new(200)
    |> response.set_body(body)
  Ok(resp)
}
