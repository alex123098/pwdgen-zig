const std = @import("std");
const symbols = @import("symbols.zig");
const Request = @import("request.zig");

pub fn generateNoWordlist(req: Request, allocator: std.mem.Allocator) ![]const u8 {
    if (req.verbose) {
        std.log.debug("> length: {}, disable numbers: {}, disable symbols: {}, disable uppercase letters: {}\n", .{
            req.length,
            req.no_numbers,
            req.no_special_symb,
            req.no_upper,
        });
    }
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
    if (req.verbose) {
        std.log.debug("> length: {}, disable numbers: {}, disable symbols: {}, disable uppercase letters: {}\n", .{
            req.length,
            req.no_numbers,
            req.no_special_symb,
            req.no_upper,
        });
        std.log.debug("> wordlist path: {s}\n", .{wordlist_path});
    }
    const st1_seed: u64 = @bitCast(std.time.milliTimestamp());
    var rng = std.Random.DefaultPrng.init(st1_seed);
    const rnd = rng.random();
    const word_idx = rnd.uintLessThan(u64, std.math.maxInt(u64));
    if (req.verbose) std.log.debug("> generated word_idx: {}\n", .{word_idx});

    const word = try pickWord(wordlist_path, word_idx, req.verbose, allocator);
    defer allocator.free(word);

    return try mangleWord(word, req, rnd, allocator);
}

fn mangleWord(word: []const u8, req: Request, rnd: std.Random, allocator: std.mem.Allocator) ![]const u8 {
    var res = try allocator.alloc(u8, req.length);
    errdefer allocator.free(res);

    if (word.len >= req.length) {
        @memcpy(res, word[0..req.length]);
        if (req.verbose) std.log.debug("> picked word is too long and will be truncated\n", .{});
        replaceSymbols(res, req, rnd);
        return res;
    }

    const len_diff = req.length - word.len;
    const pfx_len = len_diff / 2;
    const sfx_len = len_diff - pfx_len;
    if (req.verbose) std.log.debug("> generated prefix length: {}, generated suffix length: {}\n", .{
        pfx_len,
        sfx_len,
    });

    const alphabet = try req.alphabet(allocator);
    defer allocator.free(alphabet);

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

fn pickWord(wordlist_path: []const u8, word_idx: u64, verbose: bool, allocator: std.mem.Allocator) ![]const u8 {
    if (verbose) {
        var arena = std.heap.ArenaAllocator.init(allocator);
        defer arena.deinit();

        const alloc = arena.allocator();
        std.log.debug("> cwd path: {s}\n", .{
            try std.fs.cwd().realpathAlloc(alloc, "."),
        });
    }

    const file = try std.fs.cwd().openFile(wordlist_path, .{});
    defer file.close();
    var idx = word_idx + 1;

    const buf = try file.readToEndAlloc(allocator, 500_000_000);
    defer allocator.free(buf);

    while (true) {
        var words_count: u64 = 0;

        var iter = std.mem.splitScalar(u8, buf, '\n');
        while (iter.next()) |w| {
            words_count += 1;
            if (idx == words_count) {
                const res = try allocator.alloc(u8, w.len);
                @memcpy(res, w);
                if (verbose) std.log.debug("> picked word: {s}\n", .{w});
                return res;
            }
        }

        idx = idx % words_count;
        if (verbose) std.log.debug("> word_idx adjusted to {}\n", .{idx});
    }
}

test "can pick a word from a list" {
    const idx: u64 = 14344392;
    const path = "test_wordlist.txt";

    const word = try pickWord(path, idx, false, std.testing.allocator);
    defer std.testing.allocator.free(word);

    try std.testing.expectEqualStrings("1234567", word);
}
