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
        .files = &[_][]const u8{"lib/stb_impl.c"},
    });
    zRogue.addIncludePath(.{ .path = "lib/" });

    return zRogue;
}

pub const ExampleOptions = struct {};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const examples = .{"hello-window"};

    const lib = buildzlib(b, .{ .target = target, .optimization = optimize });
    const zrogue_module = b.addModule(
        "zRogue",
        .{ .root_source_file = b.path("src/zRogue.zig") },
    );
    zrogue_module.linkLibrary(lib);
    zrogue_module.addCSourceFiles(.{
        .files = &[_][]const u8{"lib/stb_impl.c"},
    });
    zrogue_module.addIncludePath(.{ .path = "lib/" });
    _ = examples;

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
}
