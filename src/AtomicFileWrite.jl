module AtomicFileWrite

export atomic_write

function atomic_write(f, path; backup=nothing, overwrite_backup=false)
    mktemp() do temp_path, temp_io
        f(temp_io)
        isnothing(backup) || cp(path, backup; force=overwrite_backup)
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
