const std = @import("std");
const c = @import("c.zig");

const Self = @This();
id: u32,

// Loads the shaders at the given paths
pub fn init(vs_path: []const u8, fs_path: []const u8) !Self {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var vs_file = try std.fs.cwd().openFile(vs_path, .{});
    defer vs_file.close();
    const vs_file_size = try vs_file.getEndPos();
    const vs_buffer = try allocator.alloc(u8, @intCast(vs_file_size));
    const vs_bytes = try vs_file.readAll(vs_buffer);
    _ = vs_bytes;
    const vs: u32 = c.glCreateShader(c.GL_VERTEX_SHADER);
    c.glShaderSource(vs, 1, &vs_buffer.ptr, null);
    c.glCompileShader(vs);
    try checkShaderCompilation(vs);

    var fs_file = try std.fs.cwd().openFile(fs_path, .{});
    defer fs_file.close();
    const fs_file_size = try fs_file.getEndPos();
    const fs_buffer = try allocator.alloc(u8, @intCast(fs_file_size));
    const fs_bytes = try fs_file.readAll(fs_buffer);
    _ = fs_bytes;
    const fs: u32 = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    c.glShaderSource(fs, 1, &fs_buffer.ptr, null);
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
