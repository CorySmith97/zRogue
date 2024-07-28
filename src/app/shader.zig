const std = @import("std");
const c = @import("c.zig");

const Self = @This();
id: u32,

/// Loads the shaders at the given paths
pub fn init(vs_path: []const u8, fs_path: []const u8) !Self {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    _ = allocator;
    const vs: u32 = c.glCreateShader(c.GL_VERTEX_SHADER);
    c.glShaderSource(vs, 1, &vs_path.ptr, null);
    c.glCompileShader(vs);
    try checkShaderCompilation(vs);

    const fs: u32 = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    c.glShaderSource(fs, 1, &fs_path.ptr, null);
    c.glCompileShader(fs);
    try checkShaderCompilation(fs);

    const shaderProgram = c.glCreateProgram();
    c.glAttachShader(shaderProgram, vs);
    c.glAttachShader(shaderProgram, fs);
    c.glLinkProgram(shaderProgram);
    try checkProgramLinking(shaderProgram);

    c.glDeleteShader(vs);
    c.glDeleteShader(fs);

    return .{
        .id = shaderProgram,
    };
}
fn checkShaderCompilation(shader: u32) !void {
    var success: c_int = 0;
    c.glGetShaderiv(shader, c.GL_COMPILE_STATUS, &success);
    if (success == 0) {
        var infoLog: [1024]u8 = undefined;
        c.glGetShaderInfoLog(shader, 1024, null, &infoLog[0]);
        std.debug.print("Shader compilation error: {s}\n", .{infoLog[0..infoLog.len]});
        return error.ShaderCompilationFailed;
    }
}

fn checkProgramLinking(program: u32) !void {
    var success: c_int = 0;
    c.glGetProgramiv(program, c.GL_LINK_STATUS, &success);
    if (success == 0) {
        var infoLog: [1024]u8 = undefined;
        c.glGetProgramInfoLog(program, 1024, null, &infoLog[0]);
        std.debug.print("Program linking error: {s}\n", .{infoLog[0..infoLog.len]});
        return error.ProgramLinkingFailed;
    }
}
fn setBool(self: *Self, name: []const u8, value: bool) void {
    const location = c.glGetUniformLocation(self.id, name);
    c.glUniform1i(location, if (value) 1 else 0);
}

fn setInt(self: *Self, name: []const u8, value: i32) void {
    const location = c.glGetUniformLocation(self.id, name);
    c.glUniform1i(location, value);
}

fn setFloat(self: *Self, name: []const u8, value: f32) void {
    const location = c.glGetUniformLocation(self.id, name);
    c.glUniform1f(location, value);
}
