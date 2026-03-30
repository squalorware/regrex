/// This module contains type-safe wrappers for various bitwise flags used by libc regex.h
const clib = @import("c_api.zig");

pub const Error = error {
    InvalidValue,
};

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

pub const cflags_mask: c_int =
    use_extended |
    ignore_case |
    no_match_newline |
    results_only;

pub const eflags_mask: c_int =
    no_bol_string |
    no_eol_string |
    limit_start_end;

/// Checks if provided flags match the acceptable bit mask;
fn isValid(mask: c_int, bits: c_int) bool {
    return (bits & ~mask) == 0;
}

/// Takes bits and checks if they are valid cflags or eflags
pub fn from(mask: c_int, bits: c_int) Error!c_int {
    if  (bits == null_flag) return null_flag;

    if (!isValid(mask, bits)) return Error.InvalidValue;

    return bits;
}
