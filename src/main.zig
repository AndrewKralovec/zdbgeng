const std = @import("std");
const print = std.debug.print;
const readCommandLine = @import("./utils/command.zig").readCommandLine;
const DbgEngExtension = @import("./core/debugger.zig").DbgEngExtension;
const dbgeng = @import("./dbgeng/bindings.zig");

pub fn main() !void {
    print("************** zdbgeng **************\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const target = try readCommandLine(allocator);
    defer allocator.free(target);
    print("target: {s}\n", .{target});

    var debugger = try DbgEngExtension.init(allocator);
    defer debugger.deinit();

    debugger.createProcess(target.ptr) catch |err| {
        print("failed create process: {}\n", .{err});
        return;
    };

    debugger.waitForEvent(dbgeng.INFINITE) catch |err| {
        print("failed to wait for initial event: {}\n", .{err});
        return;
    };

    const initial_status = try debugger.executionStatus();
    if (initial_status != .status_break) {
        print("unexpected initial execution status {any}\n", .{initial_status});
    }
}
