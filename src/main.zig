const std = @import("std");
const math = std.math;

const EncodeError = error{
    EmptyInput,
};

const base64 = struct {
    lookupTable: [64]u8,

    pub fn init() base64 {
        const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        const lower = "abcdefghijklmnopqrstuvwxyz";
        const symbols = "0123456789+/";

        return base64{ .lookupTable = upper ++ lower ++ symbols };
    }

    pub fn charAt(self: base64, i: u8) u8 {
        return self.lookupTable[i];
    }

    pub fn encode(_: base64, text: []u8) EncodeError![]u8 {
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

        _ = encoded;
        // Todo:
        // Test out with an outbuffer of 4 with input ex:'Lil'
        // go through 3 bytes at a time
        // output byte 1: in_byte[0] & b11111100
        // output byte 2: in_byte[0] & 00000011 << 6 + in_byte[1] >> 2
        // output byte 3: in_byte[1] & 00000011 << 6 + in_byte[2] >> 2
        // output byte 4: in_byte[2] & 00000011 << 6 + in_byte[3] >> 2
    }
};

pub fn main() !void {}
