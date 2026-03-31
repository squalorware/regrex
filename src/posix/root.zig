/// Zig wrapper over POSIX `regex.h` library
const Allocator = @import("std").mem.Allocator;

const clib = @import("lib/c_api.zig");
const pattern = @import("lib/pattern.zig");

pub const Error = @import("lib/errors.zig");
pub const Flags = @import("lib/flags.zig");

pub const compile: fn (Allocator, []const u8, c_int) Error!pattern.Pattern = pattern.compile;

test {
    _ = @import("lib/c_api.zig");
    _ = @import("lib/errors.zig");
    _ = @import("lib/exec.zig");
    _ = @import("lib/flags.zig");
    _ = @import("lib/match.zig");
    _ = @import("lib/pattern.zig");
}
