const std = @import("std");

const MAIN_COLOR = "\x1b[97m";
const DETAILS_COLOR = "\x1b[38;5;7m";
const ERROR_COLOR = "\x1b[31m";
const RESET_COLOR = "\x1b[0m";

const Self = @This();

main_out: *std.Io.Writer,
error_out: *std.Io.Writer,
verbose: bool,

pub fn init(main_out: *std.Io.Writer, error_out: *std.Io.Writer, verbose: bool) Self {
    return .{
        .main_out = main_out,
        .error_out = error_out,
        .verbose = verbose,
    };
}

pub fn detail(self: Self, comptime format: []const u8, args: anytype) void {
    if (!self.verbose) return;

    self.error_out.writeAll(DETAILS_COLOR) catch unreachable;
    self.error_out.print(format, args) catch unreachable;
    self.error_out.writeAll(RESET_COLOR) catch unreachable;
}

pub fn err(self: Self, comptime format: []const u8, args: anytype) void {
    self.error_out.writeAll(ERROR_COLOR) catch unreachable;
    self.error_out.print(format, args) catch unreachable;
    self.error_out.writeAll(RESET_COLOR) catch unreachable;
}

pub fn out(self: Self, comptime format: []const u8, args: anytype) void {
    self.main_out.print(format, args) catch unreachable;
}
