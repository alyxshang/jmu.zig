// JMU.ZIG by Alyx Shang.
// Licensed under the FSL v1.

// Importing the "std" namespace.
const std = @import("std");

// Importing the "ArrayList" structure
// from the standard library.
const ArrayList = std.ArrayList;

// Importing the function to 
// parse an integer from a string.
const parseInt = std.fmt.parseInt;

// Importing the "Allocator" structure
// from the standard library.
const Allocator = std.mem.Allocator;

// Importing the function to 
// parse a float from a string.
const parseFloat = std.fmt.parseFloat;

// Importing the structure to catch and
// handle errors.
const JMUErr = @import("err.zig").JMUErr;

// Importing the structure encapsulating
// data about a token.
const Token = @import("lexer.zig").Token;

// Importing the data structure that saves
// information about the position of a token.
const Position = @import("pos.zig").Position;

// Importing the enumeration that lists
// all possible JMU tokens.
const TokenType = @import("lexer.zig").TokenType;

// Importing the function to clone a pointer
// to a null-terminated slice.
const cloneSlice = @import("utils.zig").cloneSlice;

/// An error entity to 
/// catch all possible errors
/// that could occur in lexing
/// and parsing.
pub const ParserErr = JMUErr 
    || std.fmt.ParseIntError 
    || std.fmt.ParseFloatError 
    || Allocator.Error;

/// A union of enumerations to
/// "list" all possible types of
/// assignments in JMU source code.
pub const Assignment = union(enum){
    Comment,
    BoolAssign: struct {
        key: [*:0]const u8, 
        value: bool
    },
    StringAssign: struct {
        key: [*:0]const u8, 
        value: [*:0]const u8
    },
    FloatingAssign: struct {
        key: [*:0]const u8, 
        value: f64
    },
    IntegerAssign: struct {
        key: [*:0]const u8, 
        value: i64
    },
    BoolListAssign: struct {
        key: [*:0]const u8, 
        value: ArrayList(bool)
    },
    FloatingListAssign: struct {
        key: [*:0]const u8, 
        value: ArrayList(f64)
    },
    IntegerListAssign: struct {
        key: [*:0]const u8, 
        value: ArrayList(i64)
    },
    StringListAssign: struct {
        key: [*:0]const u8, 
        value: ArrayList([*:0]const u8)
    },
    NestedAssign: struct {
        key: [*:0]const u8, 
        value: ArrayList(Assignment)
    },
    AssignmentBlockList: struct {
        key: [*:0]const u8, 
        value: ArrayList(ArrayList(Assignment))
    },

    /// A function to drop all
    /// heap-allocated resources
    /// an assignment may take up.
    pub fn deinit(
        self: *Assignment,
        allocator: Allocator
    ) void {
        switch (self.*){
            .BoolAssign => |b| {
                allocator.free(std.mem.span(b.key));
            },
            .StringAssign => |s| {
                allocator.free(std.mem.span(s.key));
                allocator.free(std.mem.span(s.value));
            },
            .IntegerAssign => |i| {
                allocator.free(std.mem.span(i.key));
            },
            .FloatingAssign => |f| {
                allocator.free(std.mem.span(f.key));
            },
            .IntegerListAssign => |*il| {
                allocator.free(std.mem.span(il.key));
                il.value.deinit(allocator);
            },
            .BoolListAssign => |*bl| {
                allocator.free(std.mem.span(bl.key));
                bl.value.deinit(allocator);
            },
            .FloatingListAssign => |*fl| {
                allocator.free(std.mem.span(fl.key));
                fl.value.deinit(allocator);
            },
            .StringListAssign => |*sl| {
                allocator.free(std.mem.span(sl.key));
                for (sl.value.items) |*item| {
                    allocator.free(std.mem.span(item.*));
                }
                sl.value.deinit(allocator);
            },
            .NestedAssign => |*na| {
                allocator.free(std.mem.span(na.key));
                for (na.value.items) |*item| {
                    item.deinit(allocator);
                }
                na.value.deinit(allocator);
            },
            .AssignmentBlockList => |*abl| {
                allocator.free(std.mem.span(abl.key));
                for (abl.value.items) |*outer| {
                    for (outer.items) |*inner| {
                        inner.deinit(allocator);
                    }
                    outer.deinit(allocator);
                }
                abl.value.deinit(allocator);
            },
            else => {}
        }
    }
};

