/// Top-level public C API
const clib = @cImport(@cInclude("regrex.h"));

/// glibc regex errors
pub const enosys: c_int = clib.REG_ENOSYS;
pub const badpat: c_int = clib.REG_BADPAT;
pub const ecollate: c_int = clib.REG_ECOLLATE;
pub const ectype: c_int = clib.REG_ECTYPE;
pub const eescape: c_int = clib.REG_EESCAPE;
pub const esubreg: c_int = clib.REG_ESUBREG;
pub const ebrack: c_int = clib.REG_EBRACK;
pub const eparen: c_int = clib.REG_EPAREN;
pub const ebrace: c_int = clib.REG_EBRACE;
pub const badbr: c_int = clib.REG_BADBR;
pub const erange: c_int = clib.REG_ERANGE;
pub const esize: c_int = clib.REG_ESIZE;
pub const espace: c_int = clib.REG_ESPACE;
pub const badrpt: c_int = clib.REG_BADRPT;
pub const eend: c_int = clib.REG_EEND;
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
// pub const sizeof_regex_t = 
pub const regcomp = clib.regcomp;
pub const regexec = clib.regexec;
pub const regerror = clib.regerror;
pub const regfree = clib.regfree;

pub fn sizeOfRegexT() usize {
    return clib.sizeof_regex_t;
}
