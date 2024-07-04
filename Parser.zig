const std = @import("std");
const Die = @import("Die.zig");

/// A handful of dice.
pub const Dice = struct {
    sign: i2 = 1,
    count: usize,
    die: Die,

    pub fn roll(self: Dice, rand: std.Random) isize {
        var score: isize = 0;

        for (0..self.count) |_| {
            score += @as(isize, @intCast(self.die.roll(rand)));
        }

        return score * self.sign;
    }
};

/// A flat modifier to be applied on the result.
pub const Modifier = struct {
    sign: i2 = 1,
    value: usize,
};

const ParseError = error{
    UndefinedDieFaces,
    UnexpectedCharacter,
};

allocator: std.mem.Allocator,
buffer: []const u8,
dice: std.ArrayList(Dice),
modifiers: std.ArrayList(Modifier),
pos: usize = 0,

const Parser = @This();

pub fn init(allocator: std.mem.Allocator) Parser {
    return .{
        .allocator = allocator,
        .buffer = undefined,
        .dice = std.ArrayList(Dice).init(allocator),
        .modifiers = std.ArrayList(Modifier).init(allocator),
    };
}

pub fn deinit(self: *Parser) void {
    self.dice.deinit();
    self.modifiers.deinit();
}

pub fn parse(self: *Parser, buffer: []const u8) !void {
    self.buffer = buffer;
    self.skipWhitespace(0);

    var sign: i2 = 1;

    while (self.pos < self.buffer.len) {
        const c = self.buffer[self.pos];

        if (c == '-') {
            sign *= -1;
            self.skipWhitespace(1);
            continue;
        }

        if (c == '+') {
            self.skipWhitespace(1);
            continue;
        }

        if (try self.parseNumber()) |n| {
            if (self.matchChar('d')) {
                if (try self.parseNumber()) |faces| {
                    try self.dice.append(.{ .sign = sign, .count = n, .die = .{ .faces = faces } });
                } else {
                    return error.UndefinedDieFaces;
                }
            } else {
                try self.modifiers.append(.{ .sign = sign, .value = n });
            }
        } else {
            return error.UnexpectedCharacter;
        }
    }
}

fn parseNumber(self: *Parser) !?usize {
    const start = self.pos;

    while (self.pos < self.buffer.len and std.ascii.isDigit(self.buffer[self.pos])) : (self.pos += 1) {}

    if (start == self.pos) {
        return null;
    }

    const end = self.pos;
    self.skipWhitespace(0);

    return try std.fmt.parseInt(usize, self.buffer[start..end], 10);
}

fn matchChar(self: *Parser, c: u8) bool {
    if (self.peekChar(c)) {
        self.skipWhitespace(1);
        return true;
    }
    return false;
}

fn peekChar(self: Parser, c: u8) bool {
    return self.pos < self.buffer.len and self.buffer[self.pos] == c;
}

fn skipWhitespace(self: *Parser, len: usize) void {
    self.pos += len;
    while (self.pos < self.buffer.len and std.ascii.isWhitespace(self.buffer[self.pos])) : (self.pos += 1) {}
}

test "simple die" {
    const allocator = std.testing.allocator;

    var p = Parser.init(allocator);
    defer p.deinit();

    try p.parse("1d6");

    try std.testing.expectEqual(1, p.dice.items.len);
    try std.testing.expectEqual(0, p.modifiers.items.len);
}

test "die with mod" {
    const allocator = std.testing.allocator;

    var p = Parser.init(allocator);
    defer p.deinit();

    try p.parse("1d6 + 5");

    try std.testing.expectEqual(1, p.dice.items.len);
    try std.testing.expectEqual(1, p.modifiers.items.len);
}

test "multiple mods" {
    const allocator = std.testing.allocator;

    var p = Parser.init(allocator);
    defer p.deinit();

    try p.parse("1 + 2 + 3 - 4");

    try std.testing.expectEqual(0, p.dice.items.len);
    try std.testing.expectEqual(4, p.modifiers.items.len);
}

test "unexpected char" {
    const allocator = std.testing.allocator;

    var p = Parser.init(allocator);
    defer p.deinit();

    try std.testing.expectError(error.UnexpectedCharacter, p.parse("something"));
}

test "undefined die faces" {
    const allocator = std.testing.allocator;

    var p = Parser.init(allocator);
    defer p.deinit();

    try std.testing.expectError(error.UndefinedDieFaces, p.parse("1d"));
}
