const std = @import("std");
const print = std.debug.print;
const readCommand = @import("./command.zig").readCommand;
const bytlen = @import("./util.zig").bytlen;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    print("************** zdbgeng **************\n", .{});

    var cmd_buf = try readCommand(allocator);
    const cmd_line = bytlen(&cmd_buf);
    const target = cmd_buf[0..cmd_line];
    print("{s}\n", .{target});
}
