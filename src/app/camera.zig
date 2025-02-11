const std = @import("std");
pub const vec2 = [2]f32;
pub const vec3 = [3]f32;
pub const mat4 = [16]f32;

pub const model_matrix: mat4 = .{
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1,
};

pub const Camera2D = struct {
    position: vec2 = .{ 0, 0 },
    offset: vec2 = .{ 0, 0 },
    zoom: f32 = 1.0,
};

const Camera = struct {
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
        const position = .{ 0, 0, 1 };
        const target = .{ 0, 0, 0 };
        const up = .{ 0, 1, 0 };
        const near_plane = -1;
        const far_plane = 1.0;
        const fov = 45;

        const view_matrix: mat4 = simple2DView(position);
        const projection_matrix = ortho(0, 1200, 800, 0, 0.1, // near
            100.0 // far
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
};

pub fn distanceBetweenVec3(v1: vec3, v2: vec3) f32 {
    return @sqrt(
        std.math.pow(f32, (v1[0] - v2[0]), 2) + std.math.pow(f32, (v1[1] - v2[1]), 2) + std.math.pow(f32, (v1[2] - v2[2]), 2),
    );
}

pub fn lookAt(eye: [3]f32, target: [3]f32, up: [3]f32) mat4 {
    // Calculate camera's forward direction (z axis)
    var f = [3]f32{
        target[0] - eye[0],
        target[1] - eye[1],
        target[2] - eye[2],
    };
    // Normalize f
    const f_length = @sqrt(f[0] * f[0] + f[1] * f[1] + f[2] * f[2]);
    if (f_length > 0) {
        f[0] /= f_length;
        f[1] /= f_length;
        f[2] /= f_length;
    }

    // Calculate camera's right direction (x axis)
    var s = [3]f32{
        f[1] * up[2] - f[2] * up[1],
        f[2] * up[0] - f[0] * up[2],
        f[0] * up[1] - f[1] * up[0],
    };
    // Normalize s
    const s_length = @sqrt(s[0] * s[0] + s[1] * s[1] + s[2] * s[2]);
    if (s_length > 0) {
        s[0] /= s_length;
        s[1] /= s_length;
        s[2] /= s_length;
    }

    // Calculate camera's up direction (y axis)
    const u = [3]f32{
        s[1] * f[2] - s[2] * f[1],
        s[2] * f[0] - s[0] * f[2],
        s[0] * f[1] - s[1] * f[0],
    };

    return .{
        s[0],                                             u[0],                                             -f[0],                                         0.0,
        s[1],                                             u[1],                                             -f[1],                                         0.0,
        s[2],                                             u[2],                                             -f[2],                                         0.0,
        -(s[0] * eye[0] + s[1] * eye[1] + s[2] * eye[2]), -(u[0] * eye[0] + u[1] * eye[1] + u[2] * eye[2]), f[0] * eye[0] + f[1] * eye[1] + f[2] * eye[2], 1.0,
    };
}
pub fn simple2DView(position: [3]f32) mat4 {
    return .{
        1.0,          0.0,          0.0,          0.0,
        0.0,          1.0,          0.0,          0.0,
        0.0,          0.0,          1.0,          0.0,
        -position[0], -position[1], -position[2], 1.0,
    };
}

pub fn translateIdentity(vec: vec3) mat4 {
    return .{
        1, 0, 0, vec[0],
        0, 1, 0, vec[1],
        0, 0, 1, vec[2],
        0, 0, 0, 1.0,
    };
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

pub fn scaleMat4(mat: mat4, scalar: f32) mat4 {
    var m: mat4 = undefined;
    for (mat, 0..) |_, j| {
        m[j] = mat[j] * scalar;
    }
    return m;
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
    const mat: mat4 = .{
        2.0 / (right - left), 0,                    0,                  -(right + left) / (right - left),
        0,                    2.0 / (top - bottom), 0,                  -(top + bottom) / (top - bottom),
        0,                    0,                    2.0 / (far - near), -(far + near) / (far - near),
        0,                    0,                    0,                  1,
    };
    return mat;
}

pub fn magnitudeVec3(v1: vec3) f32 {
    return @sqrt(v1[0] * v1[0] + v1[1] * v1[1] + v1[2] * v1[2]);
}

pub fn computeAngleBetweenVec3(v1: vec3, v2: vec3) f32 {
    return std.math.acos(dotVec3(v1, v2) / (magnitudeVec3(v1) * magnitudeVec3(v2)));
}
