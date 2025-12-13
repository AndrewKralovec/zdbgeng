const std = @import("std");

pub fn main() !void {
    std.debug.print("Hello from test program!\n", .{});

    var i: u32 = 0;
    while (i < 5) : (i += 1) {
        std.debug.print("Count: {}\n", .{i});
        std.time.sleep(500 * std.time.ns_per_ms);
    }

    std.debug.print("Goodbye!\n", .{});
}
