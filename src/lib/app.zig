///
///    ███████╗██████╗  ██████╗  ██████╗ ██╗   ██╗███████╗
///    ╚══███╔╝██╔══██╗██╔═══██╗██╔════╝ ██║   ██║██╔════╝
///      ███╔╝ ██████╔╝██║   ██║██║  ███╗██║   ██║█████╗
///     ███╔╝  ██╔══██╗██║   ██║██║   ██║██║   ██║██╔══╝
///    ███████╗██║  ██║╚██████╔╝╚██████╔╝╚██████╔╝███████╗
///    ╚══════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝  ╚═════╝ ╚══════╝

// Imports
const std = @import("std");
const c = @cImport(@cInclude("SDL2/sdl.h"));

pub const app_desc = struct {
    const Self = @This();
    title: [*c]const u8,
    width: i32,
    height: i32,

    // function pointers that the user provides
    init: ?*const fn (void) void = null,
    tick: ?*const fn (void) void = null,
    events: ?*const fn (void) void = null,
};
