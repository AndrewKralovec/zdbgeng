const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const DbgEngExtension = @import("../core/debugger.zig").DbgEngExtension;
const dbgeng = @import("../dbgeng/bindings.zig");

/// Handle user commands in the REPL.
pub fn handleCommand(allocator: Allocator, debugger: *DbgEngExtension, input: []const u8) !void {
    const trimmed = std.mem.trim(u8, input, " \t\r\n");
    if (trimmed.len == 0) return;

    if (std.mem.eql(u8, trimmed, "quit") or std.mem.eql(u8, trimmed, "q")) {
        return error.QuitRequested;
    }

    if (std.mem.eql(u8, trimmed, "status")) {
        const status = debugger.executionStatus() catch |err| {
            print("error getting status: {}\n", .{err});
            return;
        };
        print("execution status: {any} ", .{status});
        return;
    }

    // Convert to null terminated string for DbgEng.
    const cmd_z = try allocator.dupeZ(u8, trimmed);
    defer allocator.free(cmd_z);

    debugger.executeCommand(cmd_z) catch |err| {
        print("error executing command: {}\n", .{err});
        return;
    };

    // If its an execution command, wait for the next event.
    if (isExecutionCommand(trimmed)) {
        print("waiting for event...\n", .{});
        debugger.waitForEvent(dbgeng.INFINITE) catch |err| {
            print("error waiting for event: {}\n", .{err});
            return;
        };

        const status = debugger.executionStatus() catch |err| {
            print("error getting status after event: {}\n", .{err});
            return;
        };

        if (status == .status_break) {
            print("break event\n", .{});
            debugger.executeCommand(".lastevent") catch |err| {
                print("error getting last event: {}\n", .{err});
            };
        } else if (status == .no_debuggee) {
            print("target process exited\n", .{});
            return error.TargetExited;
        }
    }
}

/// Returns true if a command will resume execution.
pub fn isExecutionCommand(input: []const u8) bool {
    if (input.len == 0) return false;

    if (input.len == 1) {
        return input[0] == 'g' or input[0] == 'p' or input[0] == 't';
    }

    // TODO: Make this more optimal, hash map, maybe.
    // Multi-character execution commands.
    return std.mem.startsWith(u8, input, "go") or
        std.mem.startsWith(u8, input, "pa") or // step over (various forms)
        std.mem.startsWith(u8, input, "pt") or
        std.mem.startsWith(u8, input, "ph") or
        std.mem.startsWith(u8, input, "tc") or // trace and count
        std.mem.startsWith(u8, input, "tb"); // trace to next branch
}
