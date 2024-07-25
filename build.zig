const std = @import("std");

pub const libOptions = struct {
    target: std.Build.ResolvedTarget,
    optimization: std.builtin.OptimizeMode,
};

fn buildzlib(b: *std.Build, options: libOptions) *std.Build.Step.Compile {
    const zRogue = b.addStaticLibrary(.{
        .name = "zRogue",
        .optimize = options.optimization,
        .target = options.target,
        .link_libc = true,
    });

    zRogue.linkSystemLibrary("SDL2");
    zRogue.linkSystemLibrary("epoxy");
    zRogue.linkLibC();
    zRogue.addCSourceFiles(.{
        .files = &[_][]const u8{"lib/fake.c"},
    });
    zRogue.addIncludePath(b.path("lib/"));

    return zRogue;
}

pub const ExampleOptions = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    mod_zRogue: *std.Build.Module,
};

fn buildExample(b: *std.Build, comptime name: []const u8, options: ExampleOptions) !void {
    const example_src = "examples/" ++ name ++ ".zig";
    var run: ?*std.Build.Step.Run = null;

    const example = b.addExecutable(.{
        .name = name,
        .root_source_file = b.path(example_src),
        .target = options.target,
        .optimize = options.optimize,
    });
    example.root_module.addImport("zRogue", options.mod_zRogue);
    b.installArtifact(example);
    run = b.addRunArtifact(example);
    b.step("run-" ++ name, "Run " ++ name).dependOn(&run.?.step);
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});
    std.log.info("[INFO] Target OS: {}\n", .{target.result.os.tag});
    std.log.info("[INFO] Target CPU: {}\n", .{target.result.cpu.arch});
    std.log.info("[INFO] Optimization Level: {}\n", .{optimize});

    const examples = .{
        "basic-window",
        "draw-sprite",
        "draw-map",
    };
    // Uncomment these as needed
    // "user-input",
    // "movable-sprite",

    const lib = buildzlib(b, .{
        .target = target,
        .optimization = optimize,
    });

    const zrogue_module = b.addModule("zRogue", .{ .root_source_file = b.path("src/zRogue.zig") });
    zrogue_module.linkLibrary(lib);
    zrogue_module.addIncludePath(b.path("lib/"));

    const exe = b.addExecutable(.{
        .name = "zRogue",
        .root_source_file = b.path("testBuild/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("zRogue", zrogue_module);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Run examples
    inline for (examples) |ex| {
        try buildExample(b, ex, .{
            .mod_zRogue = zrogue_module,
            .target = target,
            .optimize = optimize,
        });
    }
}
