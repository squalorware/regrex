const std = @import("std");
const Step = std.Build.Step;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_posix_mod = b.addModule("posix", .{
        .root_source_file = b.path("src/lib_posix/root.zig"),
    });

    const lib = b.addLibrary(.{
        .name = "regrex",
        .linkage = .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .root_source_file = b.path("src/root.zig"),
            .imports = &.{
                .{ .name = "posix", .module = lib_posix_mod }
            }
        })
    });
    lib.root_module.addIncludePath(b.path("include"));

    b.installArtifact(lib);
}
