# AtomicFileWrite.jl

*Write to file atomically*

### What it does
This tiny package provides a single funtion, `atomic_write(f, path; backup=nothing, overwrite_backup=false)`, to atomically write to a file. 
`f` is applied to an open `IOStream` on a temporary file, which is then moved to `path`.
Thus, writing is committed to `path` only if it completed without error, otherwise the file at `path` is left untouched. 

The `backup` keyword may be used to specify a backup filename which will contain the original contents of `path` if `f` completed successfully.

### What it doesn't do
- There is no support for appending, only overwriting.
- It's not thread-safe when the `backup` keyword is used, since the backup is created by copying. It is only intended to be atomic when run from a single thread.

### Example:
```julia
using AtomicFileWrite

filename = "tmp.txt"
open(io->print(io,"original contents"), filename, "w")
try 
    atomic_write(filename) do io
        print(io, "new ")
        error("oops!")
        print(io, "contents")
    end
catch e
    showerror(stderr, e, catch_backtrace())
end

# original contents still intact after error
@assert read(filename, String) == "original contents"


backup = filename * ".bak"
atomic_write(io->print(io,"new contents"), filename, backup=backup, overwrite_backup=true)

@assert read(filename, String) == "new contents"
@assert read(backup, String) == "original contents"
```
