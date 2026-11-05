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

// Importing the function to check if a
// character is a number or not.
const isNum = @import("utils.zig").isNum;

// Importing the function to check the length
// of a pointer to a null-terminated string
// slice.
const strLen = @import("utils.zig").strLen;

// Importing the structure to record the position
// of a character in a string.
const Position = @import("pos.zig").Position;

// Importing the function to create a new string
// slice.
const cloneSlice = @import("utils.zig").cloneSlice;

// Importing the function to output
// formatted strings.
const allocPrintSentinel = std.fmt.allocPrintSentinel;

/// An enumeration that "lists"
/// all possible types of tokens
/// that can exist in a JMU string.
pub const TokenType = enum(u8) {
    Comma,
    Assign,
    Integer,
    UserString,
    UserComment,
    OpenBracket,
    BooleanTrue,
    BooleanFalse,
    CloseBracket,
    SectionMarker,
    FloatingPoint,
};

/// A data structure to encapsulate
/// all important information about
/// a captured token.
pub const Token = struct {
    end: Position,
    start: Position,
    value: ?[*:0]const u8,
    token_type: TokenType,

    /// A function to drop
    /// all heap-allocated
    /// resources of this
    /// data structure if
    /// they exist.
    pub fn deinit(
        self: *Token,
        allocator: Allocator
    ) void {
        if (self.value) |val| {
            allocator.free(std.mem.span(val));
        }
    }
};

