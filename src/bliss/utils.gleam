import gleam/list
import gleam/string

fn drop_empty_segments(segments) {
  list.filter(segments, fn(seg) { !string.is_empty(seg) })
}

pub fn segments(path: String) {
  string.split(path, "/")
  |> drop_empty_segments
}
