const std = @import("std");
const Step = std.Build.Step;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const posix_mod = b.addModule("posix", .{
        .root_source_file = b.path("src/posix/root.zig"),
    });
    posix_mod.addCSourceFile(.{ .file = b.path("include/posix/regrex.c") });
    posix_mod.addIncludePath(b.path("include/posix"));

    const lib_mod = b.createModule(.{ .target = target, .optimize = optimize, .root_source_file = b.path("src/root.zig"), .imports = &.{.{ .name = "posix", .module = posix_mod }} });

    const lib = b.addLibrary(.{ .name = "regrex", .linkage = .static, .root_module = lib_mod });
    lib.linkLibC();

    b.installArtifact(lib);

    const install_docs = b.addInstallDirectory(.{
        .source_dir = lib.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });
    const docs_step = b.step("docs", "Generate documentation");
    docs_step.dependOn(&install_docs.step);

    const testing_step = b.step("test", "Run all tests");

    const posix_test_mod = b.createModule(.{ .root_source_file = b.path("src/posix/root.zig"), .target = target, .optimize = optimize });
    posix_test_mod.addCSourceFile(.{ .file = b.path("include/posix/regrex.c") });
    posix_test_mod.addIncludePath(b.path("include/posix"));

    const regrex_test_posix = b.addTest(.{
        .root_module = posix_test_mod,
    });
    regrex_test_posix.linkLibC();

    testing_step.dependOn(&b.addRunArtifact(regrex_test_posix).step);
}
