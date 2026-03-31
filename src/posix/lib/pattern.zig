const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;

const clib = @import("c_api.zig");
const errors = @import("errors.zig");
const exec = @import("exec.zig");
const flags = @import("flags.zig");
const Match = @import("match.zig").Match;
const Error = errors.PosixError;
const MatchBuffer = exec.MatchBuffer;
const MatchIterator = exec.MatchIterator;

/// Represents compiled pattern. Wraps over POSIX `regex_t`
///
/// Allocates buffer to store `regex_t` and exposes it as a typed pointer.
pub const Pattern = struct {
    const Self = @This();

    buffer: *clib.regex_t,

    /// Allocates a `regex_t` with C API
    ///
    /// Using C allocation instead of native Zig memory handling is necessary
    /// because `regex_t` is an opaque type - its size and alignment are unknown to Zig
    pub fn init() Error!Self {
        const ptr = clib.regrex_create() orelse return Error.OutOfMemory;

        return .{ .buffer = ptr };
    }

    /// Frees the memory allocated for the `regex_t` pattern
    ///
    /// First, `regfree` releases the internal state;
    /// then a C API function is called to free memory allocated in `init`
    pub fn deinit(self: *Self) void {
        clib.regfree(self.buffer);
        clib.regrex_destroy(self.buffer);
    }

    /// Search the input for the first pattern match no matter its position
    ///
    /// Return `Match` instance or `null` if no matches found
    pub fn search(self: *Self, allocator: Allocator, input: []const u8, eflags: c_int) !?Match {
        var buf: MatchBuffer = MatchBuffer.init(allocator);
        defer buf.deinit();

        const ok = try buf.exec(self, input, eflags);
        if (!ok) return null;

        return try buf.toMatch(allocator, input, 0);
    }

    /// Search for match at position 0 (i.e. full match)
    ///
    /// Return `Match` instance if found; `null` otherwise
    pub fn match(self: *Self, allocator: Allocator, input: []const u8, eflags: c_int) !?Match {
        const result = try self.search(allocator, input, eflags);
        if (result == null) return null;

        const m = result.?.subgroups[0];

        if (m.start != 0) {
            var tmp = result.?;
            tmp.deinit(allocator);
            return null;
        }

        return result;
    }

    /// Initialize an iterator instance to go over all matches in the input
    ///
    /// Note: for each `Match` yielded the memory must be freed by calling `Match.deinit()`
    pub fn findIter(self: *Self, allocator: Allocator, input: []const u8, eflags: c_int) MatchIterator {
        return MatchIterator.init(self, allocator, input, eflags);
    }
};

/// Initialize `Pattern` instance and compile the regular expression pattern
///
/// Call `regcomp` and store result in `Pattern.buffer` until the memory is freed
pub fn compile(allocator: Allocator, pattern: []const u8, flag_bits: c_int) Error!Pattern {
    var re = try Pattern.init();

    // convert to a C pointer to null-terminated string
    const c_str = allocator.dupeZ(u8, pattern) catch |err| switch (err) {
        Allocator.Error.OutOfMemory => return Error.OutOfMemory,
    };
    defer allocator.free(c_str);

    const cflags: c_int = try flags.cflags(flag_bits);
    const result: c_int = clib.regcomp(re.buffer, c_str.ptr, cflags);

    if (result != 0) {
        re.deinit();
        return errors.fromRegCompReturnCode(result);
    }
    return re;
}

test "compile doesn't return error and doesn't leak memory" {
    const alloc = testing.allocator;

    {
        var pattern = try compile(alloc, "^[a-z]*$", flags.null_flag);
        defer pattern.deinit();
    }
}

test "compile returns different error type depending on input" {
    const alloc = testing.allocator;

    try testing.expectError(Error.UnmatchedBracket, compile(alloc, "^[a-z*$", flags.null_flag));

    try testing.expectError(Error.UnmatchedParen, compile(alloc, "(abc", flags.use_extended));

    try testing.expectError(Error.InvalidRepetition, compile(alloc, "{0,1", flags.use_extended));

    try testing.expectError(Error.InvalidRange, compile(alloc, "[y-b]", flags.null_flag));
}

test "Pattern.search returns a Match" {
    const alloc = testing.allocator;
    var pattern = try compile(alloc, "[a-z]", flags.null_flag);
    defer pattern.deinit();

    var m = try pattern.search(alloc, "abc 123 def", flags.null_flag);
    if (m) |*match| {
        defer match.deinit(alloc);
    }
    try testing.expect(m != null);
}

test "Pattern.search returns null (no match)" {
    const alloc = testing.allocator;
    var pattern = try compile(alloc, "[A-Z]", flags.null_flag);
    defer pattern.deinit();

    var m = try pattern.search(alloc, "420 kek 69", flags.null_flag);
    if (m) |*match| {
        defer match.deinit(alloc);
    }

    try testing.expectEqual(null, m);
}

test "Pattern.match returns full match" {
    const alloc = testing.allocator;
    var pattern = try compile(alloc, "^\\w+\\s\\w+[.!?]$", flags.use_extended);
    defer pattern.deinit();

    var m = try pattern.match(alloc, "Hello World!", flags.null_flag);
    if (m) |*match| {
        defer match.deinit(alloc);
    }

    try testing.expect(m != null);
}

test "Pattern.match returns null (input doesn't match pattern)" {
    const alloc = testing.allocator;
    var pattern = try compile(alloc, "^[A-Za-z]+ [A-Za-z]+!$", flags.use_extended);
    defer pattern.deinit();

    var m = try pattern.match(alloc, "Hello 67 World!", flags.null_flag);
    if (m) |*match| {
        defer match.deinit(alloc);
    }

    try testing.expectEqual(null, m);
}

test "Pattern.findIter returns all matches" {
    const alloc = testing.allocator;
    var pattern = try compile(alloc, "[a-z]+", flags.use_extended);
    defer pattern.deinit();

    var iter = pattern.findIter(alloc, "abc 123 def", flags.null_flag);
    defer iter.deinit();

    var results: std.ArrayList([]const u8) = .empty;
    defer results.deinit(alloc);

    while (try iter.next()) |m_val| {
        var m = m_val;
        defer m.deinit(alloc);

        try results.append(alloc, m.full());
    }

    try testing.expectEqual(@as(usize, 2), results.items.len);
    try testing.expectEqualStrings("abc", results.items[0]);
    try testing.expectEqualStrings("def", results.items[1]);
}

test "Pattern.findIter returns null (no matches in input)" {
    const alloc = testing.allocator;
    var pattern = try compile(alloc, "^[A-Za-z]+ [A-Za-z]+$", flags.use_extended);
    defer pattern.deinit();

    var iter = pattern.findIter(alloc, "#@lol69420KeK", flags.null_flag);
    defer iter.deinit();

    const m = try iter.next();
    try testing.expectEqual(null, m);
}
