/// Top-level public C API
const clib = @cImport(@cInclude("regrex.h"));

/// glibc regex errors
pub const enosys: c_int = clib.REG_ENOSYS;
pub const enomatch: c_int = clib.REG_NOMATCH;
pub const ebadpat: c_int = clib.REG_BADPAT;
pub const ecollate: c_int = clib.REG_ECOLLATE;
pub const ectype: c_int = clib.REG_ECTYPE;
pub const eescape: c_int = clib.REG_EESCAPE;
pub const esubreg: c_int = clib.REG_ESUBREG;
pub const ebrack: c_int = clib.REG_EBRACK;
pub const eparen: c_int = clib.REG_EPAREN;
pub const ebrace: c_int = clib.REG_EBRACE;
pub const ebadbr: c_int = clib.REG_BADBR;
pub const erange: c_int = clib.REG_ERANGE;
pub const esize: c_int = clib.REG_ESIZE;
pub const espace: c_int = clib.REG_ESPACE;
pub const ebadrpt: c_int = clib.REG_BADRPT;
pub const eend: c_int = clib.REG_EEND;
// Custom errors following POSIX style
pub const eillseq: c_int = clib.REGX_ILLSEQ;
pub const ebadgrp: c_int = clib.REGX_BADGRP;
pub const egrplmt: c_int = clib.REGX_EGRPLMT;
/// glibc bit flags
pub const fextended: c_int = clib.REG_EXTENDED;
pub const ficase: c_int = clib.REG_ICASE;
pub const fnewline: c_int = clib.REG_NEWLINE;
pub const fnosub: c_int = clib.REG_NOSUB;
pub const fnotbol: c_int = clib.REG_NOTBOL;
pub const fnoteol: c_int = clib.REG_NOTEOL;
pub const fstartend: c_int = clib.REG_STARTEND;
/// Type and function aliases
pub const regex_t = clib.regex_t;
pub const regmatch_t = clib.regmatch_t;
pub extern fn regcomp(noalias __preg: ?*regex_t, noalias __pattern: [*c]const u8, __cflags: c_int) c_int;
pub extern fn regexec(noalias __preg: ?*const regex_t, noalias __String: [*c]const u8, __nmatch: usize, noalias __pmatch: [*c]regmatch_t, __eflags: c_int) c_int;
pub extern fn regfree(__preg: ?*regex_t) void;
pub extern fn regerror(__errcode: c_int, noalias __preg: ?*const regex_t, noalias __errbuf: [*c]u8, __errbuf_size: usize) usize;
pub extern fn regrex_create() ?*clib.regex_t;
pub extern fn regrex_destroy(*clib.regex_t) void;
/// Return an error message for custom error codes
///
/// Copies `regerror` functionality:
///   - if `errbuf` is `null`, returns required buffer size (null terminator included)
///   - Else write message to `errbuf` up to `errbuf_size` bytes and return written length (with null terminator)
pub extern fn regrex_error(c_int, [*c]u8, usize) usize;
