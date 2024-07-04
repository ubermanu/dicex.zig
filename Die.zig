const std = @import("std");

faces: usize,

const Die = @This();

pub fn roll(self: Die, rand: std.Random) usize {
    return (rand.int(usize) % self.faces) + 1;
}
