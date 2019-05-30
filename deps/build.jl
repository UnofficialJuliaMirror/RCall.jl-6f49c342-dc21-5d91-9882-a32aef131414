import Conda
@static if Sys.iswindows()
    import WinReg
end

include("setup.jl")

# 1) Try Conda
if uppercase(get(ENV, "R_CONDA", "FALSE")) == "TRUE"
    @info "Installing R via Conda.jl"
    using Conda
    Conda.add_channel("r")
    Conda.add("r")

    if Sys.iswindows()
        Rhome = joinpath(Conda.ROOTENV, "Lib", "R")
    else
        Rhome = joinpath(Conda.LIBDIR, "R")
    end
    @info "Using R installation installed by Conda at $Rhome"
else
    # 2) Try R_HOME environment variable
    Rhome = get(ENV, "R_HOME", "")
    if Rhome != ""
        @info "Using R installation specified by `R_HOME` environment variable at $Rhome"
    end

    # 3) See if R is in PATH
    if Rhome == ""
        try
            global Rhome
            Rhome = readchomp(`R RHOME`)
            @info "Using R installation found in `PATH` at $Rhome"
        catch
        end
    end

    # 4) Look up Windows registry
    if Rhome == "" && Sys.iswindows()
        using WinReg
        try
            global Rhome
            Rhome = WinReg.querykey(WinReg.HKEY_LOCAL_MACHINE,
                                    "Software\\R-Core\\R", "InstallPath")
            @info "Using R installation found in Windows registry at $Rhome"
        catch
        end
    end
end
if Rhome == ""
    error("No R installation found")
end

libR = locate_libR(Rhome)
@info "Using libR at $libR."

open("deps.jl", "w") do f
    println(f, "## This file is generated by deps/build.jl")
    println(f, :(const Rhome = $Rhome))
    println(f, :(const libR = $libR))
end
