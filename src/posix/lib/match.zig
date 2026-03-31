const std = @import("std");
const Allocator = std.mem.Allocator;
const maxInt = std.math.maxInt;
const testing = std.testing;

const clib = @import("c_api.zig");
const errors = @import("errors.zig");

const Error = errors.PosixError;
const Pattern = @import("pattern.zig").Pattern;

const sent_val: usize = maxInt(usize);

/// A type-safe, Zig-native implementation of `regmatch_t`
///
/// Represents a half-open interval referring to a substring
/// of an input string using byte indices [start, end)
pub const Group = struct {
    const Self = @This();

    /// Start offset, inclusive
    start: usize,
    /// End offset, exclusive
    end: usize,

    /// Returns a sentinel group representing no match.
    ///
    /// Used when a capture group did not participate in the match
    pub fn none() Self {
        return .{ .start = sent_val, .end = sent_val };
    }

    /// Returns true if this group is a no-match sentinel
    pub fn isNone(self: Self) bool {
        return self.start == sent_val;
    }
};

/// Contains the matching results
///
/// Holds all capture groups including group 0 (full match)
/// and a reference to the original string
pub const Match = struct {
    const Self = @This();

    /// Capture groups (subgroups)
    ///
    /// Heap-allocated, must be freed with `deinit()`
    subgroups: []Group,
    /// Borrowed reference to original input
    input: []const u8,

    /// Returns the full match
    pub fn full(self: Self) []const u8 {
        const m = self.subgroups[0];
        return self.input[m.start..m.end];
    }

    /// Returns subgroup `i` (0 = full match)
    pub fn group(self: Self, i: usize) ![]const u8 {
        if (i >= self.subgroups.len) return Error.InvalidGroup;

        const m = self.subgroups[i];
        if (m.isNone()) return Error.NoMatch;

        return self.input[m.start..m.end];
    }

    /// Returns all capture groups excluding the full match
    pub fn groups(self: Self) []Group {
        return self.subgroups[1..];
    }

    /// Returns the start offset of a group at index `i`
    pub fn start(self: Self, i: usize) !usize {
        if (i >= self.subgroups.len) return Error.InvalidGroup;

        return self.subgroups[i].start;
    }

    /// Returns the end offset of a group at index `i`
    pub fn end(self: Self, i: usize) !usize {
        if (i >= self.subgroups.len) return Error.InvalidGroup;

        return self.subgroups[i].end;
    }

    /// Frees memory allocated for capture groups
    pub fn deinit(self: *Self, allocator: Allocator) void {
        allocator.free(self.subgroups);
    }
};

test "Group.none returns a none (sentinel) group" {
    const g = Group.none();

    try testing.expect(g.isNone());
}

test "Group.isNone returns false for valid Group" {
    const g = Group{ .start = 1, .end = 3 };

    try testing.expect(!g.isNone());
}

const test_input = "abc 123";

test "Match.full returns full match slice" {
    var groups = [_]Group{.{ .start = 0, .end = 3 }};

    const m = Match{ .subgroups = groups[0..], .input = test_input };

    try testing.expectEqualStrings("abc", m.full());
}

test "Match,group returns correct subgroup" {
    var groups = [_]Group{
        .{ .start = 0, .end = 7 },
        .{ .start = 0, .end = 3 },
        .{ .start = 4, .end = 7 },
    };

    const m = Match{ .subgroups = groups[0..], .input = test_input };

    try testing.expectEqualStrings("abc", try m.group(1));
    try testing.expectEqualStrings("123", try m.group(2));
}

test "Match.group returns an InvalidGroup error for an invalid index" {
    var groups = [_]Group{.{ .start = 0, .end = 3 }};

    const m = Match{ .subgroups = groups[0..], .input = test_input };

    try testing.expectError(Error.InvalidGroup, m.group(1));
}

test "Match.group returns a NoMatch error for a none Group" {
    var groups = [_]Group{ .{ .start = 0, .end = 3 }, Group.none() };

    const m = Match{ .subgroups = groups[0..], .input = test_input };

    try testing.expectError(Error.NoMatch, m.group(1));
}

test "Match.groups returns all subgroups except full match" {
    var groups = [_]Group{ .{ .start = 0, .end = 7 }, .{ .start = 0, .end = 3 }, .{ .start = 4, .end = 7 } };

    const m = Match{ .subgroups = groups[0..], .input = test_input };

    const gs = m.groups();

    try testing.expectEqual(@as(usize, 2), gs.len);
    try testing.expect(gs[0].start == 0 and gs[0].end == 3);
    try testing.expect(gs[1].start == 4 and gs[1].end == 7);
}

test "Match.start & Match.end return correct indices" {
    var groups = [_]Group{ .{ .start = 0, .end = 7 }, .{ .start = 4, .end = 7 } };

    const m = Match{ .subgroups = groups[0..], .input = test_input };

    try testing.expectEqual(@as(usize, 4), try m.start(1));
    try testing.expectEqual(@as(usize, 7), try m.end(1));
}

test "Match.start & Match.end return InvalidGroup error for an invalid index" {
    var groups = [_]Group{.{ .start = 0, .end = 3 }};

    const m = Match{ .subgroups = groups[0..], .input = test_input };

    try testing.expectError(Error.InvalidGroup, m.start(1));
    try testing.expectError(Error.InvalidGroup, m.end(1));
}
