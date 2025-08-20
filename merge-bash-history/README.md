I horde my bash history. But I mess up, or disk becomes full, so I make random
backups at random times. I end up with lots of odd files. So I wanted a way of
combining them, but the bash history format is a bit wonky for regular tools.
This coincided with some odd idea that I should try something other than
python.

Tada, chaos.

What the tool is supposed to do;

1. Combine multiple .bash_history files
2. Sort by timestamp
3. Preserve multiline entries
4. Strip trailing whitespace
5. Remove duplicate entries on the same timestamp (and preserve order if
   multiple commands share the same timestamp, which will happen with how I've
   emergency backed up things)
6. Remove consecutive duplicates
