const std = @import("std");
const Parser = @import("Parser.zig");

const Dice = Parser.Dice;
const Die = Parser.Die;

allocator: std.mem.Allocator,
dices: []const Dice,
modifiers: []const isize,

const Dicex = @This();

/// Compile a dice expression.
pub fn compile(allocator: std.mem.Allocator, de: []const u8) !Dicex {
    var parser = Parser.init(allocator);
    defer parser.deinit();

    try parser.parse(de);

    return .{
        .allocator = allocator,
        .dices = try parser.dices.toOwnedSlice(),
        .modifiers = try parser.modifiers.toOwnedSlice(),
    };
}

pub fn deinit(self: *Dicex) void {
    self.allocator.free(self.dices);
    self.allocator.free(self.modifiers);
}

/// Roll the expression and return a total score.
pub fn roll(self: Dicex, rand: std.Random) isize {
    var score: isize = 0;

    for (self.dices) |dice| {
        score += dice.roll(rand);
    }

    for (self.modifiers) |mod| {
        score += mod;
    }

    return score;
}

test "compile" {
    const allocator = std.testing.allocator;
    var rand_impl = std.Random.DefaultPrng.init(0);

    var de = try compile(allocator, "1d6");
    defer de.deinit();

    const score = de.roll(rand_impl.random());

    try std.testing.expect(1 <= score and score <= 6);
}

test "compile modifiers only" {
    const allocator = std.testing.allocator;
    var rand_impl = std.Random.DefaultPrng.init(0);

    var de = try compile(allocator, "1 + 2 + 3 + 4");
    defer de.deinit();

    try std.testing.expectEqual(10, de.roll(rand_impl.random()));
}

test "compile double negation" {
    const allocator = std.testing.allocator;
    var rand_impl = std.Random.DefaultPrng.init(0);

    var de = try compile(allocator, "- -10");
    defer de.deinit();

    try std.testing.expectEqual(10, de.roll(rand_impl.random()));
}

test "1d1" {
    const allocator = std.testing.allocator;
    var rand_impl = std.Random.DefaultPrng.init(0);

    var de = try compile(allocator, "1d1");
    defer de.deinit();

    try std.testing.expectEqual(1, de.roll(rand_impl.random()));
}

test "compile modifiers + mods" {
    const allocator = std.testing.allocator;
    var rand_impl = std.Random.DefaultPrng.init(0);

    var de = try compile(allocator, "10 + 1d4");
    defer de.deinit();

    const score = de.roll(rand_impl.random());

    try std.testing.expect(11 <= score and score <= 14);
}
