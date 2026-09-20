const std = @import("std");
const builtin = @import("builtin");

const GREEN = "\x1b[32m";
const RED = "\x1b[31m";
const RESET = "\x1b[0m";

pub fn main(init: std.process.Init) !void {
    var std_writer = std.Io.File.stdout().writer(init.io, &.{});
    var out = &std_writer.interface;

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
            try out.print("{s}[-]{s} {s}: {s}failed: {}{s}\n", .{ RED, RESET, name, RED, err, RESET });
            continue;
        };
        try out.print("{s}[+]{s} {s}: {s}passed{s}\n", .{ GREEN, RESET, name, GREEN, RESET });
    }
}
