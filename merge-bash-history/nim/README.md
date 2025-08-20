Apparently NIM is very opinionated about filenames. And everything in Nim is a
module. This is confusing. And people are weird about it. A nim lang post asked
about it, the replies were along the lines of "well, does PYTHON support - in
modules?!". Have they never heard of scripts, executables, etc? Assuming
everyone understands that there are no executables in nim, only runnable
modules is /weird/. That said, nim author seemed chill about it and said "It
came up before, it does cause some head-scratching / friction, it is little
effort to support it, we should support it. We don't have to tell people "don't
use that" because why not... Nim should get out of the way, Nim is not about
petty rules.". Sadly, nothing happened and I like many had to go googling to
get half a clue about it.

To be fair, `nim` does have `-o:file`, `--out:file` but it's hidden away under
`--fullhelp`. And to the best of my knowledge and current level of headache vs
care can't find any mention about every .nim file being a module except in
passing under "Module". 

> Nim supports splitting a program into pieces with a module concept. Each
> module is in its own file. Modules enable information hiding and separate
> compilation. A module may gain access to the symbols of another module by
> using the import statement. Only top-level symbols that are marked with an
> asterisk (*) are exported:

https://nim-lang.org/docs/tut1.html#modules

Which I payed no attention to, I wasn't building a module. I was writing a
program. 

The `Nim Manual` mentions `To learn how to compile Nim programs and generate
documentation see the Compiler User Guide and the DocGen Tools Guide.`, so I
guess everything isn't a module? Let's see what the compiler docs says.

Aha, the compiler doesn't compile programs or modules. It compiles projects.
Under `Configuration files` there's this note:

> **Note**: The *project file name* is the name of the .nim file that is passed
> as a command-line argument to the compiler.

You know what. Nim has lots of things. Lots and lots. So many knobs and levers
to twist and pull. Whatever it is I think I want, Nim most likely handles it
perfectly well. I'll do it incorrectly for now, just because I want every
executable in every language to be the same. I'll learn the janitorial stuff
later.

Nim. You weird. Probably wonderful, but weird.
