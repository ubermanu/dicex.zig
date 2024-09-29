const std = @import("std");

/// A rollable die.
pub const Die = struct {
    faces: usize,

    pub fn roll(self: Die, rand: std.Random) usize {
        return (rand.int(usize) % self.faces) + 1;
    }
};

/// A handful of dice.
pub const Dice = struct {
    count: isize,
    die: Die,

    pub fn roll(self: Dice, rand: std.Random) isize {
        var score: isize = 0;
        const count: usize = @intCast(@abs(self.count));

        for (0..count) |_| {
            score += @intCast(self.die.roll(rand));
        }

        return score;
    }
};

const ParseError = error{
    UndefinedDieFaces,
    UnexpectedCharacter,
};

allocator: std.mem.Allocator,
buffer: []const u8,
dices: std.ArrayList(Dice),
modifiers: std.ArrayList(isize),
pos: usize = 0,

const Parser = @This();

pub fn init(allocator: std.mem.Allocator) Parser {
    return .{
        .allocator = allocator,
        .buffer = undefined,
        .dices = std.ArrayList(Dice).init(allocator),
        .modifiers = std.ArrayList(isize).init(allocator),
    };
}

pub fn deinit(self: *Parser) void {
    self.dices.deinit();
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

        if (try self.parseNumber(isize)) |n| {
            if (try self.parseDie()) |die| {
                try self.dices.append(.{ .count = sign * n, .die = die });
            } else {
                try self.modifiers.append(sign * n);
            }
            continue;
        }

        if (try self.parseDie()) |die| {
            try self.dices.append(.{ .count = sign, .die = die });
            continue;
        }

        return error.UnexpectedCharacter;
    }
}

fn parseNumber(self: *Parser, T: type) !?T {
    const start = self.pos;

    while (self.pos < self.buffer.len and std.ascii.isDigit(self.buffer[self.pos])) : (self.pos += 1) {}

    if (start == self.pos) {
        return null;
    }

    const end = self.pos;
    self.skipWhitespace(0);

    return try std.fmt.parseInt(T, self.buffer[start..end], 10);
}

fn parseDie(self: *Parser) !?Die {
    if (self.matchChar('d')) {
        if (try self.parseNumber(usize)) |faces| {
            return .{ .faces = faces };
        } else {
            return error.UndefinedDieFaces;
        }
    } else {
        return null;
    }
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

test "die without count" {
    const allocator = std.testing.allocator;

    var p = Parser.init(allocator);
    defer p.deinit();

    try p.parse("d20");

    try std.testing.expectEqual(1, p.dices.items.len);
    try std.testing.expectEqual(0, p.modifiers.items.len);

    try std.testing.expectEqual(1, p.dices.items[0].count);
    try std.testing.expectEqual(20, p.dices.items[0].die.faces);
}

test "simple die" {
    const allocator = std.testing.allocator;

    var p = Parser.init(allocator);
    defer p.deinit();

    try p.parse("1d6");

    try std.testing.expectEqual(1, p.dices.items.len);
    try std.testing.expectEqual(0, p.modifiers.items.len);
}

test "die with mod" {
    const allocator = std.testing.allocator;

    var p = Parser.init(allocator);
    defer p.deinit();

    try p.parse("1d6 + 5");

    try std.testing.expectEqual(1, p.dices.items.len);
    try std.testing.expectEqual(1, p.modifiers.items.len);
}

test "multiple mods" {
    const allocator = std.testing.allocator;

    var p = Parser.init(allocator);
    defer p.deinit();

    try p.parse("1 + 2 + 3 - 4");

    try std.testing.expectEqual(0, p.dices.items.len);
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

test "negative dice" {
    const allocator = std.testing.allocator;

    var p = Parser.init(allocator);
    defer p.deinit();

    try p.parse("-4d3");

    try std.testing.expectEqual(1, p.dices.items.len);
    try std.testing.expectEqual(0, p.modifiers.items.len);

    try std.testing.expectEqual(-4, p.dices.items[0].count);
    try std.testing.expectEqual(3, p.dices.items[0].die.faces);
}

test "negative dice without number" {
    const allocator = std.testing.allocator;

    var p = Parser.init(allocator);
    defer p.deinit();

    try p.parse("-d3");

    try std.testing.expectEqual(1, p.dices.items.len);
    try std.testing.expectEqual(0, p.modifiers.items.len);

    try std.testing.expectEqual(-1, p.dices.items[0].count);
    try std.testing.expectEqual(3, p.dices.items[0].die.faces);
}