/// A data structure to
/// tokenize a string of
/// JMU source code and
/// save information about
/// any errors that may occur.
pub const Lexer = struct {
    allocator: Allocator,
    source: [*:0]const u8,
    err_type: ?JMUErr,
    err_pos: ?Position,

    /// A function to create a new
    /// instance of the data structure
    /// and return an instance of it.
    pub fn init(
        source: [*:0]const u8,
        allocator: Allocator
    ) Lexer {
        return Lexer{
            .source = source,
            .allocator = allocator,
            .err_type = null,
            .err_pos = null,
        };
    }

    /// A function to split a 
    /// string of JMU source
    /// code into a stream of
    /// tokens and return it.
    /// If an invalid character 
    /// is encountered or an
    /// allocation error happens,
    /// an error is saved in the
    /// `Lexer` structure and 
    /// the error is returned.
    pub fn tokenize(
        self: *Lexer
    ) !ArrayList(Token) {
        const len: u64 = strLen(self.source);
        if (len == 0){
            self.err_type = JMUErr.EmptyStr;
            return JMUErr.WriteErr;
        }
        else {
            var line: u64 = 0;
            var column: u64 = 0;
            var cursor: u64 = 0;
            var stream: ArrayList(Token) = .empty;
            errdefer {
                for (stream.items) |*item| {
                    @constCast(item).deinit(self.allocator);
                }
                stream.deinit(self.allocator);
            }
            while (cursor < len){
                if (self.source[cursor] == ','){
                    const token: Token = Token{
                        .end = Position{ 
                            .line = line, 
                            .column = (column + 1)
                        },
                        .start = Position{ 
                            .line = line, 
                            .column = column
                        },
                        .value = null,
                        .token_type = .Comma
                    };
                    stream.append(
                        self.allocator, 
                        token
                    ) catch {
                            self.err_type = JMUErr.WriteErr;
                            self.err_pos = Position{
                                .line = line, 
                                .column = column
                            };
                            return JMUErr.WriteErr;
                    };
                    cursor = cursor + 1;
                    column = column + 1;
                }
                else if (self.source[cursor] == '['){
                    const token: Token = Token{
                        .end = Position{ 
                            .line = line, 
                            .column = (column + 1)
                        },
                        .start = Position{ 
                            .line = line, 
                            .column = column
                        },
                        .value = null,
                        .token_type = .OpenBracket
                    };
                    stream.append(
                        self.allocator, 
                        token
                    ) catch {
                        self.err_type = JMUErr.WriteErr;
                        self.err_pos = Position{
                            .line = line, 
                            .column = column
                        };
                        return JMUErr.WriteErr;
                    };
                    cursor = cursor + 1;
                    column = column + 1;
                }
                else if (self.source[cursor] == ']'){
                    const token: Token = Token{
                        .end = Position{ 
                            .line = line, 
                            .column = (column + 1)
                        },
                        .start = Position{ 
                            .line = line, 
                            .column = column
                        },
                        .value = null,
                        .token_type = .CloseBracket
                    };
                    stream.append(
                        self.allocator, 
                        token
                    ) catch {
                        self.err_type = JMUErr.WriteErr;
                        self.err_pos = Position{
                            .line = line, 
                            .column = column
                        };
                        return JMUErr.WriteErr;
                    };
                    cursor = cursor + 1;
                    column = column + 1;
                }
                else if (self.source[cursor] == '|'){
                    const token: Token = Token{
                        .end = Position{ 
                            .line = line, 
                            .column = (column + 1)
                        },
                        .start = Position{ 
                            .line = line, 
                            .column = column
                        },
                        .value = null,
                        .token_type = .SectionMarker
                    };
                    stream.append(
                        self.allocator, 
                        token
                    ) catch {
                        self.err_type = JMUErr.WriteErr;
                        self.err_pos = Position{
                            .line = line, 
                            .column = column
                        };
                        return JMUErr.WriteErr;
                    };
                    cursor = cursor + 1;
                    column = column + 1;
                }
                else if (self.source[cursor] == '>' and
                    self.source[cursor + 1] == '~' and
                    self.source[cursor + 2] == '<')
                {
                    const token: Token = Token{
                        .end = Position{ 
                            .line = line, 
                            .column = (column + 2)
                        },
                        .start = Position{ 
                            .line = line, 
                            .column = column
                        },
                        .value = null,
                        .token_type = .Assign
                    };
                    stream.append(
                        self.allocator, 
                        token
                    ) catch {
                        self.err_type = JMUErr.WriteErr;
                        self.err_pos = Position{ 
                            .line = line, 
                            .column = column 
                        };
                        return JMUErr.WriteErr;
                    };
                    cursor = cursor + 3;
                    column = column + 3;
                }
                else if (self.source[cursor] == 't' and
                    self.source[cursor + 1] == 'r' and
                    self.source[cursor + 2] == 'u' and
                    self.source[cursor + 3] == 'e')
                {
                    const token: Token = Token{
                        .end = Position{ 
                            .line = line, 
                            .column = (column + 3)
                        },
                        .start = Position{ 
                            .line = line, 
                            .column = column
                        },
                        .value = null,
                        .token_type = .BooleanTrue
                    };
                    stream.append(
                        self.allocator, 
                        token
                    ) catch {
                        self.err_type = JMUErr.WriteErr;
                        self.err_pos = Position{ 
                            .line = line, 
                            .column = column 
                        };
                        return JMUErr.WriteErr;
                    };
                    cursor = cursor + 4;
                    column = column + 4;
                }
                else if (self.source[cursor] == 'f' and
                    self.source[cursor + 1] == 'a' and
                    self.source[cursor + 2] == 'l' and
                    self.source[cursor + 3] == 's' and
                    self.source[cursor + 4] == 'e')
                {
                    const token: Token = Token{
                        .end = Position{ 
                            .line = line, 
                            .column = (column + 4)
                        },
                        .start = Position{ 
                            .line = line, 
                            .column = column
                        },
                        .value = null,
                        .token_type = .BooleanFalse
                    };
                    stream.append(
                        self.allocator, 
                        token
                    ) catch {
                        self.err_type = JMUErr.WriteErr;
                        self.err_pos = Position{ 
                            .line = line, 
                            .column = column 
                        };
                        return JMUErr.WriteErr;
                    };
                    cursor = cursor + 5;
                    column = column + 5;
                }
                else if (self.source[cursor] == '"'){
                    const col_start: u64 = column;
                    cursor = cursor + 1;
                    var slice: ArrayList(u8) = .empty;
                    errdefer slice.deinit(self.allocator);
                    while (cursor < len and self.source[cursor] != '"'){
                        if (self.source[cursor] == '"'){
                            break;
                        }
                        else {
                            slice.append(
                                self.allocator,
                                self.source[cursor]
                            ) catch {
                                self.err_type = JMUErr.WriteErr;
                                self.err_pos = Position{ 
                                    .line = line, 
                                    .column = column 
                                };
                                return JMUErr.WriteErr;
                            };
                            cursor = cursor + 1;
                        }
                    }
                    cursor = cursor + 1;
                    column = column + 1;
                    const joined: [*:0]const u8 = slice
                        .toOwnedSliceSentinel(
                            self.allocator,
                            0
                        ) catch {
                            self.err_type = JMUErr.AllocErr;
                            self.err_pos = Position{ 
                                .line = line, 
                                .column = col_start 
                            };
                            return JMUErr.AllocErr;
                    };
                    const token: Token = Token{
                        .end = Position {
                            .line = line,
                            .column = column
                        },
                        .start = Position {
                            .line = line,
                            .column = col_start
                        },
                        .value = joined,
                        .token_type = .UserString
                    };
                    stream.append(
                        self.allocator, 
                        token
                    ) catch {
                        self.err_type = JMUErr.WriteErr;
                        self.err_pos = Position{ 
                            .line = line, 
                            .column = col_start 
                        };
                        return JMUErr.WriteErr;
                    };
                }
                else if (self.source[cursor] == '#'){
                    cursor = cursor + 1;
                    const col_start: u64 = column;
                    while (cursor < len){
                        if (self.source[cursor] == '\r' or
                            self.source[cursor] == '\n')
                        {
                            break;
                        } 
                        else {
                            cursor = cursor + 1;
                            column = column + 1;
                        }
                    }
                    const token: Token = Token{
                        .end = Position {
                            .line = line,
                            .column = column
                        },
                        .start = Position {
                            .line = line,
                            .column = col_start
                        },
                        .value = null,
                        .token_type = .UserComment
                    };
                    stream.append(
                        self.allocator, 
                        token
                    ) catch {
                        self.err_type = JMUErr.WriteErr;
                        self.err_pos = Position{ 
                            .line = line, 
                            .column = col_start 
                        };
                        return JMUErr.WriteErr;
                    };
                }  
                else if (self.source[cursor] == ' ' or
                    self.source[cursor] == '\t')
                {
                    column = column + 1;
                    cursor = cursor + 1;
                }
                else if (self.source[cursor] == '\r' and
                    self.source[cursor + 1] == '\n')
                {
                    column = 0;
                    line = line + 1;
                    cursor = cursor + 2;
                }
                else if (self.source[cursor] == '\n' or
                    self.source[cursor] == '\r')
                {
                    column = 0;
                    line = line + 1;
                    cursor = cursor + 1;
                }
                else if (isNum(self.source[cursor])){
                    const col_start: u64 = column;
                    var im_buf: ArrayList(u8) = .empty;
                    errdefer im_buf.deinit(self.allocator);
                    var num_buf: ArrayList([*:0]const u8) = .empty;
                    errdefer {
                        for (num_buf.items) |item| {
                            self.allocator.free(std.mem.span(item));
                        }
                        num_buf.deinit(self.allocator);
                    }
                    while (cursor < len){
                        if (!isNum(self.source[cursor])){
                            if (self.source[cursor] == '.'){
                                const joined: [*:0]const u8 = im_buf
                                    .toOwnedSliceSentinel(
                                        self.allocator,
                                        0
                                    ) catch {
                                        self.err_type = JMUErr.AllocErr;
                                        self.err_pos = Position{ 
                                            .line = line, 
                                            .column = col_start 
                                        };
                                        return JMUErr.AllocErr;
                                };
                                errdefer self.allocator.free(std.mem.span(joined));
                                num_buf.append(
                                    self.allocator,
                                    joined
                                ) catch {
                                    self.err_type = JMUErr.WriteErr;
                                    self.err_pos = Position{ 
                                        .line = line, 
                                        .column = col_start 
                                    };
                                    return JMUErr.WriteErr;
                                };
                                im_buf.clearRetainingCapacity();
                                cursor = cursor + 1;
                                column = column + 1;
                            }
                            else {
                                break;
                            }
                        }
                        else {
                            im_buf.append(
                                self.allocator,
                                self.source[cursor]
                            ) catch {
                                self.err_type = JMUErr.WriteErr;
                                self.err_pos = Position{ 
                                    .line = line, 
                                    .column = col_start 
                                };
                                return JMUErr.WriteErr;
                            };
                            cursor = cursor + 1;
                            column = column + 1;
                        }
                    }
                    const joined: [*:0]const u8 = im_buf
                        .toOwnedSliceSentinel(
                            self.allocator,
                            0
                        ) catch {
                            self.err_type = JMUErr.AllocErr;
                            self.err_pos = Position{ 
                                .line = line, 
                                .column = col_start 
                            };
                            return JMUErr.AllocErr;
                    };
                    errdefer self.allocator.free(std.mem.span(joined));
                    num_buf.append(
                        self.allocator,
                        joined
                    ) catch {
                        self.err_type = JMUErr.WriteErr;
                        self.err_pos = Position{ 
                            .line = line, 
                            .column = col_start 
                        };
                        return JMUErr.WriteErr;
                    };
                    im_buf.clearRetainingCapacity();
                    if (num_buf.items.len == 2){
                        const front: [*:0]const u8 = cloneSlice(num_buf.items[0], self.allocator)
                            catch {
                                self.err_type = JMUErr.AllocErr;
                                self.err_pos = Position{ 
                                    .line = line, 
                                    .column = col_start 
                                };
                                return JMUErr.AllocErr;
                        };
                        defer self.allocator.free(std.mem.span(front));
                        errdefer self.allocator.free(std.mem.span(front));
                        const back: [*:0]const u8 = cloneSlice(num_buf.items[1], self.allocator)
                            catch {
                                self.err_type = JMUErr.AllocErr;
                                self.err_pos = Position{ 
                                    .line = line, 
                                    .column = col_start 
                                };
                                return JMUErr.AllocErr;
                        };
                        defer self.allocator.free(std.mem.span(back));
                        errdefer self.allocator.free(std.mem.span(back));
                        defer {
                            for (num_buf.items) |item| {
                                self.allocator.free(std.mem.span(item));
                            }
                            num_buf.deinit(self.allocator);
                        }
                        const float_num: [*:0]const u8 = allocPrintSentinel(
                            self.allocator,
                            "{s}.{s}",
                            .{front, back},
                            0
                        ) catch {
                            self.err_type = JMUErr.AllocErr;
                            self.err_pos = Position{ 
                                .line = line, 
                                .column = col_start 
                            };
                            return JMUErr.AllocErr;
                        };
                        errdefer self.allocator.free(std.mem.span(float_num));
                        const token: Token = Token {
                            .end = Position {
                                .line = line,
                                .column = column
                            },
                            .start = Position {
                                .line = line,
                                .column = col_start
                            },
                            .value = float_num,
                            .token_type = .FloatingPoint
                        };
                        stream.append(
                            self.allocator, 
                            token
                        ) catch {
                            self.err_type = JMUErr.WriteErr;
                            self.err_pos = Position{ 
                                .line = line, 
                                .column = col_start 
                            };
                            return JMUErr.WriteErr;
                        };
                    }
                    else if (num_buf.items.len == 1){
                        const l_int: [*:0]const u8 = cloneSlice(num_buf.items[0], self.allocator)
                            catch {
                                self.err_type = JMUErr.AllocErr;
                                self.err_pos = Position{ 
                                    .line = line, 
                                    .column = col_start 
                                };
                                return JMUErr.AllocErr;
                        };
                        errdefer self.allocator.free(std.mem.span(l_int));
                        defer {
                            for (num_buf.items) |item| {
                                self.allocator.free(std.mem.span(item));
                            }
                            num_buf.deinit(self.allocator);
                        }
                        const token: Token = Token {
                            .end = Position {
                                .line = line,
                                .column = column
                            },
                            .start = Position {
                                .line = line,
                                .column = col_start
                            },
                            .value = l_int,
                            .token_type = .Integer
                        };
                        stream.append(
                            self.allocator, 
                            token
                        ) catch {
                            self.err_type = JMUErr.WriteErr;
                            self.err_pos = Position{ 
                                .line = line, 
                                .column = col_start 
                            };
                            return JMUErr.WriteErr;
                        };
                    }
                    else {
                        self.err_pos = Position {
                            .line = line,
                            .column = column
                        };
                        self.err_type = JMUErr.UnexpectedChar;
                        return JMUErr.UnexpectedChar;
                    }
                }
                else {
                    self.err_pos = Position {
                        .line = line,
                        .column = column
                    };
                    self.err_type = JMUErr.UnexpectedChar;
                    return JMUErr.UnexpectedChar;
                }
            }
            return stream;
         }
    }
};
