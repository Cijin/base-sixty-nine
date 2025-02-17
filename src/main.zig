const std = @import("std");
const math = std.math;

const EncodeError = error{
    EmptyInput,
    NotBase64,
};

const base64 = struct {
    lookupTable: [64]u8,

    pub fn init() base64 {
        const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        const lower = "abcdefghijklmnopqrstuvwxyz";
        const symbols = "0123456789+/";

        return base64{ .lookupTable = upper ++ lower ++ symbols };
    }

    pub fn charAt(self: base64, i: u8) EncodeError!u8 {
        if (i >= 64) {
            return EncodeError.NotBase64;
        }
        return self.lookupTable[i];
    }

    pub fn encode(self: base64, text: []u8) EncodeError![]u8 {
        if (text.len == 0) {
            return EncodeError.EmptyInput;
        }

        var encodedTextLen: usize = 0;
        if (text.len < 3) {
            encodedTextLen = 4;
        } else {
            encodedTextLen = try math.divCeil(usize, text.len, 3);
            encodedTextLen * 4;
        }
        const encoded: [encodedTextLen]u8 = undefined;

        var isStart: bool = true;
        for (text, 0..encodedTextLen) |c, i| {
            if (i % 4 == 0) {
                if (isStart) {
                    encoded[i] = try self.charAt(c >> 2);
                    encoded[i + 1] = c << 4;
                    isStart = false;
                } else {
                    // Todo:
                    // what to do on the last one?
                    // When to insert '='?
                    isStart = true;
                }
                continue;
            }

            encoded[i] = try self.charAt(encoded[i - 1] | c >> 4);
            encoded[i + 1] = c << 4;
        }
    }
};

pub fn main() !void {}
