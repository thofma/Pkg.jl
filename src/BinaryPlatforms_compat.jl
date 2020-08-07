module BinaryPlatforms

using Base.BinaryPlatforms
export platform_key_abi, platform_dlext, valid_dl_path, arch, libc, compiler_abi,
       libgfortran_version, libstdcxx_version, cxxstring_abi, parse_dl_name_version,
       detect_libgfortran_version, detect_libstdcxx_version, detect_cxxstring_abi,
       call_abi, wordsize, triplet, select_platform, platforms_match,
       CompilerABI, Platform, UnknownPlatform, Linux, MacOS, Windows, FreeBSD

struct UnknownPlatform <: AbstractPlatform
end
tags(::UnknownPlatform) = Dict{String,String}()


struct CompilerABI
    libgfortran_version::Union{Nothing,VersionNumber}
    libstdcxx_version::Union{Nothing,VersionNumber}
    cxxstring_abi::Union{Nothing,Symbol}

    function CompilerABI(;libgfortran_version::Union{Nothing, VersionNumber} = nothing,
                         libstdcxx_version::Union{Nothing, VersionNumber} = nothing,
                         cxxstring_abi::Union{Nothing, Symbol} = nothing)
        return new(libgfortran_version, libstdcxx_version, cxxstring_abi)
    end
end

# Easy replacement constructor
function CompilerABI(cabi::CompilerABI; libgfortran_version=nothing,
                                        libstdcxx_version=nothing,
                                        cxxstring_abi=nothing)
    return CompilerABI(;
        libgfortran_version=something(libgfortran_version, Some(cabi.libgfortran_version)),
        libstdcxx_version=something(libstdcxx_version, Some(cabi.libstdcxx_version)),
        cxxstring_abi=something(cxxstring_abi, Some(cabi.cxxstring_abi)),
    )
end

libgfortran_version(cabi::CompilerABI) = cabi.libgfortran_version
libstdcxx_version(cabi::CompilerABI) = cabi.libstdcxx_version
cxxstring_abi(cabi::CompilerABI) = cabi.cxxstring_abi

for T in (:Linux, :Windows, :MacOS, :FreeBSD)
    @eval begin
        struct $(T) <: AbstractPlatform
            p::Platform
            function $(T)(arch::Symbol; compiler_abi=nothing, kwargs...)
                if compiler_abi !== nothing
                    kwargs[:libgfortran_version] = libgfortran_version(compiler_abi)
                    kwargs[:libstdcxx_version] = libstdcxx_version(compiler_abi)
                    kwargs[:cxxstring_abi] = cxxstring_abi(compiler_abi)
                end
                return Platform(arch, string($(T)); kwargs...)
            end
        end
    end

    # First, methods we need to coerce to Symbol for backwards-compatibility
    for f in (:arch, :libc, :call_abi, :cxxstring_abi)
        @eval begin
            $(f)(platform::$(T)) = Symbol($(f)(p.p))
        end
    end

    # Next, things we don't need to coerce
    for f in (:libgfortran_version, :libstdcxx_version, :platform_name, :wordsize, :platform_dlext)
        @eval begin
            $(f)(p::$(T)) = $(f)(p.p)
        end
    end

    # Finally, 
end

# Add one-off functions
MacOS(; kwargs...) = MacOS(:x86_64; kwargs...)
FreeBSD(; kwargs...) = FreeBSD(:x86_64; kwargs...)

"""
    platform_key_abi(machine::AbstractString)

Returns the platform key for the current platform, or any other though the
the use of the `machine` parameter.

This method is deprecated, use `Base.BinaryPlatforms.Platform()` instead.
"""
platform_key_abi() = Platform()
platform_key_abi(machine::AbstractString) = Platform(machine)

"""
    valid_dl_path(path::AbstractString, platform::Platform)

Return `true` if the given `path` ends in a valid dynamic library filename.
E.g. returns `true` for a path like `"usr/lib/libfoo.so.3.5"`, but returns
`false` for a path like `"libbar.so.f.a"`.

This method is deprecated and will be removed in Julia 2.0.
"""
function valid_dl_path(path::AbstractString, platform::Platform)
    try
        parse_dl_name_version(path, platform)
        return true
    catch
        return false
    end
end

end # module BinaryPlatforms