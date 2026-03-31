/// Internal regex execution utilities.
///
/// Provides buffer management and iteration primitives used to run
/// compiled patterns and produce match results.
const Allocator = @import("std").mem.Allocator;
const clib = @import("c_api.zig");
const errors = @import("errors.zig");
const flags = @import("flags.zig");
const match = @import("match.zig");
const Pattern = @import("pattern.zig").Pattern;
const Match = match.Match;
const Group = match.Group;

/// Maximal threshold for dynamic buffer size
const max_groups: usize = 1024;
const Error = errors.PosixError;

/// Internal wrapper used to call `regexec`
///
/// Allocates and manages a dynamic buffer to store raw `regmatch_t` objects.
pub const MatchBuffer = struct {
    const Self = @This();

    allocator: Allocator,
    /// Raw buffer for `regexec` results. Grows dynamically.
    raw: []clib.regmatch_t,

    pub fn init(allocator: Allocator) Self {
        return .{ .allocator = allocator, .raw = &[_]clib.regmatch_t{} };
    }

    pub fn deinit(self: *Self) void {
        if (self.raw.len > 0) {
            self.allocator.free(self.raw);
        }
    }

    /// Resize the internal buffer for capture groups
    fn grow(self: *Self, new_size: usize) !void {
        if (self.raw.len > 0) {
            self.allocator.free(self.raw);
        }
        self.raw = try self.allocator.alloc(clib.regmatch_t, new_size);
    }

    /// Call `regexec` to match the input against the compiled pattern
    ///
    /// Store results in the internal dynamic buffer;
    /// Increase buffer size if required; Maximum buffer size is limited to `max_groups`
    pub fn exec(self: *Self, pattern: *Pattern, input: []const u8, flag_bits: c_int) Error!bool {
        const eflags = try flags.eflags(flag_bits);

        var nmatch: usize = if (self.raw.len == 0) 4 else self.raw.len;

        while (true) {
            try self.grow(nmatch);

            const c_str = try self.allocator.dupeZ(u8, input);
            defer self.allocator.free(c_str);

            const result: c_int = clib.regexec(pattern.buffer, c_str, nmatch, self.raw.ptr, eflags);

            if (result == clib.enomatch) {
                return false;
            } else if (result != 0) {
                return errors.fromRegCompReturnCode(result);
            }

            const last = self.raw[nmatch - 1];
            const truncated = last.rm_so != -1;

            if (!truncated) return true;

            nmatch *= 2;

            if (nmatch > max_groups) {
                return Error.ExceededGroupLimit;
            }
        }
    }

    /// Convert raw `regmatch_t` to safe `Match`.
    ///
    /// Returned `Match` instance owns its memory which must be freed by the caller
    pub fn toMatch(self: *Self, allocator: Allocator, input: []const u8, offset: usize) !Match {
        var groups = try allocator.alloc(Group, self.raw.len);

        for (self.raw, 0..) |m, i| {
            if (m.rm_so == -1) {
                groups[i] = Group.none();
            } else {
                groups[i] = .{ .start = @as(usize, @intCast(m.rm_so)) + offset, .end = @as(usize, @intCast(m.rm_eo)) + offset };
            }
        }

        return Match{ .subgroups = groups, .input = input };
    }
};

/// Iterator over matches in the input string.
///
/// Lazy yields matches. Reuses internal buffer
pub const MatchIterator = struct {
    const Self = @This();

    pattern: *Pattern,
    input: []const u8,
    offset: usize,
    allocator: Allocator,
    buf: MatchBuffer,
    flags: c_int,

    pub fn init(pattern: *Pattern, allocator: Allocator, input: []const u8, eflags: c_int) Self {
        return .{ .pattern = pattern, .input = input, .offset = 0, .allocator = allocator, .buf = MatchBuffer.init(allocator), .flags = eflags };
    }

    pub fn deinit(self: *Self) void {
        self.buf.deinit();
    }

    /// Return the next `Match` or `null` if iteration is complete
    ///
    /// Each returned `Match` must be freed by the caller
    pub fn next(self: *Self) !?Match {
        if (self.offset > self.input.len) return null;

        const slice = self.input[self.offset..];

        const ok = try self.buf.exec(self.pattern, slice, self.flags);
        if (!ok) return null;

        const m = try self.buf.toMatch(self.allocator, self.input, self.offset);

        const full = m.subgroups[0];

        // Advance offset; avoid infinite loops on empty matches
        if (full.start == full.end) {
            self.offset += 1;
        } else {
            self.offset += full.end;
        }

        return m;
    }
};
