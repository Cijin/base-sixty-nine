const std = @import("std");
const print = std.debug.print;
const mem = std.mem;
const math = std.math;
const heap = std.heap;
const testing = std.testing;
const assert = std.debug.assert;

const EncodeError = error{
    EmptyInput,
    NotBase64,
};

const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
const lower = "abcdefghijklmnopqrstuvwxyz";
const symbols = "0123456789+/";
const lookupTable = upper ++ lower ++ symbols;

fn charAt(i: u8) u8 {
    assert(i < 64);
    return lookupTable[i];
}

fn index(char: u8) !u8 {
    if (char == '=') {
        return 64;
    }

    for (lookupTable, 0..) |c, i| {
        if (c == char) {
            return @intCast(i);
        }
    }

    return EncodeError.NotBase64;
}

fn encode(allocator: mem.Allocator, text: []const u8) ![]u8 {
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
            encoded[encodedIdx] = charAt(buf[0] >> 2);
            encoded[encodedIdx + 1] = charAt(((buf[0] & 0x03) << 4) | buf[1] >> 4);
            encoded[encodedIdx + 2] = charAt(((buf[1] & 0x0f) << 2) | buf[2] >> 6);
            encoded[encodedIdx + 3] = charAt((buf[2] & 0x3f));

            encodedIdx += 4;
            bufIdx = 0;
        }
    }

    if (bufIdx == 2) {
        encoded[encodedIdx] = charAt(buf[0] >> 2);
        encoded[encodedIdx + 1] = charAt(((buf[0] & 0x03) << 4) | buf[1] >> 4);
        encoded[encodedIdx + 2] = charAt((buf[1] & 0x0f) << 2);
        encoded[encodedIdx + 3] = '=';

        encodedIdx += 4;
        bufIdx = 0;
    }

    if (bufIdx == 1) {
        encoded[encodedIdx] = charAt(buf[0] >> 2);
        encoded[encodedIdx + 1] = charAt((buf[0] & 0x03) << 4);
        encoded[encodedIdx + 2] = '=';
        encoded[encodedIdx + 3] = '=';

        encodedIdx += 4;
        bufIdx = 0;
    }

    assert(encodedIdx == encodedTextLen);
    return encoded;
}

fn decode(allocator: mem.Allocator, encoded: []const u8) ![]u8 {
    assert(encoded.len > 0);

    var decodedTextLen: usize = 0;
    if (encoded.len <= 4) {
        decodedTextLen = 3;
    } else {
        decodedTextLen = try math.divFloor(usize, encoded.len - 1, 4);
        decodedTextLen = decodedTextLen * 3;
    }

    const decoded = try allocator.alloc(u8, decodedTextLen);
    var decodedIdx: usize = 0;
    var buf = [4]u8{ 0, 0, 0, 0 };
    var bufIdx: u8 = 0;

    for (encoded) |c| {
        buf[bufIdx] = try index(c);
        bufIdx += 1;

        if (bufIdx == 4) {
            decoded[decodedIdx] = (buf[0] << 2) | (buf[1] >> 4 & 0x03);
            if (buf[2] != 64) {
                decoded[decodedIdx + 1] = buf[1] << 4 | (buf[2] >> 2 & 0x0f);
            }
            if (buf[3] != 64) {
                decoded[decodedIdx + 2] = buf[2] << 6 | (buf[3] & 0x3f);
            }

            decodedIdx += 3;
            bufIdx = 0;
        }
    }

    assert(decodedIdx == decodedTextLen);
    return decoded;
}

pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{ .thread_safe = true }){};
    const allocator = gpa.allocator();
    defer if (gpa.deinit() == .leak) {
        print("Memory leak", .{});
    };

    const input = "Man";
    const encoded = encode(allocator, input) catch |err| {
        print("There was an error while encoding:{any}\n", .{err});
        return;
    };
    defer allocator.free(encoded);

    const decoded = decode(allocator, encoded) catch |err| {
        print("There was an error while decoding:{any}\n", .{err});
        return;
    };
    defer allocator.free(decoded);

    assert(mem.eql(u8, input, decoded));
}
