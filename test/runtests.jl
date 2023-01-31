using Test
using AtomicFileWrite

mktempdir() do dir; cd(dir) do
    fname = "1"
    e = ArgumentError("msg")

    @test atomic_write(io->print(io,"write"), fname) === nothing
    @test read(fname, String) == "write"
    @test atomic_write(io->print(io,"overwrite"), fname) === nothing
    @test read(fname, String) == "overwrite"

    @test_throws e atomic_write(fname) do io
        println(io, "don't write this")
        throw(e)
    end
    @test read(fname, String) == "overwrite"

    if Sys.iswindows()
        io2 = nothing
        @test_throws Base.IOError atomic_write(fname) do io
            println(io, "don't write that")
            io2 = open(fname)  # On windows, should fail overwriting open file
        end
        @test io2 isa IOStream
        close(io2)
        @test read(fname, String) == "overwrite"
    end

    dirname = "dir"
    mkdir(dirname)
    @test_throws Exception atomic_write(io->print(io,"write"), dirname)

    backup = "$fname.bck"
    @test atomic_write(io->print(io,"overwrite 2"), fname; backup=backup) === nothing
    @test read(fname, String) == "overwrite 2"
    @test read(backup, String) == "overwrite"

    @test_throws ArgumentError atomic_write(io->print(io,"overwrite backup"), fname; backup=backup)
    @test read(fname, String) == "overwrite 2"
    @test read(backup, String) == "overwrite"

    @test atomic_write(io->print(io,"overwrite backup"), fname;
                        backup=backup, overwrite_backup=true) === nothing
    @test read(fname, String) == "overwrite backup"
    @test read(backup, String) == "overwrite 2"
end; end
