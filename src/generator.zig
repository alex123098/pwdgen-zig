const std = @import("std");
const symbols = @import("symbols.zig");
const Request = @import("request.zig");

pub fn generateNoWordlist(req: Request, allocator: std.mem.Allocator) ![]const u8 {
    const alphabet = try req.alphabet(allocator);
    defer allocator.free(alphabet);

    const st1_seed: u64 = @bitCast(std.time.milliTimestamp());
    var rng = std.Random.DefaultPrng.init(st1_seed);
    const rnd = rng.random();
    var pwd = try allocator.alloc(u8, req.length);

    for (0..req.length) |i| {
        const idx = rnd.uintLessThan(usize, alphabet.len);
        pwd[i] = alphabet[idx];
    }
    return pwd;
}

pub fn generateWordlist(req: Request, wordlist_path: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    const st1_seed: u64 = @bitCast(std.time.milliTimestamp());
    var rng = std.Random.DefaultPrng.init(st1_seed);
    const rnd = rng.random();
    const word_idx = rnd.uintLessThan(u64, std.math.maxInt(u64));
    std.debug.print("> generated word_idx: {}\n", .{word_idx});

    const word = try pickWord(wordlist_path, word_idx, allocator);
    defer allocator.free(word);

    return try mangleWord(word, req, rnd, allocator);
}

fn mangleWord(word: []const u8, req: Request, rnd: std.Random, allocator: std.mem.Allocator) ![]const u8 {
    var res = try allocator.alloc(u8, req.length);
    errdefer allocator.free(res);

    const alphabet = try req.alphabet(allocator);
    defer allocator.free(alphabet);

    if (word.len >= req.length) {
        @memcpy(res, word[0..req.length]);
        replaceSymbols(res, req, rnd);
        return res;
    }

    const len_diff = req.length - word.len;
    const pfx_len = len_diff / 2;
    const sfx_len = len_diff - pfx_len;

    for (0..pfx_len) |i| {
        const idx = rnd.uintLessThan(usize, alphabet.len);
        res[i] = alphabet[idx];
    }
    for (0..sfx_len) |i| {
        const idx = rnd.uintLessThan(usize, alphabet.len);
        res[pfx_len + word.len + i] = alphabet[idx];
    }
    const word_res = res[pfx_len .. pfx_len + word.len];
    @memcpy(word_res, word);
    replaceSymbols(word_res, req, rnd);
    return res;
}

fn replaceSymbols(str: []u8, req: Request, rnd: std.Random) void {
    for (str) |*c| {
        const repl = symbols.replacements(c.*, !req.no_numbers, !req.no_special_symb);
        if (repl) |r| {
            const repl_idx = rnd.uintAtMost(usize, r.len);
            c.* = if (repl_idx == r.len) c.* else r[repl_idx];
        }
    }
}

fn pickWord(wordlist_path: []const u8, word_idx: u64, allocator: std.mem.Allocator) ![]const u8 {
    const file = try std.fs.cwd().openFile(wordlist_path, .{});
    defer file.close();
    var idx = word_idx + 1;

    const buf = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(buf);

    while (true) {
        var words_count: u64 = 0;

        var iter = std.mem.splitScalar(u8, buf, '\n');
        while (iter.next()) |w| {
            words_count += 1;
            if (idx == words_count) {
                const res = try allocator.alloc(u8, w.len);
                @memcpy(res, w);
                std.debug.print("> picked word: {s}\n", .{w});
                return res;
            }
        }

        idx = idx % words_count;
        std.debug.print("> word_idx adjusted to {}\n", .{idx});
    }
}

test "Can pick a word from a list" {
    const idx: u64 = 14344392;
    const path = "/usr/share/wordlists/seclists/Passwords/Leaked-Databases/rockyou.txt";

    const word = try pickWord(path, idx, std.testing.allocator);
    defer std.testing.allocator.free(word);

    try std.testing.expectEqualStrings("123456", word);
}
