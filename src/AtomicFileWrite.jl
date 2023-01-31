module AtomicFileWrite

export atomic_write

function atomic_write(f, path; backup=nothing, overwrite_backup=false)
    isdir(path) && error("Cannot `atomic_write` to `path`: is a directory")
    # The temp file is created in the same location as `path`,
    # to ensure it's on the same device and can atomically replace 
    # the target at `path` using `jl_fs_rename`
    tmp_path = dirname(path)
    # On Windows, `mktemp("")` creates the temp file at "/" rather than "."
    isempty(tmp_path) && (tmp_path = ".")

    mktemp(tmp_path) do temp_path, temp_io
        f(temp_io)
        backup === nothing || cp(path, backup; force=overwrite_backup)
        close(temp_io)
        _replace(temp_path, path)
    end
end

# Unlike Base.mv, no fallback to cp && rm on error, to ensure atomicity
function _replace(src, dst)
    err = ccall(:jl_fs_rename, Int32, (Cstring, Cstring), src, dst)
    Base.uv_error("Failed to replace $dst with $src", err)
end

end
