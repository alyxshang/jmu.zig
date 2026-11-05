// JMU.ZIG by Alyx Shang.
// Licensed under the FSL v1.

// Exporting the module containing
// the structure to catch and handle
// errors.
pub const err = @import("err.zig");

// Exporting the module containing
// a structure to record the position
// of characters in a string.
pub const pos = @import("pos.zig");

// Exporting the module containing the
// main deserialization function.
pub const from = @import("from.zig");

// Exporting the module containing
// JMU.ZIG's tokenizer.
pub const lexer = @import("lexer.zig");

// Exporting the module containing
// some utility functions.
pub const utils = @import("utils.zig");

// Exporting the module containing
// JMU.ZIG's parser.
pub const parser = @import("parser.zig");

// Exporting the module containing
// JMU.ZIG's deserializer.
pub const deserializer = @import("deserializer.zig");
