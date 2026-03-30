const std = @import("std");
const mem = std.mem;
const testing = std.testing;

const clib = @import("c_api.zig");
const flags = @import("flags.zig");

pub const RegexPatternBuffer = clib.regex_t;
pub const RegexMatch = struct {
    matches: []clib.regmatch_t,
    input: []const u8,
};

pub const Error = error {
    /// Invalid regular expression (generic syntax error)
    InvalidPattern,
    /// `REG_EBRACK` unmatched `[` or `]`
    UnmatchedBracket,
    /// `REG_EPAREN` unmatched `(` or `)`
    UnmatchedParen,
    /// `REG_EBRACE` unmatched `{` or `}`
    UnmatchedBrace,
    /// `REG_BADRPT` invalid use of repetition operators `(*, +, ?, {,})`
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
    Unexpected,
};

pub const PosixRegexError = Error || flags.Error;

/// Maps C error codes to correspondent Zig errors
pub fn fromRegCompReturnCode(c_errno: c_int) Error {
    switch(c_errno) {
        clib.enosys => return Error.Unsupported,
        clib.badpat => return Error.InvalidPattern,
        clib.ecollate => return Error.InvalidCollationElement,
        clib.ectype => return Error.InvalidCharacterClass,
        clib.eescape => return Error.TrailingEscape,
        clib.esubreg => return Error.InvalidBackreference,
        clib.ebrack => return Error.UnmatchedBracket,
        clib.eparen => return Error.UnmatchedParen,
        clib.ebrace => return Error.UnmatchedBrace,
        clib.badbr => return Error.InvalidBounds,
        clib.erange => return Error.InvalidRange,
        clib.esize => return Error.PatternTooLarge,
        clib.espace => return Error.OutOfMemory,
        clib.badrpt => return Error.InvalidRepetition,
        clib.eend => return Error.UnexpectedEnd,
        else => return Error.Unexpected,
    }
}

/// Maps Zig errors back to correspondent C error codes.
/// 
/// Can be useful to retrieve a string containing an error message with `clib.regerror`
pub fn toRegexErrorCode(err_t: Error) c_int {
    switch(err_t) {
        Error.Unsupported => return clib.enosys,
        Error.InvalidPattern => return clib.badpat,
        Error.InvalidCollationElement => return clib.ecollate,
        Error.InvalidCharacterClass => return clib.ectype,
        Error.TrailingEscape => return clib.eescape,
        Error.InvalidBackreference => return clib.esubreg,
        Error.UnmatchedBracket => return clib.ebrack,
        Error.UnmatchedParen => return clib.eparen,
        Error.UnmatchedBrace => return clib.ebrace,
        Error.InvalidBounds => return clib.badbr,
        Error.InvalidRange => return clib.erange,
        Error.PatternTooLarge => return clib.esize,
        Error.OutOfMemory => return clib.espace,
        Error.InvalidRepetition => return clib.badrpt,
        Error.UnexpectedEnd => return clib.eend,
        Error.Unexpected => return 1,
    }
}