/// A structure containing
/// the recursive descent parser
/// for JMU source code.
pub const Parser = struct {
    cursor: u64,
    err_type: ?JMUErr,
    err_pos: ?Position, 
    allocator: Allocator,
    stream: *const ArrayList(Token),

    /// A function to create a new instance
    /// of the `Parser` structure and fill
    /// the optional error fields to record
    /// any errors that happen during parsing.
    pub fn init(
        sub: *const ArrayList(Token),
        allocator: Allocator
    ) Parser {
        return Parser {
            .cursor = 0,
            .stream = sub,
            .err_pos = null,
            .err_type = null,
            .allocator = allocator
        };
    }

    /// A function to check if the
    /// internal cursor has reached
    /// the end of the stream of tokens.
    pub fn isDone(
        self: *Parser
    ) bool {
        return self.stream.items.len == self.cursor;
    }

    /// Advances the internal cursor, to loop
    /// through the token stream, by one.
    pub fn advance(
        self: *Parser
    ) void {
        self.cursor = self.cursor + 1;
    }

    /// Peeks at the token at position `n`
    /// and returns it. If the index is
    /// larger than the length of the
    /// internal stream of tokens, an
    /// error is returned.
    pub fn peekN(
        self: *Parser,
        n: u64
    ) ParserErr!Token {
        const new_idx: u64  = self.cursor + n;
        if (new_idx < self.stream.items.len){
            return self.stream.items[new_idx];
        }
        else {
            return JMUErr.UnexpectedStreamEnd;
        }
    }

    /// Looks at the token at the current
    /// position. If the token is of the
    /// expected type, it is returned. 
    /// If it isn't, an error is returned.
    /// If the index is larger than the 
    /// length of the internal stream 
    /// of tokens, an error is returned.
    pub fn expect(
        self: *Parser,
        token_type: TokenType
    ) ParserErr!Token {
        if (self.isDone()){
            self.err_pos = self.stream.items[self.cursor].start;
            self.err_type = JMUErr.UnexpectedStreamEnd;
            return JMUErr.UnexpectedStreamEnd;
        }
        else {
            const curr: Token = self.stream.items[self.cursor];
            if (curr.token_type == token_type){
                self.advance();
                return curr;
            }
            else {
                self.err_pos = self.stream.items[self.cursor].start;
                self.err_type = JMUErr.UnexpectedToken;
                return JMUErr.UnexpectedToken;
            }
        }
    }

    /// A function to parse the internal stream
    /// of tokens. This function dispatches to 
    /// a function to parse a single assignment
    /// statement. All errors are "bubbled" up
    /// here.
    pub fn parse(
        self: *Parser
    ) ParserErr!ArrayList(Assignment) {
        var result: ArrayList(Assignment) = .empty;
        errdefer {
            for (result.items) |*item| {
                item.deinit(self.allocator);
            }
            result.deinit(self.allocator);
        }
        while (!self.isDone()){
            result.append(
                self.allocator,
                try self.parseAssignment()
            ) catch {
                self.err_pos = self.stream.items[self.cursor].start;
                self.err_type = JMUErr.WriteErr;
                return JMUErr.WriteErr;
            };
        }
        return result;
    }

    /// A function to parse a single assignment.
    /// Based on which token is encountered where
    /// the value should be, this function dispatches
    /// to the corresponding function. If parsing fails,
    /// an error is returned.
    pub fn parseAssignment(
        self: *Parser
    ) ParserErr!Assignment {
        if ((try self.peekN(0)).token_type == .UserString and
            (try self.peekN(1)).token_type == .Assign)
        {
            switch ((try self.peekN(2)).token_type){
                .Integer => return (try self.parseIntegerAssign()),
                .OpenBracket => return (try self.parseListAssign()),
                .UserString => return (try self.parseStringAssign()), 
                .BooleanTrue => return (try self.parseBooleanAssign()),
                .BooleanFalse => return (try self.parseBooleanAssign()), 
                .FloatingPoint => return (try self.parseFloatingAssign()),
                .SectionMarker => return (try self.parseNestedAssignment()),
                else => {
                    self.err_pos = self.stream.items[self.cursor].start;
                    self.err_type = JMUErr.UnexpectedToken;
                    return JMUErr.UnexpectedToken;
                }
            }
        }
        else if ((try self.peekN(0)).token_type == .UserComment){
            self.advance();
            return .Comment;
        }
        else {
            self.err_pos = self.stream.items[self.cursor].start;
            self.err_type = JMUErr.UnexpectedToken;
            return JMUErr.UnexpectedToken;
        }
    }

    /// A function to parse an assignment to an integer.
    /// If the operation is successful, the `IntegerAssign`
    /// variant of the `Assignment` enumeration union is
    /// returned. If memory allocations or unexpected tokens
    /// are encountered, an error is returned.
    pub fn parseIntegerAssign(
        self: *Parser
    ) ParserErr!Assignment {
        const key_token: Token = try self.expect(.UserString);
        _ = try self.expect(.Assign);
        const value_token: Token = try self.expect(.Integer);
        const parsed_int: i64 = try std.fmt.parseInt(
            i64, std.mem.span(value_token.value.?), 10
        );
        const cloned_str: [*:0]const u8 = try cloneSlice(
            key_token.value.?, 
            self.allocator
        );
        errdefer self.allocator.free(std.mem.span(cloned_str));
        return Assignment { 
            .IntegerAssign = .{ 
                .key = cloned_str,
                .value = parsed_int
            }
        };
    }

    /// A function to parse an assignment to a floating number.
    /// If the operation is successful, the `FloatAssign`
    /// variant of the `Assignment` enumeration union is
    /// returned. If memory allocations or unexpected tokens
    /// are encountered, an error is returned.
    pub fn parseFloatingAssign(
        self: *Parser
    ) ParserErr!Assignment {
        const key_token: Token = try self.expect(.UserString);
        _ = try self.expect(.Assign);
        const value_token: Token = try self.expect(.FloatingPoint);
        const parsed_float: f64 = try std.fmt.parseFloat(
            f64, std.mem.span(value_token.value.?)
        );
        const cloned_str: [*:0]const u8 = try cloneSlice(
            key_token.value.?, 
            self.allocator
        );
        errdefer self.allocator.free(std.mem.span(cloned_str));
        return Assignment { 
            .FloatingAssign = .{ 
                .key = cloned_str, 
                .value = parsed_float
            }
        };
    }

    /// A function to parse an assignment to a string.
    /// If the operation is successful, the `StringAssign`
    /// variant of the `Assignment` enumeration union is
    /// returned. If memory allocations or unexpected tokens
    /// are encountered, an error is returned.
    pub fn parseStringAssign(
        self: *Parser
    ) ParserErr!Assignment {
        const key_token: Token = try self.expect(.UserString);
        _ = try self.expect(.Assign);
        const value_token: Token = try self.expect(.UserString);
        const cloned_key: [*:0]const u8 = try cloneSlice(
            key_token.value.?, 
            self.allocator
        );
        errdefer self.allocator.free(std.mem.span(cloned_key));
        const cloned_value: [*:0]const u8 = try cloneSlice(
            value_token.value.?, 
            self.allocator
        );
        errdefer self.allocator.free(std.mem.span(cloned_value));
        return Assignment { 
            .StringAssign = .{ 
                .key = cloned_key, 
                .value = cloned_value
            }
        };
    }

    /// A function to parse an assignment to a boolean.
    /// If the operation is successful, the `BoolAssign`
    /// variant of the `Assignment` enumeration union is
    /// returned. If memory allocations or unexpected tokens
    /// are encountered, an error is returned.
    pub fn parseBooleanAssign(
        self: *Parser
    ) ParserErr!Assignment {
        const key_token: Token = try self.expect(.UserString);
        _ = try self.expect(.Assign);
        const cloned_key: [*:0]const u8 = try cloneSlice(
            key_token.value.?,
            self.allocator
        );
        errdefer self.allocator.free(std.mem.span(cloned_key));
        if ((try self.peekN(0)).token_type == .BooleanTrue){
            _ = try self.expect(.BooleanTrue);
            return Assignment { 
                .BoolAssign = .{ 
                    .key = cloned_key,
                    .value = true
                }
            };
        }
        else if ((try self.peekN(0)).token_type == .BooleanFalse){
            _ = try self.expect(.BooleanFalse);
            return Assignment { 
                .BoolAssign = .{ 
                    .key = cloned_key, 
                    .value = false
                }
            };
        }
        else {
            self.err_pos = self.stream.items[self.cursor].start;
            self.err_type = JMUErr.UnexpectedToken;
            return JMUErr.UnexpectedToken;
        }
    }

    /// A function to parse an assignment to a list of types.
    /// If the operation is successful, the `*ListAssign`
    /// variant of the `Assignment` enumeration union is
    /// returned. If memory allocations or unexpected tokens
    /// are encountered, an error is returned.
    pub fn parseListAssign(
        self: *Parser
    ) ParserErr!Assignment {
        if ((try self.peekN(0)).token_type == .UserString and
            (try self.peekN(1)).token_type == .Assign and
            (try self.peekN(2)).token_type == .OpenBracket)
        {
            switch ((try self.peekN(3)).token_type){
                .Integer => return (try self.parseIntegerListAssign()), 
                .BooleanTrue => return (try self.parseBoolListAssign()),
                .UserString => return (try self.parseStringListAssign()),
                .BooleanFalse => return (try self.parseBoolListAssign()),
                .FloatingPoint => return (try self.parseFloatListAssign()),
                .SectionMarker => return (try self.parseAssignmentBlockListAssign()),
                else => {
                    self.err_pos = self.stream.items[self.cursor].start;
                    self.err_type = JMUErr.UnexpectedToken;
                    return JMUErr.UnexpectedToken;
                }
            }
        } 
        else {
            self.err_pos = self.stream.items[self.cursor].start;
            self.err_type = JMUErr.UnexpectedToken;
            return JMUErr.UnexpectedToken;
        }
    }

    /// A function to parse an assignment to a list of integers.
    /// If the operation is successful, the `IntegerListAssign`
    /// variant of the `Assignment` enumeration union is
    /// returned. If memory allocations or unexpected tokens
    /// are encountered, an error is returned.
    pub fn parseIntegerListAssign(
        self: *Parser
    ) ParserErr!Assignment {
        const key_token: Token = try self.expect(.UserString);
        const cloned_str: [*:0]const u8 = try cloneSlice(
            key_token.value.?,
            self.allocator
        );
        errdefer self.allocator.free(std.mem.span(cloned_str));
        _ = try self.expect(.Assign);
        _ = try self.expect(.OpenBracket);
        var int_buf: ArrayList(i64) = .empty;
        errdefer int_buf.deinit(self.allocator);
        while (self.cursor < self.stream.items.len){
            if (self.isDone()){
                self.err_pos = self.stream.items[self.cursor].start;
                self.err_type = JMUErr.UnexpectedStreamEnd;
                return JMUErr.UnexpectedStreamEnd;
            }
            else if ((try self.peekN(0)).token_type == .CloseBracket){
                break;
            } 
            else {
                var next: Token = undefined;
                if ((try self.peekN(1)).token_type == .CloseBracket){
                    next = try self.expect(.Integer);
                }
                else {
                    next = try self.expect(.Integer);
                    _ = try self.expect(.Comma);
                }
                const parsed: i64 = parseInt(
                    i64,
                    std.mem.span(next.value.?),
                    10
                ) catch {
                    self.err_pos = next.start;
                    self.err_type = JMUErr.ParseIntErr;
                    return JMUErr.ParseIntErr;
                };
                int_buf.append(
                    self.allocator,
                    parsed
                ) catch {
                    self.err_pos = self.stream.items[self.cursor].start;
                    self.err_type = JMUErr.WriteErr;
                    return JMUErr.WriteErr;
                };
            }
        }
        _ = try self.expect(.CloseBracket);
        return Assignment {
            .IntegerListAssign = .{
                .key = cloned_str,
                .value = int_buf
            }
        };
    }

    /// A function to parse an assignment to a list of floating numbers.
    /// If the operation is successful, the `FlaotingListAssign`
    /// variant of the `Assignment` enumeration union is
    /// returned. If memory allocations or unexpected tokens
    /// are encountered, an error is returned.
    pub fn parseFloatListAssign(
        self: *Parser
    ) ParserErr!Assignment {
        const key_token: Token = try self.expect(.UserString);
        const cloned_str: [*:0]const u8 = try cloneSlice(
            key_token.value.?,
            self.allocator
        );
        errdefer self.allocator.free(std.mem.span(cloned_str));
        _ = try self.expect(.Assign);
        _ = try self.expect(.OpenBracket);
        var float_buf: ArrayList(f64) = .empty;
        errdefer float_buf.deinit(self.allocator);
        while (self.cursor < self.stream.items.len){
            if (self.isDone()){
                self.err_pos = self.stream.items[self.cursor].start;
                self.err_type = JMUErr.UnexpectedStreamEnd;
                return JMUErr.UnexpectedStreamEnd;
            }
            else if ((try self.peekN(0)).token_type == .CloseBracket){
                break;
            } 
            else {
                var next: Token = undefined;
                if ((try self.peekN(1)).token_type == .CloseBracket){
                    next = try self.expect(.FloatingPoint);
                }
                else {
                    next = try self.expect(.FloatingPoint);
                    _ = try self.expect(.Comma);
                }
                const parsed: f64 = parseFloat(
                    f64,
                    std.mem.span(next.value.?),
                ) catch {
                    self.err_pos = next.start;
                    self.err_type = JMUErr.ParseFloatErr;
                    return JMUErr.ParseFloatErr;
                };
                float_buf.append(
                    self.allocator,
                    parsed
                ) catch {
                    self.err_pos = self.stream.items[self.cursor].start;
                    self.err_type = JMUErr.WriteErr;
                    return JMUErr.WriteErr;
                };
            }
        }
        _ = try self.expect(.CloseBracket);
        return Assignment {
            .FloatingListAssign = .{
                .key = cloned_str,
                .value = float_buf
            }
        };
    }

    /// A function to parse an assignment to a list of strings.
    /// If the operation is successful, the `StringListAssign`
    /// variant of the `Assignment` enumeration union is
    /// returned. If memory allocations or unexpected tokens
    /// are encountered, an error is returned.
    pub fn parseStringListAssign(
        self: *Parser
    ) ParserErr!Assignment {
        const key_token: Token = try self.expect(.UserString);
        const cloned_key: [*:0]const u8 = try cloneSlice(
            key_token.value.?,
            self.allocator
        );
        errdefer self.allocator.free(std.mem.span(cloned_key));
        _ = try self.expect(.Assign);
        _ = try self.expect(.OpenBracket);
        var str_buf: ArrayList([*:0]const u8) = .empty;
        errdefer {
            for (str_buf.items) |*item| {
                self.allocator.free(std.mem.span(item.*));
            }
            str_buf.deinit(self.allocator);
        }
        while (self.cursor < self.stream.items.len){
            if (self.isDone()){
                self.err_pos = self.stream.items[self.cursor].start;
                self.err_type = JMUErr.UnexpectedStreamEnd;
                return JMUErr.UnexpectedStreamEnd;
            }
            else if ((try self.peekN(0)).token_type == .CloseBracket){
                break;
            } 
            else {
                var next: Token = undefined;
                if ((try self.peekN(1)).token_type == .CloseBracket){
                    next = try self.expect(.UserString);
                }
                else {
                    next = try self.expect(.UserString);
                    _ = try self.expect(.Comma);
                }
                 const cloned_str: [*:0]const u8 = try cloneSlice(
                    next.value.?,
                    self.allocator
                );
                errdefer self.allocator.free(std.mem.span(cloned_str));
                str_buf.append(
                    self.allocator,
                    cloned_str
                ) catch {
                    self.err_pos = self.stream.items[self.cursor].start;
                    self.err_type = JMUErr.WriteErr;
                    return JMUErr.WriteErr;
                };
            }
        }
        _ = try self.expect(.CloseBracket);
        return Assignment {
            .StringListAssign = .{
                .key = cloned_key,
                .value = str_buf
            }
        };
    }

    /// A function to parse an assignment to a list of booleans.
    /// If the operation is successful, the `BoolListAssign`
    /// variant of the `Assignment` enumeration union is
    /// returned. If memory allocations or unexpected tokens
    /// are encountered, an error is returned.
    pub fn parseBoolListAssign(
        self: *Parser
    ) ParserErr!Assignment {
        const key_token: Token = try self.expect(.UserString);
        const cloned_key: [*:0]const u8 = try cloneSlice(
            key_token.value.?,
            self.allocator
        );
        errdefer self.allocator.free(std.mem.span(cloned_key));
        _ = try self.expect(.Assign);
        _ = try self.expect(.OpenBracket);
        var bool_buf: ArrayList(bool) = .empty;
        errdefer bool_buf.deinit(self.allocator);
        while (self.cursor < self.stream.items.len){
            if (self.isDone()){
                self.err_pos = self.stream.items[self.cursor].start;
                self.err_type = JMUErr.UnexpectedStreamEnd;
                return JMUErr.UnexpectedStreamEnd;
            }
            else if ((try self.peekN(0)).token_type == .CloseBracket){
                break;
            } 
            else {
                var next: Token = undefined;
                if ((try self.peekN(1)).token_type == .CloseBracket){
                    if ((try self.peekN(0)).token_type == .BooleanTrue){
                        next = try self.expect(.BooleanTrue);
                        bool_buf.append(
                            self.allocator,
                            true
                        ) catch {
                            self.err_pos = self.stream.items[self.cursor].start;
                            self.err_type = JMUErr.WriteErr;
                            return JMUErr.WriteErr;
                        };
                    }
                    else if ((try self.peekN(0)).token_type == .BooleanFalse){
                        next = try self.expect(.BooleanFalse);
                        bool_buf.append(
                            self.allocator,
                            false
                        ) catch {
                            self.err_pos = self.stream.items[self.cursor].start;
                            self.err_type = JMUErr.WriteErr;
                            return JMUErr.WriteErr;
                        };
                    }
                    else {
                        self.err_pos = self.stream.items[self.cursor].start;
                        self.err_type = JMUErr.UnexpectedToken;
                        return JMUErr.UnexpectedToken;
                    }
                }
                else {
                    if ((try self.peekN(0)).token_type == .BooleanTrue){
                        next = try self.expect(.BooleanTrue);
                        bool_buf.append(
                            self.allocator,
                            true
                        ) catch {
                            self.err_pos = self.stream.items[self.cursor].start;
                            self.err_type = JMUErr.WriteErr;
                            return JMUErr.WriteErr;
                        };
                    }
                    else if ((try self.peekN(0)).token_type == .BooleanFalse){
                        next = try self.expect(.BooleanFalse);
                        bool_buf.append(
                            self.allocator,
                            false
                        ) catch {
                            self.err_pos = self.stream.items[self.cursor].start;
                            self.err_type = JMUErr.WriteErr;
                            return JMUErr.WriteErr;
                        };
                    }
                    else {
                        self.err_pos = self.stream.items[self.cursor].start;
                        self.err_type = JMUErr.UnexpectedToken;
                        return JMUErr.UnexpectedToken;
                    }
                    _ = try self.expect(.Comma);
                }  
            }
        }
        _ = try self.expect(.CloseBracket);
        return Assignment {
            .BoolListAssign = .{
                .key = cloned_key,
                .value = bool_buf
            }
        };
    }

    /// A function to parse a list of assignments
    /// inside section markers. If the the operation is 
    /// successful, an `ArrayList` of instances of
    /// the `Assignment` enumeration is returned. 
    /// If memory allocations or unexpected tokens
    /// are encountered, an error is returned.
    pub fn parseAssignmentBlock(
        self: *Parser
    ) ParserErr!ArrayList(Assignment) {
        _ = try self.expect(.SectionMarker);
        var assignment_buf: ArrayList(Assignment) = .empty;
        errdefer {
            for (assignment_buf.items) |*item| {
                item.deinit(self.allocator);
            }
            assignment_buf.deinit(self.allocator);
        }
        while (self.cursor < self.stream.items.len){
            if ((try self.peekN(0)).token_type == .SectionMarker){
                break;
            }
            else {
                assignment_buf.append(
                    self.allocator,
                    try self.parseAssignment()
                ) catch {
                    self.err_pos = self.stream.items[self.cursor].start;
                    self.err_type = JMUErr.WriteErr;
                    return JMUErr.WriteErr;
                };
            }
        }
        _ = try self.expect(.SectionMarker);
        return assignment_buf;
    }

    /// A function to parse an assignment to a list of a 
    /// block of assignments. If the the operation is 
    /// successful, the `AssignmentBlockList` variant of 
    /// the `Assignment` enumeration union is returned. 
    /// If memory allocations fail or unexpected tokens
    /// are encountered, an error is returned.
    pub fn parseAssignmentBlockListAssign(
        self: *Parser
    ) ParserErr!Assignment {
        const key_token: Token = try self.expect(.UserString);
        const cloned_key: [*:0]const u8 = try cloneSlice(
            key_token.value.?,
            self.allocator
        );
        errdefer self.allocator.free(std.mem.span(cloned_key));
        _ = try self.expect(.Assign);
        _ = try self.expect(.OpenBracket);
        var block_buf: ArrayList(ArrayList(Assignment)) = .empty;
        errdefer {
            for (block_buf.items) |*block| {
                for (block.items) |*item| {
                    item.deinit(self.allocator);
                }
                block.deinit(self.allocator);
            }
            block_buf.deinit(self.allocator);
        }
        while (!self.isDone()) {
            if ((try self.peekN(0)).token_type == .CloseBracket){
                break;
            }
            const block = try self.parseAssignmentBlock();
            block_buf.append(
                self.allocator,
                block
            ) catch {
                self.err_pos = self.stream.items[self.cursor].start;
                self.err_type = JMUErr.WriteErr;
                return JMUErr.WriteErr;
            };
            if ((try self.peekN(0)).token_type == .Comma) {
                _ = try self.expect(.Comma);
                if ((try self.peekN(0)).token_type == .CloseBracket) {
                    self.err_pos = self.stream.items[self.cursor].start;
                    self.err_type = JMUErr.UnexpectedToken;
                    return JMUErr.UnexpectedToken;
                }
            } 
            else {
                if ((try self.peekN(0)).token_type != .CloseBracket) {
                    self.err_pos = self.stream.items[self.cursor].start;
                    self.err_type = JMUErr.UnexpectedToken;
                    return JMUErr.UnexpectedToken;
                }
                break;
            }
        }
        _ = try self.expect(.CloseBracket);
        return Assignment {
            .AssignmentBlockList = .{
                .key = cloned_key,
                .value = block_buf
            }
        };
    }

    /// A function to parse an assignment to a block of assignments.
    /// If the the operation is successful, the `NestedAssign`
    /// variant of the `Assignment` enumeration union is
    /// returned. If memory allocations or unexpected tokens
    /// are encountered, an error is returned.
    pub fn parseNestedAssignment(
        self: *Parser
    ) ParserErr!Assignment {
        const key_token: Token = try self.expect(.UserString);
        const cloned_key: [*:0]const u8 = try cloneSlice(
            key_token.value.?,
            self.allocator
        );
        errdefer self.allocator.free(std.mem.span(cloned_key));
        _ = try self.expect(.Assign);
        return Assignment {
            .NestedAssign = .{
                .key = cloned_key,
                .value = try self.parseAssignmentBlock()
            }
        };
    }
};
