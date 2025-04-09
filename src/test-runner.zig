const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    const out = std.io.getStdOut().writer();

    for (builtin.test_functions) |f| {
        const name = blk: {
            const name = f.name;
            var it = std.mem.splitScalar(u8, name, '.');
            while (it.next()) |chunk| {
                if (std.mem.eql(u8, chunk, "test")) {
                    const rest = it.rest();
                    break :blk if (rest.len > 0) rest else name;
                }
            }
            break :blk name;
        };

        f.func() catch |err| {
            try out.print("{s} failed: {}\n", .{ name, err });
            continue;
        };
        try out.print(" {s} passed\n", .{name});
    }
}