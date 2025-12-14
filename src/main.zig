const std = @import("std");
const print = std.debug.print;
const readCommandLine = @import("./utils/cli.zig").readCommandLine;
const replLoop = @import("./repl/loop.zig").replLoop;
const DbgEngExtension = @import("./core/debugger.zig").DbgEngExtension;
const INFINITE = @import("./dbgeng/bindings.zig").INFINITE;

pub fn main() !void {
    print("************** zdbgeng **************\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const target = try readCommandLine(allocator);
    defer allocator.free(target);

    var debugger = try DbgEngExtension.init(allocator);
    defer debugger.deinit();

    debugger.createProcess(target.ptr) catch |err| {
        print("failed create process: {}\n", .{err});
        return;
    };
    print("process created\n", .{});

    debugger.waitForEvent(INFINITE) catch |err| {
        print("failed to wait for initial event: {}\n", .{err});
        return;
    };

    const initial_status = try debugger.executionStatus();
    if (initial_status != .status_break) {
        print("unexpected initial execution status {any}\n", .{initial_status});
    }

    try replLoop(allocator, &debugger);
}
