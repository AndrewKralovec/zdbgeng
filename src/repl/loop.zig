const std = @import("std");
const print = std.debug.print;
const DbgEngExtension = @import("../core/debugger.zig").DbgEngExtension;
const handleCommand = @import("./commands.zig").handleCommand;

pub fn replLoop(allocator: std.mem.Allocator, debugger: *DbgEngExtension) !void {
    const stdin = std.io.getStdIn().reader();
    var input_buf: [4096]u8 = undefined;

    while (true) {
        // Check if target is still alive.
        const status = debugger.executionStatus() catch |err| {
            print("error getting status: {}\n", .{err});
            break;
        };

        if (status == .no_debuggee) {
            print("target process has exited.\n", .{});
            break;
        }

        print("zdbg> ", .{});
        const maybe_input = stdin.readUntilDelimiterOrEof(&input_buf, '\n') catch |err| {
            print("error reading input: {}\n", .{err});
            break;
        };

        if (maybe_input) |input| {
            handleCommand(allocator, debugger, input) catch |err| {
                if (err == error.QuitRequested) {
                    print("exiting debugger\n", .{});
                    break;
                }
                if (err == error.TargetExited) {
                    break;
                }
            };
        } else {
            print("EOF received, exiting!\n", .{});
            break;
        }
    }

    print("debugger session ended\n", .{});
}
