import gleam/int
import gleam/io
import gleam/list
import gleam/order.{Eq, Gt, Lt}
import gleam/string

import file_streams/file_stream
import file_streams/file_stream_error

import argv

import trim3

// io.println is unbuffered, collect as much output as possible before
// printing. On my 1M line test file printing each line took ~10 seconds

pub type HistoryEntry {
  HistoryEntry(timestamp: Int, commands: List(String))
}

pub type Line {
  Timestamp(Int)
  Command(String)
}

type Acc {
  Acc(prev: String, done: List(#(Int, String)))
}

type Accumulator {
  Accumulator(
    current_timestamp: Int,
    current_commands: List(String),
    entries: List(HistoryEntry),
  )
}

fn merge_history(
  initial_state: Accumulator,
  lines: List(Line),
) -> List(HistoryEntry) {
  let final_state = list.fold(lines, initial_state, merge_history__fold)
  let final_entry =
    HistoryEntry(final_state.current_timestamp, [
      string.join(list.reverse(final_state.current_commands), with: "\n"),
    ])
  list.append(final_state.entries, [final_entry])
}

fn merge_history__fold(acc: Accumulator, line: Line) -> Accumulator {
  case line {
    Timestamp(new_timestamp) ->
      case list.length(acc.current_commands) > 0 {
        True -> {
          let current_entry =
            HistoryEntry(acc.current_timestamp, [
              string.join(list.reverse(acc.current_commands), with: "\n"),
            ])
          let final_entries = case acc.current_timestamp == 0 {
            True -> acc.entries
            False -> [current_entry, ..acc.entries]
          }
          Accumulator(new_timestamp, [], final_entries)
        }
        False -> Accumulator(new_timestamp, [], acc.entries)
      }

    Command(command_string) -> {
      Accumulator(
        acc.current_timestamp,
        [command_string, ..acc.current_commands],
        acc.entries,
      )
    }
  }
}

type Kek {
  Kek(ts: Int, comma: List(String), done: List(HistoryEntry))
}

fn dedupe_on_ts__fold(acc: Kek, entry: HistoryEntry) {
  case entry.timestamp {
    ts if ts == acc.ts -> {
      Kek(ts, list.append(entry.commands, acc.comma), acc.done)
    }
    ts -> {
      // New timestamp found
      // Move acc.ts acc.comma into done
      case acc {
        // FIXME: Has to be a better way to ignore the first empty
        // accumulator?
        Kek(0, [], []) -> Kek(ts, entry.commands, [])
        _ ->
          Kek(ts, entry.commands, [
            HistoryEntry(acc.ts, list.unique(acc.comma)),
            ..acc.done
          ])
      }
    }
  }
}

fn dedupe_on_ts(entries: List(HistoryEntry)) -> List(HistoryEntry) {
  list.fold(entries, Kek(0, [], []), dedupe_on_ts__fold)
  |> fn(acc) { [HistoryEntry(acc.ts, list.unique(acc.comma)), ..acc.done] }
}

fn dedupe_on_prev__fold(acc: Acc, entry) {
  let #(_, cmd) = entry
  case cmd == acc.prev {
    True -> Acc(cmd, acc.done)
    False -> Acc(cmd, [entry, ..acc.done])
  }
}

fn expanded__fold(
  acc: List(#(Int, String)),
  entry: HistoryEntry,
) -> List(#(Int, String)) {
  list.append(
    list.map(entry.commands, fn(command) { #(entry.timestamp, command) })
      |> list.reverse,
    acc,
  )
}

fn dedupe_on_prev(data) {
  list.fold(data, Acc("", []), with: dedupe_on_prev__fold).done
  |> list.reverse
}

fn recurse_trim_skip(stream, acc, x) -> List(Line) {
  case file_stream.read_line(stream) {
    Ok(line) -> {
      case trim3.trim3_end(line, x) {
        //case string.trim_end(line) {
        "" -> recurse_trim_skip(stream, acc, x)
        line -> {
          case string.starts_with(line, "#") {
            True -> {
              case int.parse(string.drop_start(line, 1)) {
                Ok(number) ->
                  recurse_trim_skip(stream, [Timestamp(number), ..acc], x)
                _ -> recurse_trim_skip(stream, [Command(line), ..acc], x)
              }
            }
            False -> recurse_trim_skip(stream, [Command(line), ..acc], x)
          }
        }
      }
    }
    Error(e) if e == file_stream_error.Eof -> acc
    Error(e) if e == file_stream_error.InvalidUnicode ->
      recurse_trim_skip(stream, acc, x)
    Error(x) -> {
      echo x
      panic
    }
  }
}

pub fn main() {
  let strip_chars =
    string.to_graphemes(" \t\n") |> list.map(string.to_utf_codepoints)

  let read_history = fn(history, path) {
    let assert Ok(stream) = file_stream.open_read(path)
    recurse_trim_skip(stream, [], strip_chars)
    |> list.reverse
    |> merge_history(Accumulator(0, [], history), _)
  }

  let combined_history: List(HistoryEntry) =
    argv.load().arguments |> list.fold([], read_history)

  // isn't this sorting a bit premature?
  let sorted_history: List(HistoryEntry) =
    list.sort(combined_history, by: fn(a, b) {
      case a, b {
        a, b if a.timestamp == b.timestamp -> Eq
        a, b if a.timestamp < b.timestamp -> Lt
        a, b if a.timestamp > b.timestamp -> Gt
        _, _ -> Eq
      }
    })
    // Remove duplicate entries from each timestamp
    // weirdness; at this point HistoryEntry is always one item, I should
    // probably remove the list wrapping as I don't seem to use it
    |> dedupe_on_ts
    |> list.reverse

  // expand every #(ts, [a,b..]) to #(ts, a), #(ts, b), ...

  let expanded =
    list.fold(sorted_history, [], expanded__fold)
    |> list.reverse

  // remove consecutive identical commands
  let deduped_prev = dedupe_on_prev(expanded)

  io.print(string.join(
    list.map(deduped_prev, fn(entry) {
      let #(timestamp, command) = entry
      "#" <> int.to_string(timestamp) <> "\n" <> command <> "\n"
    }),
    with: "",
  ))
  Nil
}
