const std = @import("std");
const print = std.debug.print;
const readCommand = @import("./utils/command.zig").readCommand;
const bytlen = @import("./utils/strings.zig").bytlen;
const DbgEngExtension = @import("./core/debugger.zig").DbgEngExtension;
const dbgeng = @import("./dbgeng/bindings.zig");

pub fn main() !void {
    print("************** zdbgeng **************\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var cmd_buf = try readCommand(allocator);
    const cmd_line = bytlen(&cmd_buf);
    const target = cmd_buf[0..cmd_line];
    print("target: {s}\n", .{target});

    var debugger = try DbgEngExtension.init(allocator);
    defer debugger.deinit();

    debugger.createProcess(@ptrCast(&cmd_buf)) catch |err| {
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
