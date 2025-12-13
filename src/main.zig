const std = @import("std");
const print = std.debug.print;
const readCommand = @import("./utils/command.zig").readCommand;
const bytlen = @import("./utils/strings.zig").bytlen;
const DbgEngExtension = @import("./core/debugger.zig").DbgEngExtension;

pub fn main() !void {
    print("************** zdbgeng **************\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var cmd_buf = try readCommand(allocator);
    const cmd_line = bytlen(&cmd_buf);
    const target = cmd_buf[0..cmd_line];
    print("target: {s}\n", .{target});

    var debugger = try DbgEngExtension.init();
    defer debugger.deinit();

    try debugger.createProcess(@ptrCast(&cmd_buf));

    const status = try debugger.currentStatus();
    print("status: {any}\n", .{status});
}
