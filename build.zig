const std = @import("std");

pub const libOptions = struct {
    target: std.Build.ResolvedTarget,
    optimization: std.builtin.OptimizeMode,
};

fn buildzlib(b: *std.Build, options: libOptions) *std.Build.Module {
    const zRogue = b.addStaticLibrary(.{
        .name = "zRogue",
        .root_source_file = b.path("src/root.zig"),
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

    b.installArtifact(zRogue);

    const extra_docs = b.addInstallDirectory(.{ .source_dir = zRogue.getEmittedDocs(), .install_dir = .prefix, .install_subdir = "docs" });

    const docs_step = b.step("docs", "Install docs into zig-out/docs");
    docs_step.dependOn(&extra_docs.step);

    const zrogue_module = b.addModule("zRogue", .{ .root_source_file = b.path("src/root.zig") });
    zrogue_module.linkLibrary(zRogue);
    zrogue_module.addIncludePath(b.path("lib/"));
    zrogue_module.addIncludePath(b.path("src/"));

    return zrogue_module;
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
        //"basic-window",
        "draw-sprite",
        //"draw-map",
        //"network",
        "sprite-viewer",
    };
    // Uncomment these as needed
    // "user-input",
    // "movable-sprite",

    const lib = buildzlib(b, .{
        .target = target,
        .optimization = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "zRogue",
        .root_source_file = b.path("testBuild/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("zRogue", lib);

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
            .mod_zRogue = lib,
            .target = target,
            .optimize = optimize,
        });
    }
}
