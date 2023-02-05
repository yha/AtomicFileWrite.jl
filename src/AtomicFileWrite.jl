module AtomicFileWrite

export atomic_write

function atomic_write(f, dst; backup=nothing, overwrite_backup=false)
    isdir(dst) && error("Cannot `atomic_write` to $dst: is a directory")
    # The temp file is created in the same location as `dst`,
    # to ensure it's on the same device and can atomically replace 
    # the target at `std` using `jl_fs_rename`
    dst_dir = dirname(dst)
    # On Windows, `mktemp("")` creates the temp file at "/" rather than "."
    isempty(dst_dir) && (dst_dir = ".")

    mktemp(dst_dir) do temp_path, temp_io
        f(temp_io)
        backup === nothing || cp(dst, backup; force=overwrite_backup)
        close(temp_io)
        _replace(temp_path, dst)
    end
end

# Unlike Base.mv, no fallback to cp && rm on error, to ensure atomicity
function _replace(src, dst)
    err = ccall(:jl_fs_rename, Int32, (Cstring, Cstring), src, dst)
    Base.uv_error("Failed to replace $dst with $src", err)
end

end
