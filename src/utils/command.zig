const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

// NOTE: For those wondering why an allocator is needed on windows for arguments, its because on windows you dont actually get arguments as a list to the program.
// The arguments to a program is one string, and each program needs to parse this argument string into separate arguments.
// C does this in a hidden way before main and passes the arguments to main, so technically C programs can crash before main is even called if it gets out of memory when parsing the arguments.
// Zig doesn't have this hidden behavior that C has.
// source: https://www.youtube.com/watch?v=76_VHwQ6MyM
//
// TODO: Try a different allocator method than the video shows.
// Need to return null terminated slice.
// maybe: https://ziggit.dev/t/read-command-line-arguments/220/7
//
/// Returns a null terminated command line string built from the command line arguments.
pub fn readCommand(allocator: Allocator) ![1024]u8 {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        print("Usage: {s} <executable> [args...]\n", .{args[0]});
        print("Example: {s} notepad.exe\n", .{args[0]});
        return error.InvalidArguments;
    }

    // See note above.
    var cmdline_buf: [1024]u8 = undefined;
    var cmdline_stream = std.io.fixedBufferStream(&cmdline_buf);
    const writer = cmdline_stream.writer();
    // var cmdline_al = std.ArrayList(u8).init(allocator);
    // errdefer cmdline_al.deinit();

    // Join string from omitting the starting offset. TTrim quotes.
    for (args[1..], 0..) |arg, i| {
        if (i > 0) try writer.writeByte(' ');
        const needs_quotes = std.mem.indexOfScalar(u8, arg, ' ') != null;
        if (needs_quotes) try writer.writeByte('"');
        try writer.print("{s}", .{arg});
        if (needs_quotes) try writer.writeByte('"');
    }
    try writer.writeByte(0); // null terminator

    return cmdline_buf;
}
