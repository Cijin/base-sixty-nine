const std = @import("std");
const print = std.debug.print;
const mem = std.mem;
const math = std.math;
const heap = std.heap;
const assert = std.debug.assert;

const EncodeError = error{
    EmptyInput,
    NotBase64,
};

const base64 = struct {
    lookupTable: [64:0]u8,

    pub fn init() base64 {
        const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        const lower = "abcdefghijklmnopqrstuvwxyz";
        const symbols = "0123456789+/";

        return base64{ .lookupTable = upper.* ++ lower.* ++ symbols.* };
    }

    pub fn charAt(self: base64, i: u8) u8 {
        assert(i < 64);
        return self.lookupTable[i];
    }

    pub fn encode(self: base64, allocator: mem.Allocator, text: []const u8) ![]u8 {
        if (text.len == 0) {
            return EncodeError.EmptyInput;
        }

        var encodedTextLen: usize = 0;
        if (text.len < 3) {
            encodedTextLen = 4;
        } else {
            encodedTextLen = try math.divCeil(usize, text.len, 3);
            encodedTextLen = encodedTextLen * 4;
        }

        const encoded = try allocator.alloc(u8, encodedTextLen);
        var encodedIdx: usize = 0;
        var buf = [3]u8{ 0, 0, 0 };
        var bufIdx: u8 = 0;

        for (text) |c| {
            buf[bufIdx] = c;
            bufIdx += 1;

            if (bufIdx == 3) {
                encoded[encodedIdx] = self.charAt(buf[0] >> 2);
                encoded[encodedIdx + 1] = self.charAt(((buf[0] & 0x03) << 4) + buf[1] >> 4);
                encoded[encodedIdx + 2] = self.charAt(((buf[1] & 0x0f) << 2) + buf[2] >> 6);
                encoded[encodedIdx + 3] = self.charAt((buf[2] & 0x3f));

                encodedIdx += 4;
                bufIdx = 0;
            }
        }

        if (bufIdx == 2) {
            encoded[encodedIdx] = self.charAt(buf[0] >> 2);
            encoded[encodedIdx + 1] = self.charAt(((buf[0] & 0x03) << 4) | buf[1] >> 4);
            encoded[encodedIdx + 2] = self.charAt((buf[1] & 0x0f) << 2);
            encoded[encodedIdx + 3] = '=';

            encodedIdx += 4;
            bufIdx = 0;
        }

        if (bufIdx == 1) {
            encoded[encodedIdx] = self.charAt(buf[0] >> 2);
            encoded[encodedIdx + 1] = self.charAt((buf[0] & 0x03) << 4);
            encoded[encodedIdx + 2] = '=';
            encoded[encodedIdx + 3] = '=';

            encodedIdx += 4;
            bufIdx = 0;
        }

        assert(encodedIdx == encodedTextLen);

        return encoded;
    }
};

pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{ .thread_safe = true }){};
    const allocator = gpa.allocator();
    defer if (gpa.deinit() == .leak) {
        print("Memory leak", .{});
    };

    const base64Encoder = base64.init();
    const input = "Man";
    const encoded = base64Encoder.encode(allocator, input) catch |err| {
        print("There was an error while encoding:{any}\n", .{err});
        return;
    };
    defer allocator.free(encoded);

    print("The base64 encoded string of '{s}' is '{s}'\n", .{ input, encoded });
}
