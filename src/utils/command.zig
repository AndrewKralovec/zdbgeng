const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

/// Returns a null terminated command line string built from the command line arguments.
pub fn readCommandLine(allocator: Allocator) ![:0]u8 {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    if (args.len < 2) {
        print("Usage: {s} <executable> [args...]\n", .{args[0]});
        return error.InvalidArguments;
    }

    var cmdline = ArrayList(u8).init(allocator);
    defer cmdline.deinit();
    for (args[1..], 0..) |arg, i| {
        if (i > 0) try cmdline.append(' ');

        const needs_quotes = std.mem.indexOfScalar(u8, arg, ' ') != null;
        if (needs_quotes) try cmdline.append('"');
        try cmdline.appendSlice(arg);
        if (needs_quotes) try cmdline.append('"');
    }
    return try cmdline.toOwnedSliceSentinel(0);
}
