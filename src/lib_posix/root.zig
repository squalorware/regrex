const std = @import("std");
const clib = @cImport(@cInclude("lib_posix.h"));
const mem = std.mem;

pub const flags = @import("cflags.zig");

/// Export type definitions for compiled pattern buffer size
pub const ReBufSize = clib.sizeof_regex_t;
pub const ReBufAlign = clib.alignof_regex_t;
pub const PatternBuffer = clib.regex_t;
pub const PatternMatch = clib.regmatch_t;

pub const CompilationError = error {
    PlatformError,
    NoMatchFound,
    PatternInvalid,
    CollatingContentInvalid,
    CharacterClassInvalid,
    BackslashTrailing,
    BackReferenceInvalid,
    LeftBracketUnmatched,
    ParenthesisImbalance,
    BraceUnmatched,
    BraceContentsInvalid,
    RangeEndInvalid,
    NoMemoryError,
    RepetitionInvalid,
    UnknownError,
};

fn mapErrorCodes(c_errno: c_int) CompilationError!void {
    switch(c_errno) {
        clib.REG_ENOSYS => return CompilationError.PlatformError,
        clib.REG_NOMATCH => return CompilationError.NoMatchFound,
        clib.REG_BADPAT => return CompilationError.PatternInvalid,
        clib.REG_ECOLLATE => return CompilationError.CollatingContentInvalid,
        clib.REG_ECTYPE => return CompilationError.CharacterClassInvalid,
        clib.REG_EESCAPE => return CompilationError.BackslashTrailing,
        clib.REG_ESUBREG => return CompilationError.BackReferenceInvalid,
        clib.REG_EBRACK => return CompilationError.LeftBracketUnmatched,
        clib.REG_EPAREN => return CompilationError.ParenthesisImbalance,
        clib.REG_EBRACE => return CompilationError.BraceUnmatched,
        clib.REG_BADBR => return CompilationError.BraceContentsInvalid,
        clib.REG_ERANGE => return CompilationError.RangeEndInvalid,
        clib.REG_ESPACE => return CompilationError.NoMemoryError,
        clib.REG_BADRPT => return CompilationError.RepetitionInvalid,
        else => return CompilationError.UnknownError,
    }
}

pub const RegExp = struct {
    const Self = @This();

    allocator: mem.Allocator,
    buffer: [*]PatternBuffer,
    match: PatternMatch,
    slice: []u8,

    pub fn init(alloc: mem.Allocator) CompilationError!Self {
        const slice: []u8 = alloc.alignedAlloc(u8, ReBufAlign, ReBufSize) catch |err| {
            switch(err) {
                mem.Allocator.Error => return CompilationError.NoMemoryError,
                else => return CompilationError.UnknownError,
            }
        };
        return .{
            .allocator = alloc,
            .buffer = @ptrCast(slice),
            .match = PatternMatch[0],
            .slice = slice,
        };
    }

    pub fn compile(self: Self, pattern: []u8, cflags: usize) CompilationError!RegExp {
        const result_code = clib.regcomp(self.buffer, pattern, cflags);
        if (result_code != 0) {
            return mapErrorCodes(result_code);
        }
        return self;
    }

    // pub fn matches(self: *Self) !void {}

    pub fn deinit(self: Self) void {
        self.allocator.free(self.slice);
        clib.regfree(self.buffer);
    }
};
