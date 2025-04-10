const std = @import("std");
const symbols = @import("symbols.zig");
const Printer = @import("printer.zig");

const Self = @This();

verbose: bool,
length: usize,
wordlist_path: ?[]const u8,
no_special_symb: bool,
no_numbers: bool,
no_upper: bool,

pub fn alphabet(self: Self, printer: Printer, allocator: std.mem.Allocator) ![]const u8 {
    var total_len = symbols.all.len;
    if (self.no_special_symb) {
        total_len -= symbols.special.len;
    }
    if (self.no_numbers) {
        total_len -= symbols.numbers.len;
    }
    if (self.no_upper) {
        total_len -= symbols.uppercase.len;
    }

    var res = try allocator.alloc(u8, total_len);
    @memcpy(res[0..symbols.lowercase.len], symbols.lowercase);
    var offset = symbols.lowercase.len;
    if (!self.no_special_symb) {
        @memcpy(res[offset .. offset + symbols.special.len], symbols.special);
        offset += symbols.special.len;
    }
    if (!self.no_numbers) {
        @memcpy(res[offset .. offset + symbols.numbers.len], symbols.numbers);
        offset += symbols.numbers.len;
    }
    if (!self.no_upper) {
        @memcpy(res[offset .. offset + symbols.uppercase.len], symbols.uppercase);
        offset += symbols.uppercase.len;
    }
    if (self.verbose) {
        printer.detail("> generated alphabet: {s}\n", .{res});
    }

    return res;
}

test "correct alphabet for all symbols" {
    const r = Self{
        .length = 12,
        .no_special_symb = false,
        .no_numbers = false,
        .no_upper = false,
        .wordlist_path = null,
        .verbose = false,
    };

    const alpha = try r.alphabet(Printer.init(), std.testing.allocator);
    defer std.testing.allocator.free(alpha);

    const expected = symbols.all;
    try std.testing.expectEqualStrings(expected, alpha);
}

test "correct alphabet without special symbols" {
    const r = Self{
        .length = 12,
        .no_special_symb = true,
        .no_numbers = false,
        .no_upper = false,
        .wordlist_path = null,
        .verbose = false,
    };

    const alpha = try r.alphabet(Printer.init(), std.testing.allocator);
    defer std.testing.allocator.free(alpha);

    const expected = symbols.lowercase ++ symbols.numbers ++ symbols.uppercase;
    try std.testing.expectEqualStrings(expected, alpha);
}

test "correct alphabet without numbers" {
    const r = Self{
        .length = 12,
        .no_special_symb = false,
        .no_numbers = true,
        .no_upper = false,
        .wordlist_path = null,
        .verbose = false,
    };

    const alpha = try r.alphabet(Printer.init(), std.testing.allocator);
    defer std.testing.allocator.free(alpha);

    const expected = symbols.lowercase ++ symbols.special ++ symbols.uppercase;
    try std.testing.expectEqualStrings(expected, alpha);
}

test "correct alphabet without uppercase" {
    const r = Self{
        .length = 12,
        .no_special_symb = false,
        .no_numbers = false,
        .no_upper = true,
        .wordlist_path = null,
        .verbose = false,
    };

    const alpha = try r.alphabet(Printer.init(), std.testing.allocator);
    defer std.testing.allocator.free(alpha);

    const expected = symbols.lowercase ++ symbols.special ++ symbols.numbers;
    try std.testing.expectEqualStrings(expected, alpha);
}

test "correct alphabet without special symbols and numbers" {
    const r = Self{
        .length = 12,
        .no_special_symb = true,
        .no_numbers = true,
        .no_upper = false,
        .wordlist_path = null,
        .verbose = false,
    };

    const alpha = try r.alphabet(Printer.init(), std.testing.allocator);
    defer std.testing.allocator.free(alpha);

    const expected = symbols.lowercase ++ symbols.uppercase;
    try std.testing.expectEqualStrings(expected, alpha);
}

test "correct alphabet without special symbols and uppercase" {
    const r = Self{
        .length = 12,
        .no_special_symb = true,
        .no_numbers = false,
        .no_upper = true,
        .wordlist_path = null,
        .verbose = false,
    };

    const alpha = try r.alphabet(Printer.init(), std.testing.allocator);
    defer std.testing.allocator.free(alpha);

    const expected = symbols.lowercase ++ symbols.numbers;
    try std.testing.expectEqualStrings(expected, alpha);
}

test "correct alphabet without numbers and uppercase" {
    const r = Self{
        .length = 12,
        .no_special_symb = false,
        .no_numbers = true,
        .no_upper = true,
        .wordlist_path = null,
        .verbose = false,
    };

    const alpha = try r.alphabet(Printer.init(), std.testing.allocator);
    defer std.testing.allocator.free(alpha);

    const expected = symbols.lowercase ++ symbols.special;
    try std.testing.expectEqualStrings(expected, alpha);
}

test "correct alphabet without special symbols, numbers and uppercase" {
    const r = Self{
        .length = 12,
        .no_special_symb = true,
        .no_numbers = true,
        .no_upper = true,
        .wordlist_path = null,
        .verbose = false,
    };

    const alpha = try r.alphabet(Printer.init(), std.testing.allocator);
    defer std.testing.allocator.free(alpha);

    const expected = symbols.lowercase;
    try std.testing.expectEqualStrings(expected, alpha);
}