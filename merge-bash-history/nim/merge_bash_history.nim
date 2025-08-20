import sequtils

import std/cmdline
import std/strutils
import std/algorithm

import std/tables

proc readHistory() =
  var history = initTable[int64, seq[string]]()
  var newTs: int64 = 0
  var ts: int64 = 0
  var accumulated: seq[string]

  proc history_add(ts: int64, s: string) =
    if ts notin history:
      history[ts] = @[]
    history[ts].add(s)

  for path in commandLineParams():
    let f = open(path)
    defer:
      f.close()

    for line in lines(f):
      if line.len == 0:
        continue
      block isTimestamp:
        if startsWith(line, "#"):
          # If the line doesn't parse as a timestamp, isTimestamp block is
          # skipped and the line is instead accumulated.
          newTs = try: parseInt(line[1 .. ^1]) except: break isTimestamp

          if accumulated.len > 0:
            history_add(ts, accumulated.join("\n"))
            accumulated = @[]

          ts = newTs
          continue

      # Multi-line history entry handling, accumulate lines until a new
      # timestamp is read.
      accumulated.add(line.strip(leading = false))

    # Last line(s)
    history_add(ts, accumulated.join("\n"))

  var previousEntry: string

  for ts in history.keys.toSeq.sorted:
    # Discard non-consecutive commands sharing timestamp
    for entry in deduplicate(history[ts]):
      # Discard empty lines
      if entry.len == 0:
        continue
      # Discard repeated entries (ignoring timestamp)
      if entry == previousEntry:
        continue
      echo "#", ts
      echo entry
      previousEntry = entry

readHistory()
