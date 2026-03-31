// const Allocator = @import("std").mem.Allocator;
const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;
const clib = @import("c_api.zig");

pub const PosixError = error{
    /// Invalid regular expression (generic syntax error)
    InvalidPattern,
    /// `REG_NOMATCH` No match found
    NoMatch,
    /// `REG_EBRACK` unmatched `[` or `]`
    UnmatchedBracket,
    /// `REG_EPAREN` unmatched `(` or `)`
    UnmatchedParen,
    /// `REGX_ILLSEQ` invalid multibyte sequence
    InvalidByteSequence,
    /// `REGX_BADGRP` Requested capture group does not exist within the matches
    InvalidGroup,
    /// `REGX_EGRPLMT` Exceeded maximum number of groups
    ExceededGroupLimit,
    /// `REG_EBRACE` unmatched `{` or `}`
    ///
    /// `REG_BADRPT` invalid use of repetition operators `(*, +, ?, {,})` -
    ///  these are often mixed up in the POSIX standard, so better handling them as one
    /// to avoid uncertainty
    InvalidRepetition,
    /// `REG_BADBR` invalid contents of `{}` (e.g. {2,1}, non-numeric)
    InvalidBounds,
    /// `REG_ERANGE` invalid character range (e.g. `[z-a]`)
    InvalidRange,
    /// `REG_ECTYPE` invalid character class name (e.g. `[:foo:]`)
    InvalidCharacterClass,
    /// `REG_ECOLLATE` invalid collating element (`[[. .]]`)
    InvalidCollationElement,
    /// `REG_EESCAPE` trailing `\` at the end of a pattern
    TrailingEscape,
    /// `REG_ESUBREG` invalid backreference number
    InvalidBackreference,
    /// `REG_ESIZE` compiled regex exceeds implementation limits
    PatternTooLarge,
    /// `REG_ESPACE` not enough memory to compile regex
    OutOfMemory,
    /// `REG_EEND` Unexpected end of pattern (premature termination)
    UnexpectedEnd,
    /// `REG_ENOSYS` Function/feature not implemented
    Unsupported,
    /// Unknown error
    Unknown,
};

/// Maps C error codes to correspondent Zig errors
pub fn fromRegCompReturnCode(c_errno: c_int) PosixError {
    switch (c_errno) {
        clib.enosys => return PosixError.Unsupported,
        clib.enomatch => return PosixError.NoMatch,
        clib.ebadpat => return PosixError.InvalidPattern,
        clib.ecollate => return PosixError.InvalidCollationElement,
        clib.ectype => return PosixError.InvalidCharacterClass,
        clib.eescape => return PosixError.TrailingEscape,
        clib.esubreg => return PosixError.InvalidBackreference,
        clib.ebrack => return PosixError.UnmatchedBracket,
        clib.eparen => return PosixError.UnmatchedParen,
        clib.ebrace => return PosixError.InvalidRepetition,
        clib.ebadbr => return PosixError.InvalidBounds,
        clib.erange => return PosixError.InvalidRange,
        clib.esize => return PosixError.PatternTooLarge,
        clib.espace => return PosixError.OutOfMemory,
        clib.ebadrpt => return PosixError.InvalidRepetition,
        clib.eend => return PosixError.UnexpectedEnd,
        clib.eillseq => return PosixError.InvalidByteSequence,
        clib.ebadgrp => return PosixError.InvalidGroup,
        clib.egrplmt => return PosixError.ExceededGroupLimit,
        else => return PosixError.Unknown,
    }
}

/// Maps Zig errors back to correspondent C error codes.
///
/// Can be useful to retrieve a string containing an error message with `clib.regerror`
pub fn toRegexErrorCode(err_t: PosixError) c_int {
    switch (err_t) {
        PosixError.Unsupported => return clib.enosys,
        PosixError.NoMatch => return clib.enomatch,
        PosixError.InvalidPattern => return clib.ebadpat,
        PosixError.InvalidByteSequence => return clib.eillseq,
        PosixError.InvalidGroup => return clib.ebadgrp,
        PosixError.ExceededGroupLimit => return clib.egrplmt,
        PosixError.InvalidCollationElement => return clib.ecollate,
        PosixError.InvalidCharacterClass => return clib.ectype,
        PosixError.TrailingEscape => return clib.eescape,
        PosixError.InvalidBackreference => return clib.esubreg,
        PosixError.UnmatchedBracket => return clib.ebrack,
        PosixError.UnmatchedParen => return clib.eparen,
        PosixError.InvalidBounds => return clib.ebadbr,
        PosixError.InvalidRange => return clib.erange,
        PosixError.PatternTooLarge => return clib.esize,
        PosixError.OutOfMemory => return clib.espace,
        PosixError.InvalidRepetition => return clib.ebadrpt,
        PosixError.UnexpectedEnd => return clib.eend,
        PosixError.Unknown => return 69,
    }
}

/// Determine size of the buffer required to store the error message
/// and check if it is a POSIX error or custom regrex error
fn getErrorStringBufSize(errcode: c_int) usize {
    if (errcode >= clib.eillseq) {
        // regrex error: call `regrex_error` with null to get buffer size
        return clib.regrex_error(errcode, null, 0);
    } else {
        // POSIX error: call `regerror` with null to get buffer size
        return clib.regerror(errcode, null, null, 0);
    }
}

/// Converts an error code to a string message with libc `regerror()`
///
/// A feature of `regerror()` is used here - if provided buffer size is 0,
/// then this function returns buffer size it needs. This value is used
/// to allocate required memory and call it the second time with
/// a properly sized buffer
pub fn toString(allocator: Allocator, err: PosixError) ![]u8 {
    const errcode: c_int = toRegexErrorCode(err);

    const buf_size: usize = getErrorStringBufSize(errcode);
    // Allocate buffer to store the message
    const buf = try allocator.alloc(u8, buf_size);

    if (errcode >= clib.eillseq) {
        _ = clib.regrex_error(errcode, buf.ptr, buf.len);
    } else {
        _ = clib.regerror(errcode, null, buf.ptr, buf.len);
    }

    return buf;
}

test "fromRegCompReturnCode maps error code to correct error type" {
    const err_code: c_int = clib.eescape;
    try testing.expectEqual(PosixError.TrailingEscape, fromRegCompReturnCode(err_code));
}

test "toRegexErrorCode maps error type to correct error code" {
    try testing.expectEqual(clib.ebadbr, toRegexErrorCode(PosixError.InvalidBounds));
}

test "toString returns a string with error message" {
    const alloc = testing.allocator;

    const msg = try toString(alloc, PosixError.Unknown);
    defer alloc.free(msg);

    std.debug.print("TEST: {s}\n", .{msg});
    try testing.expect(msg.len > 0);
}
