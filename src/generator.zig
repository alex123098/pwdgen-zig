const std = @import("std");
const symbols = @import("symbols.zig");
const Request = @import("request.zig");
const Printer = @import("printer.zig");
const Self = @This();

allocator: std.mem.Allocator,
io: std.Io,
seed: u64,

pub fn init(io: std.Io, allocator: std.mem.Allocator) Self {
    const ts = std.Io.Timestamp.now(io, .real);
    return .{
        .allocator = allocator,
        .io = io,
        .seed = @bitCast(ts.toMilliseconds()),
    };
}

pub fn generateNoWordlist(self: Self, req: Request, printer: Printer) ![]const u8 {
    printer.detail("> length: {}, disable numbers: {}, disable symbols: {}, disable uppercase letters: {}\n", .{
        req.length,
        req.no_numbers,
        req.no_special_symb,
        req.no_upper,
    });

    const alphabet = try req.alphabet(self.allocator);
    defer self.allocator.free(alphabet);
    printer.detail("> generated alphabet: {s}\n", .{alphabet});

    var rng = std.Random.DefaultPrng.init(self.seed);
    const rnd = rng.random();
    var pwd = try self.allocator.alloc(u8, req.length);

    for (0..req.length) |i| {
        const idx = rnd.uintLessThan(usize, alphabet.len);
        pwd[i] = alphabet[idx];
    }
    return pwd;
}

pub fn generateWordlist(self: Self, req: Request, wordlist_path: []const u8, printer: Printer) ![]const u8 {
    printer.detail("> length: {}, disable numbers: {}, disable symbols: {}, disable uppercase letters: {}\n", .{
        req.length,
        req.no_numbers,
        req.no_special_symb,
        req.no_upper,
    });
    printer.detail("> wordlist path: {s}\n", .{wordlist_path});

    var rng = std.Random.DefaultPrng.init(self.seed);
    const rnd = rng.random();
    const word_idx = rnd.uintLessThan(u64, std.math.maxInt(u64));
    printer.detail("> generated word_idx: {}\n", .{word_idx});

    const word = try self.pickWord(wordlist_path, word_idx, req.verbose, printer);
    defer self.allocator.free(word);

    return try mangleWord(word, req, rnd, printer, self.allocator);
}

fn mangleWord(word: []const u8, req: Request, rnd: std.Random, printer: Printer, allocator: std.mem.Allocator) ![]const u8 {
    var res = try allocator.alloc(u8, req.length);
    errdefer allocator.free(res);

    if (word.len >= req.length) {
        @memcpy(res, word[0..req.length]);
        printer.detail("> picked word is too long and will be truncated\n", .{});
        replaceSymbols(res, req, rnd);
        return res;
    }

    const len_diff = req.length - word.len;
    const pfx_len = len_diff / 2;
    const sfx_len = len_diff - pfx_len;
    printer.detail("> generated prefix length: {}, generated suffix length: {}\n", .{
        pfx_len,
        sfx_len,
    });

    const alphabet = try req.alphabet(allocator);
    defer allocator.free(alphabet);
    printer.detail("> generated alphabet: {s}\n", .{alphabet});

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
        } else if (req.no_upper and std.ascii.isUpper(c.*)) {
            c.* = std.ascii.toLower(c.*);
        }
    }
}

fn pickWord(self: Self, wordlist_path: []const u8, word_idx: u64, verbose: bool, printer: Printer) ![]const u8 {
    if (verbose) {
        var arena = std.heap.ArenaAllocator.init(self.allocator);
        defer arena.deinit();

        const alloc = arena.allocator();
        printer.detail("> cwd path: {s}\n", .{
            try std.Io.Dir.cwd().realPathFileAlloc(self.io, ".", alloc),
        });
    }

    const file = try std.Io.Dir.cwd().openFile(self.io, wordlist_path, .{});
    defer file.close(self.io);
    var idx = word_idx + 1;

    var reader = file.reader(self.io, &.{});
    const buf = try reader.interface.allocRemaining(self.allocator, .limited(500_000_000));
    defer self.allocator.free(buf);

    while (true) {
        var words_count: u64 = 0;

        var iter = std.mem.splitScalar(u8, buf, '\n');
        while (iter.next()) |w| {
            words_count += 1;
            if (idx == words_count) {
                const res = try self.allocator.alloc(u8, w.len);
                @memcpy(res, w);
                printer.detail("> picked word: {s}\n", .{w});
                return res;
            }
        }

        idx = idx % words_count;
        printer.detail("> word_idx adjusted to {}\n", .{idx});
    }
}

test "can pick a word from a list" {
    const idx: u64 = 14344392;
    const path = "test_wordlist.txt";
    const testing = std.testing;
    const gen = Self.init(testing.io, testing.allocator);

    const word = try gen.pickWord(path, idx, false, Printer.init(testing.io, false));
    defer std.testing.allocator.free(word);

    try std.testing.expectEqualStrings("1234567", word);
}
