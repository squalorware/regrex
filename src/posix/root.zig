/// This module exports Zig wrappers over POSIX regular expressions implementation in glibc
const std = @import("std");
const mem = std.mem;
const testing = std.testing;

const regex = @import("regex.zig");
const Regex = regex.Regex;

pub const flags = @import("flags.zig");
/// Bit flags parsing errors
pub const FlagsError = flags.Error;
/// Regex compilation and execution errors
pub const RegexError = regex.Error;
pub const PosixRegexError = regex.PosixRegexError;
pub const RegexPatternBuffer = regex.RegexPatternBuffer;
pub const compile: fn (mem.Allocator, []const u8, c_int) PosixRegexError!Regex = regex.compile;
pub const getErrorString: fn (mem.Allocator, RegexError, *RegexPatternBuffer) mem.Allocator.Error.OutOfMemory![]u8 = regex.getErrorString;
