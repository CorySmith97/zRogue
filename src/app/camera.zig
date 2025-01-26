const std = @import("std");
pub const vec2 = [2]f32;
pub const vec3 = [3]f32;
pub const mat4 = [16]f32;

const Self = @This();
position: vec3,
target: vec3,
up: vec3,
zoom: f32,
rotation: f32,
near_plane: f32,
far_plane: f32,
fov: f32,
view_matrix: mat4,
projection_matrix: mat4,
aspect_ratio: f32,

pub fn init(
    self: *Self,
    aspect_ratio: f32,
) void {
    const position = .{ 4, 1, 4 };
    const target = .{ 0, 0, 0 };
    const up = .{ 0, 1, 0 };
    const near_plane = 0.1;
    const far_plane = 1000;
    const fov = 45;

    const view_matrix: mat4 = lookAt(position, target, up);
    const projection_matrix: mat4 = ortho(
        0,
        1200,
        800,
        0,
        near_plane,
        far_plane,
    );

    self.* = .{
        .position = position,
        .target = target,
        .up = up,
        .zoom = 1.0,
        .rotation = 0.0,
        .aspect_ratio = aspect_ratio,
        .near_plane = near_plane,
        .far_plane = far_plane,
        .fov = fov,
        .view_matrix = view_matrix,
        .projection_matrix = projection_matrix,
    };
}

pub fn distanceBetweenVec3(v1: vec3, v2: vec3) f32 {
    return @sqrt(
        std.math.pow(f32, (v1[0] - v2[0]), 2) + std.math.pow(f32, (v1[1] - v2[1]), 2) + std.math.pow(f32, (v1[2] - v2[2]), 2),
    );
}

pub fn recalcViewProj(self: *Self) void {
    const view_matrix: mat4 = lookAt(self.position, self.target, self.up);
    const projection_matrix: mat4 = perspective(
        self.fov,
        self.aspect_ratio,
        self.near_plane,
        self.far_plane,
    );
    self.view_matrix = view_matrix;
    self.projection_matrix = projection_matrix;
}

pub fn front(self: *Self) vec3 {
    return normalizeVec3(subVec3(self.target, self.position));
}

pub fn rotate(self: *Self, angle: f32) void {
    self.rotation = angle * 2 * std.math.pi / 180;

    const radius = distanceBetweenVec3(self.position, self.target);

    self.position[0] = self.position[0] + radius * @cos(self.rotation);
    self.position[2] = self.position[2] + radius * @sin(self.rotation);

    self.view_matrix = lookAt(.{ self.position[0], self.position[1], self.position[2] }, self.target, self.up);
}

pub fn lookAt(pos: vec3, target: vec3, up: vec3) mat4 {
    const z_axis = normalizeVec3(subVec3(pos, target));
    const x_axis = normalizeVec3(crossVec3(up, z_axis));
    const y_axis = crossVec3(z_axis, x_axis);

    const view: mat4 = .{
        x_axis[0],             y_axis[0],            -z_axis[0],            0,
        x_axis[1],             y_axis[1],            -z_axis[1],            0,
        x_axis[2],             y_axis[2],            -z_axis[2],            0,
        -dotVec3(x_axis, pos), dotVec3(y_axis, pos), -dotVec3(z_axis, pos), 1,
    };
    return view;
}

pub fn addVec3(v1: vec3, v2: vec3) vec3 {
    return .{ v1[0] + v2[0], v1[1] + v2[1], v1[2] + v2[2] };
}

pub fn scaleVec3(v1: vec3, scaler: f32) vec3 {
    return .{ v1[0] * scaler, v1[1] * scaler, v1[2] * scaler };
}

pub fn dotVec3(v1: vec3, v2: vec3) f32 {
    return v1[0] * v2[0] + v1[1] * v2[1] + v1[2] * v2[2];
}

pub fn crossVec3(v1: vec3, v2: vec3) vec3 {
    return .{
        (v1[1] * v2[2] - v1[2] * v2[1]),
        (v1[0] * v2[2] - v1[2] * v2[0]),
        (v1[0] * v2[1] - v1[1] * v2[0]),
    };
}

pub fn subVec3(v1: vec3, v2: vec3) vec3 {
    return .{
        v1[0] - v2[0],
        v1[1] - v2[1],
        v1[2] - v2[2],
    };
}

pub fn normalizeVec3(vec: vec3) vec3 {
    const magnitude = @sqrt(vec[0] * vec[0] + vec[1] * vec[1] + vec[2] * vec[2]);
    return .{
        vec[0] / magnitude,
        vec[1] / magnitude,
        vec[2] / magnitude,
    };
}

pub fn perspective(
    fov: f32,
    aspect_ratio: f32,
    near: f32,
    far: f32,
) mat4 {
    const half_tan_fov = @tan(fov / 2.0);
    //
    const proj: mat4 = .{
        1.0 / (aspect_ratio * half_tan_fov), 0.0,                0.0,                                0.0,
        0.0,                                 1.0 / half_tan_fov, 0.0,                                0.0,
        0.0,                                 0.0,                -(far + near) / (far - near),       -1.0,
        0.0,                                 0.0,                -(2.0 * far * near) / (far - near), 0.0,
    };
    return proj;
}

pub fn ortho(
    left: f32,
    right: f32,
    top: f32,
    bottom: f32,
    near: f32,
    far: f32,
) mat4 {
    const mat: mat4 = .{ 2.0 / (right - left), 0, 0, -(right + left) / (right - left), 0, 2.0 / (top - bottom), 0, -(top + bottom) / (top - bottom), 0, 0, 2.0 / (far - near), -(far + near) / (far - near), 0, 0, 0, 1 };
    return mat;
}

pub fn magnitudeVec3(v1: vec3) f32 {
    return @sqrt(v1[0] * v1[0] + v1[1] * v1[1] + v1[2] * v1[2]);
}

pub fn computeAngleBetweenVec3(v1: vec3, v2: vec3) f32 {
    return std.math.acos(dotVec3(v1, v2) / (magnitudeVec3(v1) * magnitudeVec3(v2)));
}
