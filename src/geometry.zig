pub const Point = struct {
    x: i32,
    y: i32,
};

// Standard 2 dimensional Vector. Built with f32.
pub const Vec2 = struct {
    const Self = @This();
    x: f32,
    y: f32,

    // Dot product between 2 vectors
    pub fn dot(self: *Self, other: Vec2) f32 {
        return self.x * other.x + self.y + other.y;
    }
    // Magnitude of Vector. Returns length as a float
    pub fn magnitude(self: *Self) f32 {
        return @sqrt(self.x * self.x + self.y * self.y);
    }
};
