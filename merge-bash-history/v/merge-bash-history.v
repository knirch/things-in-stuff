import os { read_lines }

fn main() {
	mut history := map[i64]string{}
	mut ts := i64(0)

	for path in arguments()[1..] {
		lines := read_lines(path)!

		mut accumulated := []string{}
		for line in lines {
			if line.starts_with('#') {
				if accumulated.len > 0 {
					for {
						if ts in history {
							ts += 1
						} else {
							break
						}
					}
					history[ts] = accumulated.join('\n')
					accumulated.clear()
				}

				ts = line.substr(1, line.len).i64() * 1000
				continue
			}
			accumulated << line.trim_space_right()
		}
		// Save remaining accumulated lines when transitioning between files
		if accumulated.len > 0 {
			for {
				if ts in history {
					ts += 1
				} else {
					break
				}
			}
			history[ts] = accumulated.join('\n')
			accumulated.clear()
		}
	}

	mut previous_entry := ''
	mut previous_ts := i64(0)
	mut entries_same_ts := []string{}

	for t in history.keys().sorted() {
		// Discard empty lines
		if history[t].len == 0 {
			continue
		}

		// Discard repeated commands
		if history[t] == previous_entry {
			continue
		}

		ts = t / 1000

		// Discard non-consecutive commands on same timestamp
		if ts != previous_ts {
			entries_same_ts.clear()
		}
		if history[t] in entries_same_ts {
			continue
		}
		entries_same_ts << history[t]

		println('#${ts}')
		println(history[t])

		previous_entry = history[t]
		previous_ts = ts
	}
}
