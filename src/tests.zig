// JMU.ZIG by Alyx Shang.
// Licensed under the FSL v1.

// Importing the standard
// library namespace.
const std = @import("std");

// Importing the module combining
// all other parts of the pipeline.
const from = @import("from.zig");

// Importing the module containing
// utility functions.
const utils = @import("utils.zig");

// Importing the module containing
// the  tokenizer for JMU.
const lexer = @import("lexer.zig");

// Importing the module containing
// the parser for JMU.
const parser = @import("parser.zig");

// Importing the module containing the deserializer
// for JMU.
const deserializer = @import("deserializer.zig");

/// A structure to encapsulate
/// data about a command. This
/// structure is used for 
/// testing purposes.
const Command = struct {
    name: [*:0]const u8,
    command: [*:0]const u8,

    /// A function to drop all heap-allocated
    /// resources this structure uses.
    pub fn deinit(
        self: *const Command,
        allocator: std.mem.Allocator
    ) void {
        allocator.free(std.mem.span(self.name));
        allocator.free(std.mem.span(self.command));
    }
};

/// A test sub-structure.
const TestSubStruct = struct {
    fav_characters: i64,
    is_goth: bool,
};

/// A test structure to 
/// deserialize data into.
const TestStruct = struct {
    name: [*:0]const u8,
    age: i64,
    gpa: f64,
    is_political: bool,
    likes_cake: bool,
    imp_nums: std.ArrayList(i64),
    float_nums: std.ArrayList(f64),
    hobbies: std.ArrayList([*:0]const u8),
    truth_table: std.ArrayList(bool),
    sub_info: TestSubStruct,
    misc_list: std.ArrayList(Command),

    /// A function to drop all heap-allocated
    /// resources this structure uses.
    pub fn deinit(
        self: *TestStruct,
        allocator: std.mem.Allocator
    ) void {
        allocator.free(std.mem.span(self.name));
        self.imp_nums.deinit(std.testing.allocator);
        self.float_nums.deinit(std.testing.allocator);
        self.truth_table.deinit(std.testing.allocator);
        for (self.hobbies.items) |hobby|{
            allocator.free(std.mem.span(hobby));
        }
        self.hobbies.deinit(std.testing.allocator);
        for (self.misc_list.items) |item| {
            item.deinit(allocator);
        }
        self.misc_list.deinit(std.testing.allocator);
    }
};

// Testing the module containing utility 
// functions.
test "Testing the module containing utility functions." {
    const test_str: [*:0]const u8 = "hello";
    const is_num_t: u8 = '4';
    const is_num_f: u8 = 'a';
    try std.testing.expect(utils.strLen(test_str) == 5);
    try std.testing.expect(utils.isNum(is_num_t) == true);
    try std.testing.expect(utils.isNum(is_num_f) == false);
}

// Testing the module containing the 
// tokenizer for JMU.
test "Testing the module containing the tokenizer for JMU." {
    const test_str: [*:0]const u8 = 
        \\,45>~<"hello"# hello world
        \\[truefalse]|56.7
    ;
    var ml: lexer.Lexer = lexer.Lexer.init(
        test_str,
        std.testing.allocator
    );
    var lexed: std.ArrayList(lexer.Token) = 
        try ml.tokenize(); 
    defer {
        for (lexed.items) |*item| {
            item.deinit(std.testing.allocator);
        }
        lexed.deinit(std.testing.allocator);
    }
    try std.testing.expect(lexed.items.len == 11);
}

// Testing the module containing JMU's parser.
test "Testing the module containing JMU's parser." {
    const test_str: [*:0]const u8 = 
        \\"name" >~< "Alyx"
        \\"age" >~< 2026
        \\"gpa" >~< 1.0
        \\"is_political" >~< false
        \\"likes_cake" >~< true
        \\"imp_nums" >~< [45, 46, 47]
        \\"float_nums" >~< [34.5, 12.3, 67.8]
        \\"hobbies" >~< ["art", "code", "reading"]
        \\"truth_table" >~< [true, false, true, true]
        \\"specials" >~< |
        \\  "likes_sharkey" >~< true
        \\  "fav_characters" >~< ["Zibai", "Raiden Shogun"]
        \\|
        \\"misc_list" >~< [
        \\  |
        \\      "fav_characters" >~< ["zibai", "raiden shogun"]
        \\      "Adventure Rank" >~< 59
        \\  |,
        \\  |
        \\      "fav_languages" >~< ["zig", "rust"]
        \\      "programming_since" >~< 2012
        \\  |
        \\]
    ;
    var ml: lexer.Lexer = lexer.Lexer.init(
        test_str,
        std.testing.allocator
    );
    var lexed: std.ArrayList(lexer.Token) = 
        try ml.tokenize(); 
    defer {
        for (lexed.items) |*item| {
            item.deinit(std.testing.allocator);
        }
        lexed.deinit(std.testing.allocator);
    }
    var mp: parser.Parser = parser.Parser.init(
        &lexed,
        std.testing.allocator
    );
    var stmts: std.ArrayList(parser.Assignment) = try mp.parse();
    defer {
        for (stmts.items) |*item| {
            item.deinit(std.testing.allocator);
        }
        stmts.deinit(std.testing.allocator);
    }
    try std.testing.expect(stmts.items.len == 11);
}

