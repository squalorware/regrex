# regrex

> A programmable regret - inevitable. Inexorable. The Crime and the Punishment.

## What is this?

**regrex** = Regret + RegEx

![REGRET](assets/readme.jpg)

An amateurish Zig library for working with regular expressions.

Currently provides a wrapper over POSIX `regex.h` (more specifically `glibc` implementation). Possibly support additional backends such as PCRE and (optionally) Python-style regex engines in the future.

## Installation

`zig fetch https://github.com/squalorware/regrex`

Then, in `build.zig`:

```
const regrex = b.dependency("regrex", .{});

exe.root_module.addImport("regrex", regrex.module("regrex"));
```

## Usage

```
const std = @import("std");
const regrex = @import("regrex");
const rePosix = regrex.posix;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var re = try rePosix.compile(allocator, "^[a-z]+$", rePosix.flags.null_flag);
    // do something (not implemented yet lolz)
}
```

## Build

Minimal required version for a successful build is 0.15.2

### Tests

Run `zig build test --summary all --verbose`
