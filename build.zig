const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zRogue",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.linkSystemLibrary("sdl2");
    exe.linkSystemLibrary("sdl2_image");
    exe.linkFramework("opengl");
    exe.linkSystemLibrary("epoxy");
    exe.linkLibC();
    exe.addCSourceFiles(.{
        .files = &[_][]const u8{"lib/stb_impl.c"},
    });
    exe.addIncludePath(.{ .path = "lib" });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