// Testing the module containing the
// deserializer for JMU.
test "Testing the module containing the deserializer for JMU." { 
    const test_str: [*:0]const u8 = 
        \\"name" >~< "Alyx"
        \\"age" >~< 2026
        \\"gpa" >~< 1.0
        \\"is_political" >~< false
        \\"likes_cake" >~< true
        \\"imp_nums" >~< [45, 46, 47]
        \\"float_nums" >~< [34.5, 12.3, 67.8]
        \\"hobbies" >~< ["art", "code", "reading"]
        \\"truth_table" >~< [true, false, true, true]
        \\"sub_info" >~< |
        \\  "fav_characters" >~< 3
        \\  "is_goth" >~< true
        \\|
        \\"misc_list" >~< [
        \\  |
        \\      "name" >~< "build"
        \\      "command" >~< "echo"
        \\  |,
        \\  |
        \\      "name" >~< "clean"
        \\      "command" >~< "echo"
        \\  |
        \\]
    ;
    var ml: lexer.Lexer = lexer.Lexer.init(
        test_str,
        std.testing.allocator
    );
    var lexed: std.ArrayList(lexer.Token) = ml.tokenize() catch {
        std.debug.print("Position: {any}\n", .{ml.err_pos});
        return;
    };
    defer {
        for (lexed.items) |*item| {
            item.deinit(std.testing.allocator);
        }
        lexed.deinit(std.testing.allocator);
    }
    var mp: parser.Parser = parser.Parser.init(
        &lexed,
        std.testing.allocator
    );
    var stmts: std.ArrayList(parser.Assignment) = try mp.parse();
    defer {
        for (stmts.items) |*item| {
            item.deinit(std.testing.allocator);
        }
        stmts.deinit(std.testing.allocator);
    }
    var my_struct: TestStruct = undefined;
    var des = deserializer.Deserializer(TestStruct).init(
        &stmts, 
        std.testing.allocator, 
        &my_struct
    );
    try des.deserialize();
    defer my_struct.deinit(std.testing.allocator);
    try std.testing.expect(std.mem.eql(u8, std.mem.span(my_struct.name), "Alyx"));
    try std.testing.expect(my_struct.age == 2026);
    try std.testing.expect(my_struct.gpa == 1.0);
    try std.testing.expect(my_struct.is_political == false);
    try std.testing.expect(my_struct.likes_cake == true);
    try std.testing.expect(my_struct.imp_nums.items.len == 3);
    try std.testing.expect(my_struct.float_nums.items.len == 3);
    try std.testing.expect(my_struct.hobbies.items.len == 3);
    try std.testing.expect(my_struct.truth_table.items.len == 4);
    try std.testing.expect(my_struct.sub_info.fav_characters == 3);
    try std.testing.expect(my_struct.sub_info.is_goth == true);
    try std.testing.expect(my_struct.misc_list.items.len == 2);
}

// Testing the module containing the "fromStr" function.
test "Testing the module containing the \"fromStr\" function." {
    const test_str: [*:0]const u8 = 
        \\"name" >~< "Alyx"
        \\"age" >~< 2026
        \\"gpa" >~< 1.0
        \\"is_political" >~< false
        \\"likes_cake" >~< true
        \\"imp_nums" >~< [45, 46, 47]
        \\"float_nums" >~< [34.5, 12.3, 67.8]
        \\"hobbies" >~< ["art", "code", "reading"]
        \\"truth_table" >~< [true, false, true, true]
        \\"sub_info" >~< |
        \\  "fav_characters" >~< 3
        \\  "is_goth" >~< true
        \\|
        \\"misc_list" >~< [
        \\  |
        \\      "name" >~< "build"
        \\      "command" >~< "echo"
        \\  |,
        \\  |
        \\      "name" >~< "clean"
        \\      "command" >~< "echo"
        \\  |
        \\]
    ;
    var ms: TestStruct = try from.fromStr(
        TestStruct,
        std.testing.allocator,
        test_str
    );
    defer ms.deinit(std.testing.allocator);
    try std.testing.expect(ms.age == 2026);
    try std.testing.expect(ms.gpa == 1.0);
    try std.testing.expect(ms.is_political == false);
    try std.testing.expect(ms.likes_cake == true);
    try std.testing.expect(ms.imp_nums.items.len == 3);
    try std.testing.expect(ms.float_nums.items.len == 3);
    try std.testing.expect(ms.hobbies.items.len == 3);
    try std.testing.expect(ms.truth_table.items.len == 4);
    try std.testing.expect(ms.sub_info.fav_characters == 3);
    try std.testing.expect(ms.sub_info.is_goth == true);
    try std.testing.expect(ms.misc_list.items.len == 2);    
}
