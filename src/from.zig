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

// Importing the structure encapsulating
// data about a token.
const Token = @import("lexer.zig").Token;

// Importing the structure to tokenize a
// string of JMU source code.
const Lexer = @import("lexer.zig").Lexer;

// Importing the structure to tokenize a
// string of JMU source code.
const Parser = @import("parser.zig").Parser;

// Importing the enumeration union representing all
// possible types of assignments in JMU source code.
const Assignment = @import("parser.zig").Assignment;

// Importing the type function to deserialize a list of
// assignments into the supplied structure.
const Deserializer = @import("deserializer.zig").Deserializer;

/// A function to deserialize a 
/// JMU string into the supplied
/// data structure. If the operation fails, 
/// an error is returned. The consumer MUST
/// free the structure.
pub fn fromStr(
    comptime T: type,
    allocator: Allocator,
    jmu_str: [*:0]const u8, 
) !T {
    var lexer: Lexer = Lexer.init(
        jmu_str,
        allocator
    );
    var lexed: ArrayList(Token) = try lexer.tokenize(); 
    defer {
        for (lexed.items) |*item| {
            item.deinit(allocator);
        }
        lexed.deinit(allocator);
    }
    var parser: Parser = Parser.init(
        &lexed,
        allocator
    );
    var stmts: ArrayList(Assignment) = try parser.parse(); 
    defer {
        for (stmts.items) |*item| {
            item.deinit(allocator);
        }
        stmts.deinit(allocator);
    }
    var result: T = undefined;
    var des = Deserializer(T).init(
        &stmts, 
        allocator, 
        &result
    );
    try des.deserialize();
    return result;
}
