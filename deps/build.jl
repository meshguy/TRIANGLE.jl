using BinDeps

isfile("deps.jl") && rm("deps.jl")

@BinDeps.setup
    deps = [libnix = library_dependency("libtriangle", aliases = ["libtriangle.so","libtriangle.dylib"], runtime = false, os = :Unix),
            libwin = library_dependency("libtriangle", aliases = ["libtriangle.dll"], runtime = false, os = :Windows)]
    rootdir = BinDeps.depsdir(libnix)
    if is_windows()
        rootdir = BinDeps.depsdir(libwin)
    end
    srcdir = joinpath(rootdir, "src")
    prefix = joinpath(rootdir, "usr")
    libdir = joinpath(prefix, "lib")
    headerdir = joinpath(prefix, "include")

    if is_windows()
        libfile = joinpath(libdir, "libtriangle.dll")
        userdit = ENV["USERPROFILE"]
        vcpython="AppData\\Local\\Programs\\Common\\Microsoft\\Visual\ C++\ for\ Python\\9.0\\vcvarsall.bat"
        provides(BinDeps.SimpleBuild, (@build_steps begin
                 BinDeps.run(@build_steps begin
                    ChangeDirectory(srcdir)
                    `$userdit\\$vcpython & nmake -f makefile.win clean & nmake -f makefile.win`
                    `cmd /c copy libtriangle.dll $libfile`
                    `cmd /c copy triangle.h $headerdir`
                    `cmd /c copy tricall.h $headerdir`
                    `cmd /c copy commondefine.h $headerdir`
                    `$userdit\\$vcpython & nmake -f makefile.win clean`
            end) end), libwin)
    else 
        libname = "libtriangle.so"
        if is_apple()
            libname = "libtriangle.dylib"
        end
        libfile = joinpath(libdir, libname)
        provides(BinDeps.BuildProcess, (@build_steps begin
                    FileRule(libfile, @build_steps begin
                        BinDeps.ChangeDirectory(srcdir)
                        `make clean`
                        `make`
                        `cp libtriangle.so $libfile`
                        `cp triangle.h $headerdir/`
                        `cp tricall.h $headerdir/`
                        `cp commondefine.h $headerdir/`
                        `make clean`
                    end)
                end), libnix)
    end

if is_windows()
    @BinDeps.install Dict(:libwin => :jl_libtriangle)
else
    @BinDeps.install Dict(:libnix => :jl_libtriangle)
end