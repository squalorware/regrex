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

```zig
const regrex = b.dependency("regrex", .{});

exe.root_module.addImport("regrex", regrex.module("regrex"));
```

## Usage

Start by compiling your pattern

```zig
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();
const compile = regrex.posix.compile;
const flags = regrex.posix.flags;

var pattern = try compile(allocator, "^[a-z]+$", flags.use_extended);
defer pattern.deinit();
```
Or, if you want to print out an error message for debug
```zig
var pattern = compile(allocator, "^[a-z]+$", flags.use_extended) catch |err| {
    const msg = regrex.posix.Error.toString(allocator, err);
    defer allocator.free(msg);

    std.debug.print("Error: {s}\n", .{msg});
}
```
This gives you an instance of the `Pattern` type, which in this case is basically a wrapper over POSIX `regex_t`. Now you can perform the basic operations, like:

1. `search` (returns the first match independently of its position in the input string)
    ```zig
    var match = try pattern.search(allocator, "abc 123", flags.null_flag);
    ```
    This function returns us either an instance of `Match` type or a `null`. 
    
    `Match` is a structure containing a list of subgroups and a reference to the input string. Subgroups are an array of type `Group`, which is a type-safe native Zig re-implementation of `regmatch_t` - a half-open (starting offset is inclusive, ending offset is exclusive) interval which references a substring in the input by byte indices. `Match` owns the memory, so it is important never to forget to free the memory allocated to it. In case like above, where `Match` can be `null`, you can do it like this:
    ```zig
    if (match) |*m| {
        defer m.deinit(allocator);
    }
    ```
2. `match` (anchored to the initial subgroup, i.e. compares full string against the pattern.)
    ```zig
    var match = try pattern.match(allocator, "abc 123", flags.null_flag);
    ```
    Further handling is identical to `search`

3. `findIter` - returns an Iterator object that allows us to safely loop over all of matches in the string.
    ```zig
    var iter = pattern.findIter(allocator, "abc 123 def ghi", flags.null_flag);
    defer iter.deinit();

    while(try iter.next()) |m_val| {
        var m = m_val;
        // Don't forget - you must release memory for each Match instance, including yielded by the iterator
        defer m.deinit(allocator);

        // Print the full match
        std.debug.print("{s}\n", .{ m.full() });
    }
    ```

## Build

Minimal required version for a successful build is 0.15.2

### Tests

Run `zig build test --summary all --verbose`
