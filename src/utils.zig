// JMU.ZIG by Alyx Shang.
// Licensed under the FSL v1.

// Importing the "std" namespace.
const std = @import("std");

// Importing the "ArrayList" structure
// from the standard library.
const ArrayList = std.ArrayList;

// Importing the "Allocator" structure
// from the standard library.
const Allocator = std.mem.Allocator;

// Importing the structure to catch and
// handle errors.
const JMUErr = @import("err.zig").JMUErr;

/// A function to get the 
/// length of a string that
/// is a pointer to a 
/// null-terminated
/// slice.
pub fn strLen(
    sub: [*:0]const u8
) u64 {
    var result: u64 = 0;
    while (sub[result] != 0){
        result = result + 1;
    }
    return result;
}

/// A function to check if
/// a character is numeric
/// or not. A boolean is
/// returned to reflect
/// this.
pub fn isNum(
    sub: u8
) bool {
    var cursor: u64 = 0;
    var result: bool = false;
    const alpha: [*:0]const u8 = "1234567890";
    while (cursor < 10){
        if (alpha[cursor] == sub){
            result = true;
        }
        cursor = cursor + 1;
    }
    return result;
}

/// A function to clone
/// a pointer to a null-terminated
/// string slice. If allocation fails,
/// an error is returned. If not, the
/// pointer to the slice is returned.
pub fn cloneSlice(
    sub: [*:0]const u8,
    allocator: Allocator
) ![*:0]const u8 {
    var cursor: u64 = 0;
    var chars: ArrayList(u8) = .empty;
    errdefer chars.deinit(allocator);
    while (sub[cursor] != 0){
        chars.append(
            allocator,
            sub[cursor]
        ) catch return JMUErr.WriteErr;
        cursor = cursor + 1;
    }
    const joined: [*:0]const u8 = chars.toOwnedSliceSentinel(
        allocator,
        0
    ) catch return JMUErr.AllocErr;
    errdefer allocator.free(std.mem.span(joined));
    return joined;
}