/// A Zig wrapper over the POSIX `regex_t` type.
///
/// This type owns the memory backing a `regex_t` instance used by
/// `regcomp` / `regexec`. Since the POSIX API expects the caller to
/// provide storage for `regex_t`, this struct allocates a properly sized
/// buffer and exposes it as a typed pointer.
///
/// The memory allocated here must be released with `deinit`. Additionally,
/// any resources allocated internally by `regcomp` should be released
/// (e.g. via `regfree`) before calling `deinit` if applicable.
pub const Regex = struct {
    const Self = @This();

    allocator: mem.Allocator,
    buffer: *RegexPatternBuffer,
    store: []u8,

    /// Initializes a new `Regex` instance.
    ///
    /// Allocates a buffer large enough to hold a `regex_t` object and
    /// prepares it for use with POSIX regex functions.
    ///
    /// The returned instance owns the allocated memory and must be
    /// released with `deinit`.
    ///
    /// Errors:
    /// - `Error.OutOfMemory` if allocation fails.
    pub fn init(allocator: mem.Allocator) Error!Self {
        const bufSize: usize = clib.sizeOfRegexT();

        const slice: []u8 = allocator.alloc(u8, bufSize) catch |err| switch (err) {
            mem.Allocator.Error.OutOfMemory => return Error.OutOfMemory,
        };

        return .{
            .allocator = allocator,
            .buffer = @ptrCast(slice.ptr),
            .store = slice,
        };
    }

    /// Releases the memory owned by this `Regex` instance.
    ///
    /// This frees the backing storage allocated in `init`.
    ///
    /// Note: This does NOT call `regfree`. If `regcomp` was used,
    /// the caller is responsible for ensuring that any internal
    /// allocations made by the POSIX regex engine are freed
    /// before calling `deinit`.
    pub fn deinit(self: *Self) void {
        self.allocator.free(self.store);
    }
};

/// Creates a Regex instance which contains an allocated buffer.
/// 
/// Calls extern C `regcomp` to compile a regular expression pattern
/// And store it in Regex.buffer until the memory is freed
pub fn compile(
    /// A memory allocator instance
    allocator: std.mem.Allocator,
    /// A string containing a regular expression pattern
    pattern: []const u8, 
    ///  Bit flags which can be passed to modify the result of `regcomp`
    cflags: c_int
) PosixRegexError!Regex  {
    var re = try Regex.init(allocator);
    defer re.deinit();
    // convert to a C pointer to null-terminated string
    const zt_pat = allocator.dupeZ(u8, pattern) catch |err| switch (err) {
        mem.Allocator.Error.OutOfMemory => return Error.OutOfMemory,
    };
    defer allocator.free(zt_pat);

    const __flags = try flags.from(flags.cflags_mask, cflags);
    const result: c_int = clib.regcomp(re.buffer, zt_pat.ptr, __flags);
    defer clib.regfree(re.buffer);

    if (result != 0) {
        return fromRegCompReturnCode(result);
    }
    return re;
}

/// Converts an error code to a string message with libc `regerror()`
/// 
/// A feature of `regerror()` is used here - if provided buffer size is 0, 
/// then this function returns buffer size it requires. This value is used
/// to allocate enough memory and call it the second time with 
/// a properly sized buffer
pub fn getErrorString(
    /// A memory allocator instance
    allocator: std.mem.Allocator, 
    /// Error set instance.
    err: Error,
    /// A pointer to compiled pattern buffer
    buffer: *RegexPatternBuffer
) ![]u8 {
    const errcode = toRegexErrorCode(err);
    // Do a first call with 4th parameter == 0 - then `regerror` returns an integer correspinding to 
    // buffer length/size required to display it
    const buf_size = clib.regerror(errcode, buffer, null, 0);
    var buf = try allocator.alloc(u8, buf_size);
    _ = clib.regerror(errcode, buffer, buf.ptr, buf.len);
    return buf[0..buf_size - 1];
}

test "Should correctly map C error code to Zig error" {
    const err_code: c_int = clib.eescape;
    try testing.expectEqual(Error.TrailingEscape, fromRegCompReturnCode(err_code));
}

test "Should correctly map Zig error to C error code" {
    try testing.expectEqual(clib.badbr, toRegexErrorCode(Error.InvalidBounds));
}

test "Regex object should not leak memory when created" {
    const alloc = testing.allocator;
    var re = try Regex.init(alloc);
    defer re.deinit();
    try testing.expect(true);
}

test "Should compile regex when given a valid pattern" {
    const alloc = testing.allocator;
    _ = try compile(alloc, "^[a-z]*$", flags.null_flag);
    try testing.expect(true);
}

test "Should throw an error on a broken pattern" {
    const alloc = testing.allocator;

    try testing.expectError(
        Error.UnmatchedBracket,
        compile(alloc, "^[a-z*$", flags.null_flag)
    );
}
