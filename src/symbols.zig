const std = @import("std");

pub const lowercase = "abcdefghijklmnopqrstuvwxyz";
pub const uppercase = "ABCDEFGHIJKLOMNPQRSTUVWXYZ";
pub const numbers = "0123456789";
pub const special = "-_=+*()^&%$#@!,./?|\\;:'\"";
pub const all = lowercase ++ special ++ numbers ++ uppercase;

pub fn replacements(char: u8, allow_num: bool, allow_sym: bool) ?[]const u8 {
    if (!allow_num and !allow_sym) {
        return null;
    }
    if (allow_num and !allow_sym) {
        return numbers_replacements(char);
    }
    if (!allow_num and allow_sym) {
        return sym_replacements(char);
    }
    return all_replacements(char);
}

fn all_replacements(char: u8) ?[]const u8 {
    switch (char) {
        'a', 'A' => return "4@",
        'b', 'B' => return "8",
        'd', 'D' => return "6",
        'e', 'E' => return "3",
        'g', 'G' => return "6",
        'h', 'H' => return "#",
        'i', 'I' => return "1!",
        'l', 'L' => return "1",
        'o', 'O' => return "0",
        'q', 'Q' => return "9",
        's', 'S' => return "5",
        't', 'T' => return "7",
        else => return null,
    }
}

fn numbers_replacements(char: u8) ?[]const u8 {
    switch (char) {
        'a', 'A' => return "4",
        'b', 'B' => return "8",
        'd', 'D' => return "6",
        'e', 'E' => return "3",
        'g', 'G' => return "6",
        'i', 'I' => return "1",
        'l', 'L' => return "1",
        'o', 'O' => return "0",
        'q', 'Q' => return "9",
        's', 'S' => return "5",
        't', 'T' => return "7",
        else => return null,
    }
}

fn sym_replacements(char: u8) ?[]const u8 {
    switch (char) {
        'a', 'A' => return "@",
        'h', 'H' => return "#",
        'i', 'I' => return "!",
        else => return null,
    }
}