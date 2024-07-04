# dicex.zig

A Dice Expression (DicEx) compiler.

## Install

```sh
zig fetch --save git+https://github.com/ubermanu/dicex.zig
```

```zig
const dicex_mod = b.dependency("dicex", .{});
exe.root_module.addImport("dicex", dicex_mod.module("dicex"));
```

## Usage

```zig
const Dicex = @import("dicex").Dicex;

test {
    const allocator = std.testing.allocator;
    var rand_impl = std.Random.DefaultPrng.init(0);

    const de = try Dicex.compile(allocator, "1d20 + 3");
    defer de.deinit();

    const score = de.roll(rand_impl.random());

    try std.testing.expect(4 <= score and score <= 23);
}
```
