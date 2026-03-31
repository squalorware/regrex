/// This module contains type-safe wrappers for various bitwise flags used by libc regex.h
const clib = @import("c_api.zig");
const testing = @import("std").testing;

const Error = @import("errors.zig").PosixError;

/// Default zero bit to use if no output modifications required
pub const null_flag: c_int = 0;
/// If this bit is set, use extended syntax; basic posix syntax otherwise
pub const use_extended: c_int = clib.fextended;
/// If this bit is set, ignore character case
pub const ignore_case: c_int = clib.ficase;
/// If this bit is set, anchors do not match at new line chars inside the string
pub const no_match_newline: c_int = clib.fnewline;
/// If this bit is set, return only success or fail
pub const results_only: c_int = clib.fnosub;
/// If this bit is set, beginning-of-line character doesn't match beginning of string
pub const no_bol_string: c_int = clib.fnotbol;
/// Same as `no_bol_string` but for the end of line
pub const no_eol_string: c_int = clib.fnoteol;
/// If this bit is set, limit start and end of search in buffer by PMATCH[0]
pub const limit_start_end: c_int = clib.fstartend;

const cflags_mask: c_int =
    use_extended |
    ignore_case |
    no_match_newline |
    results_only;

const eflags_mask: c_int =
    no_bol_string |
    no_eol_string |
    limit_start_end;

/// Checks if provided flags match the acceptable bit mask;
fn isValid(mask: c_int, bits: c_int) bool {
    return (bits & ~mask) == 0;
}

/// Takes bits and checks if they are valid cflags or eflags
fn from(mask: c_int, bits: c_int) Error!c_int {
    if (bits == null_flag) return null_flag;

    if (!isValid(mask, bits)) return Error.InvalidByteSequence;

    return bits;
}

pub fn cflags(bits: c_int) Error!c_int {
    return from(cflags_mask, bits);
}

pub fn eflags(bits: c_int) Error!c_int {
    return from(eflags_mask, bits);
}

test "Should return flags.null_flag if bits == 0" {
    const cf_result = try cflags(null_flag);
    try testing.expectEqual(null_flag, cf_result);
    const ef_result = try eflags(null_flag);
    try testing.expectEqual(null_flag, ef_result);
}

test "Should accept single valid flag" {
    const cf_result = try cflags(use_extended);
    try testing.expectEqual(use_extended, cf_result);
    const ef_result = try eflags(no_bol_string);
    try testing.expectEqual(no_bol_string, ef_result);
}

test "Should accept combined flags" {
    const _cflags = use_extended | ignore_case;
    const cf_result = try cflags(_cflags);
    try testing.expectEqual(_cflags, cf_result);
    const _eflags = no_bol_string | no_eol_string;
    const ef_result = try eflags(_eflags);
    try testing.expectEqual(_eflags, ef_result);
}

test "Should reject invalid bits" {
    const bad_bits: c_int = 1 << 20;

    try testing.expectError(Error.InvalidByteSequence, cflags(bad_bits));
    try testing.expectError(Error.InvalidByteSequence, eflags(bad_bits));
}

test "Should reject valid + invalid bits" {
    const bad_bits: c_int = 1 << 20;
    const _cflags = use_extended | bad_bits;
    try testing.expectError(Error.InvalidByteSequence, cflags(_cflags));
    const _eflags = no_bol_string | bad_bits;
    try testing.expectError(Error.InvalidByteSequence, eflags(_eflags));
}
