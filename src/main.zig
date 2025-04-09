const std = @import("std");
const clap = @import("clap");
const Request = @import("request.zig");
const symbols = @import("symbols.zig");
const generator = @import("generator.zig");

const DEFAULT_LENGTH = 12;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var allocator = gpa.allocator();
    const req = try parseRequest(allocator) orelse {
        std.process.exit(0);
    };
    defer {
        if (req.wordlist_path) |wp| {
            allocator.free(wp);
        }
    }

    const res = generate(req, allocator) catch |err| {
        try std.io.getStdErr().writer().print("{any}\n", .{err});
        return err;
    };

    try std.io.getStdOut().writer().print("{s}\n", .{res});
    allocator.free(res);
}

fn generate(req: Request, allocator: std.mem.Allocator) ![]const u8 {
    return if (req.wordlist_path) |wl|
        generator.generateWordlist(req, wl, allocator)
    else
        generator.generateNoWordlist(req, allocator);
}

fn parseRequest(allocator: std.mem.Allocator) !?Request {
    const params_def = comptime clap.parseParamsComptime(
        \\-v, --verbose             Output extra information
        \\-h, --help                Show this help message
        \\-l, --length <SYMBOLS>    Length of the generated password
        \\-w, --wordlist <PATH>     Wordlist file
        \\-S, --no-special          Do not use special characters
        \\-N, --no-numbers          Do not use numbers
        \\-U, --no-uppercase        Do not use uppercase letters
    );

    const parsers = comptime .{
        .SYMBOLS = clap.parsers.int(usize, 0),
        .PATH = clap.parsers.string,
    };

    var res = try clap.parse(clap.Help, &params_def, parsers, .{
        .allocator = allocator,
    });
    defer res.deinit();
    if (res.args.help != 0) {
        try clap.help(std.io.getStdOut().writer(), clap.Help, &params_def, .{});
        return null;
    }

    var req = Request{
        .verbose = res.args.verbose != 0,
        .length = res.args.length orelse DEFAULT_LENGTH,
        .no_numbers = res.args.@"no-numbers" != 0,
        .no_special_symb = res.args.@"no-special" != 0,
        .no_upper = res.args.@"no-uppercase" != 0,
        .wordlist_path = null,
    };
    if (res.args.wordlist) |wl| {
        const path = try allocator.alloc(u8, wl.len);
        @memcpy(path, wl);
        req.wordlist_path = path;
    }
    return req;
}

test {
    const r = Request{
        .verbose = false,
        .length = 12,
        .no_numbers = false,
        .wordlist_path = null,
        .no_special_symb = false,
        .no_upper = false,
    };
    _ = try generator.generateNoWordlist(r, std.testing.allocator);
}
