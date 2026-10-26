-- Update this to point to the location of the CHERIoT SDK
sdkdir = path.absolute("./cheriot-rtos/sdk")
set_project("CoreMark")

includes(sdkdir)

set_toolchains("cheriot-clang")

includes(path.join(sdkdir, "lib"))

option("board")
  set_default("sonata-1.1")

option("iterations")
  set_default(800)

compartment("coremark")
    set_default(false)
    add_includedirs(".", "..")
    add_deps("freestanding", "stdio")
    add_files("../core_main.c",
              "../core_list_join.c",
              "../core_matrix.c",
              "../core_state.c",
              "../core_util.c",
              "core_portme.c")
    if has_config("iterations") then
        add_defines("ITERATIONS=" .. get_config("iterations"))
    end

    -- Capture all compilation flags once xmake has resolved them.
    on_config(function (target)
        import("core.tool.compiler")
        local flags = compiler.compflags(target:sourcefiles()[1], {target = target})

        -- Exclude include paths to reduce noise
        local kept, skipnext = {}, false
        for _, f in ipairs(flags) do
            if skipnext then
                skipnext = false
            elseif f == "-I" or f == "-isystem" or f == "-iquote" then
                skipnext = true
            elseif not (f:match("^%-I") or f:match("^%-isystem") or f:match("^%-iquote")) then
                table.insert(kept, f)
            end
        end

        -- Render the compilation flag into a FLAGS_STR macro definition
        local str = table.concat(kept, " "):gsub("\\", "\\\\"):gsub('"', '\\"')
        target:add("defines", format('FLAGS_STR="%s"', str))
    end)

firmware("coremark_firmware")
    add_deps("coremark")
    on_load(function(target)
        target:values_set("board", "$(board)")
        target:values_set("threads", {
          {
            compartment = "coremark",
            priority = 1,
            entry_point = "cheriot_entry",
            stack_size = 0xe00,
            trusted_stack_frames = 6
          },
        }, {expand = false})
    end)
