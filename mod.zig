pub const Dicex = @import("Dicex.zig");
pub const Die = @import("Die.zig");

pub const Dice = @import("Parser.zig").Dice;
pub const Modifier = @import("Parser.zig").Modifier;

pub const d2 = Die{ .faces = 2 };
pub const d4 = Die{ .faces = 4 };
pub const d6 = Die{ .faces = 6 };
pub const d8 = Die{ .faces = 8 };
pub const d10 = Die{ .faces = 10 };
pub const d12 = Die{ .faces = 12 };
pub const d20 = Die{ .faces = 20 };
pub const d100 = Die{ .faces = 100 };
