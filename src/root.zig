/// Compile and test with POSIX regular expressions (implementation: glibc)
pub const posix = @import("posix");

comptime {
    const root = @This();
    for (@typeInfo(root).@"struct".decls) |decl| {
        const _Decl = @TypeOf(@field(root, decl.name));
        if (_Decl == void) continue;

        if (!@hasDecl(root, decl.name)) {
            @compileError("Missing declaration: " ++ decl.name);
        }

        if (_Decl != @TypeOf(@field(root, decl.name))) {
            @compileError("Declaration has wrong type: " ++ decl.name);
        }
    }
}
