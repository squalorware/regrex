const re = @cImport(@cInclude("exegray_posix.h"));

/// If this bit is set, anchors do not match at new line chars inside the string
pub const UseExtended: usize = @intCast(re.REG_EXTENDED);
/// If this bit is set, ignore character case
pub const IgnoreCase: usize = @intCast(re.REG_ICASE);
/// If this bit is set, anchors do not match at new line chars inside the string
pub const NoMatchNewline: usize = @intCast(re.REG_NEWLINE);
/// If this bit is set, return only success or fail
pub const ResultOnly: usize = @intCast(re.NOSUB);
/// If this bit is set, beginning-of-line character doesn't match beginning of string
pub const StringStartNotBOL: usize = @intCast(re.REG_NOTBOL);
/// Same as REG_NOTBOL but for the end of line
pub const StringEndNotEOL: usize = @intCast(re.REG_NOTEOL);
/// If this bit is set, limit start and end of search in buffer by PMATCH[0]
pub const LimitStartEnd: usize = @intCast(re.REG_STARTEND);
