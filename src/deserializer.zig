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

// Importing the function to clone a pointer to
// a null-terminated string slice.
const cloneSlice = @import("utils.zig").cloneSlice;

// Importing the enumeration union representing all
// possible types of assignments in JMU source code.
const Assignment = @import("parser.zig").Assignment;

/// A function to initialize a new deserializer
/// given the target type to deserialize into.
pub fn Deserializer(comptime T: type) type {
    return struct {
        cursor: u64,
        target: *T,
        stmts: *const ArrayList(Assignment),
        allocator: std.mem.Allocator,

        /// Initializing and returning the
        /// `Deserializer` structure.
        pub fn init(
            sub: *const ArrayList(Assignment), 
            allocator: Allocator,
            target_type: *T
        ) @This() {
            return .{
                .cursor = 0,
                .stmts = sub,
                .target = target_type,
                .allocator = allocator,
            };
        }

        /// Advances the internal cursor
        /// through a list of assignment
        /// statements.
        pub fn advance(
            self: *@This()
        ) void {
            self.cursor = self.cursor + 1;
        }

        /// A function to check if the end
        /// of the assignment block stream
        /// has been reached or not. A boolean
        /// is returned based on this.
        pub fn isDone(
            self: *@This()
        ) bool {
            return self.cursor == self.stmts.items.len;
        }

        /// A function to start lopping through
        /// the list of assignments.
        pub fn deserialize(
            self: *@This()
        ) !void {
            while (!self.isDone()){
                try self.deserializeAssignment();
                self.advance();
            }
        }

        /// A function to dispatch to
        /// other functions based on 
        /// what kind of statement is
        /// received. Each dispatch searches
        /// for the field with the same name
        /// as the key of the current assignment
        /// and sets the field's value to the value
        /// in the assignment.
        pub fn deserializeAssignment(
            self: *@This()
        ) !void {
            const item = self.stmts.items[self.cursor];
            switch (item) {
                .Comment => {}, 
                .BoolAssign => |b| try self.mapBoolAssign(b.key, b.value),
                .IntegerAssign => |i| try self.mapIntAssign(i.key, i.value),
                .StringAssign => |s| try self.mapStringAssign(s.key, s.value),
                .FloatingAssign => |f| try self.mapFloatAssign(f.key, f.value),
                .NestedAssign => |na| try self.mapBlockAssign(na.key, na.value),
                .BoolListAssign => |bl| try self.mapBoolListAssign(bl.key, bl.value),
                .IntegerListAssign => |il| try self.mapIntListAssign(il.key, il.value),
                .StringListAssign => |sl| try self.mapStringListAssign(sl.key, sl.value),
                .FloatingListAssign => |fl| try self.mapFloatListAssign(fl.key, fl.value),
                .AssignmentBlockList => |abl| try self.mapBlockListAssign(abl.key, abl.value),
            }
        }

        /// A function to map a key-value
        /// pair to a structure field that
        /// takes a string value.
        pub fn mapStringAssign(
            self: *@This(),
            key: [*:0]const u8,
            value: [*:0]const u8,
        ) !void {
            var field_found: bool = false;
            const info = @typeInfo(T).@"struct";
            inline for (info.field_names, info.field_types) |field_name, field_type| {
                if (std.mem.eql(u8, std.mem.span(key), field_name)){
                    field_found = true;
                    if (field_type == [*:0]const u8){
                        const cloned: [*:0]const u8 = cloneSlice(
                            value,
                            self.allocator
                        ) catch return JMUErr.AllocErr;
                        errdefer self.allocator.free(cloned);
                        @field(self.target, field_name) = cloned;
                    }
                    else {
                        return JMUErr.ValueTypeErr;
                    }
                }
            }
            if (!field_found) {
                return JMUErr.NoSuchFieldErr;
            }
        }

        /// A function to map a key-value
        /// pair to a structure field that
        /// takes a boolean value.
        pub fn mapBoolAssign(
            self: *@This(),
            key: [*:0]const u8,
            value: bool,
        ) !void {
            var field_found: bool = false;
            const info = @typeInfo(T).@"struct";
            inline for (info.field_names, info.field_types) |field_name, field_type| {
                if (std.mem.eql(u8, std.mem.span(key), field_name)){
                    field_found = true;
                    if (field_type == bool){ 
                        @field(self.target, field_name) = value;
                    }
                    else {
                        return JMUErr.ValueTypeErr;
                    }
                }
            }
            if (!field_found) {
                return JMUErr.NoSuchFieldErr;
            }
        }

        /// A function to map a key-value
        /// pair to a structure field that
        /// takes an integer value.
        pub fn mapIntAssign(
            self: *@This(),
            key: [*:0]const u8,
            value: i64,
        ) !void {
            var field_found: bool = false;
            const info = @typeInfo(T).@"struct";
            inline for (info.field_names, info.field_types) |field_name, field_type| {
                if (std.mem.eql(u8, std.mem.span(key), field_name)){
                    field_found = true;
                    if (field_type == i64){ 
                        @field(self.target, field_name) = value;
                    }
                    else {
                        return JMUErr.ValueTypeErr;
                    }
                }
            }
            if (!field_found) {
                return JMUErr.NoSuchFieldErr;
            }
        }

        /// A function to map a key-value
        /// pair to a structure field that
        /// takes a floating number value.
        pub fn mapFloatAssign(
            self: *@This(),
            key: [*:0]const u8,
            value: f64,
        ) !void {
            var field_found: bool = false;
            const info = @typeInfo(T).@"struct";
            inline for (info.field_names, info.field_types) |field_name, field_type| {
                if (std.mem.eql(u8, std.mem.span(key), field_name)){
                    field_found = true;
                    if (field_type == f64){ 
                        @field(self.target, field_name) = value;
                    }
                    else {
                        return JMUErr.ValueTypeErr;
                    }
                }
            }
            if (!field_found) {
                return JMUErr.NoSuchFieldErr;
            }
        }

        /// A function to map a key-value
        /// pair to a structure field that
        /// takes a list of booleans as a value.
        pub fn mapBoolListAssign(
            self: *@This(),
            key: [*:0]const u8,
            value: ArrayList(bool),
        ) !void {
            var field_found: bool = false;
            const info = @typeInfo(T).@"struct";
            inline for (info.field_names, info.field_types) |field_name, field_type| {
                if (std.mem.eql(u8, std.mem.span(key), field_name)){
                    field_found = true;
                    if (field_type == ArrayList(bool)){
                        var cloned_list: ArrayList(bool) = .empty;
                        errdefer cloned_list.deinit(self.allocator);
                        cloned_list.appendSlice(
                            self.allocator,
                            value.items
                        ) catch return JMUErr.WriteErr;
                        @field(self.target, field_name) = cloned_list;
                    }
                    else {
                        return JMUErr.ValueTypeErr;
                    }
                }
            }
            if (!field_found) {
                return JMUErr.NoSuchFieldErr;
            }
        }

        /// A function to map a key-value
        /// pair to a structure field that
        /// takes a list of integers as a value.
        pub fn mapIntListAssign(
            self: *@This(),
            key: [*:0]const u8,
            value: ArrayList(i64),
        ) !void {
            var field_found: bool = false;
            const info = @typeInfo(T).@"struct";
            inline for (info.field_names, info.field_types) |field_name, field_type| {
                if (std.mem.eql(u8, std.mem.span(key), field_name)){
                    field_found = true;
                    if (field_type == ArrayList(i64)){
                        var cloned_list: ArrayList(i64) = .empty;
                        errdefer cloned_list.deinit(self.allocator);
                        cloned_list.appendSlice(
                            self.allocator,
                            value.items
                        ) catch return JMUErr.WriteErr;
                        @field(self.target, field_name) = cloned_list;
                    }
                    else {
                        return JMUErr.ValueTypeErr;
                    }
                }
            }
            if (!field_found) {
                return JMUErr.NoSuchFieldErr;
            }
        }

        /// A function to map a key-value
        /// pair to a structure field that
        /// takes a list of floats as a value.
        pub fn mapFloatListAssign(
            self: *@This(),
            key: [*:0]const u8,
            value: ArrayList(f64),
        ) !void {
            var field_found: bool = false;
            const info = @typeInfo(T).@"struct";
            inline for (info.field_names, info.field_types) |field_name, field_type| {
                if (std.mem.eql(u8, std.mem.span(key), field_name)){
                    field_found = true;
                    if (field_type == ArrayList(f64)){
                        var cloned_list: ArrayList(f64) = .empty;
                        errdefer cloned_list.deinit(self.allocator);
                        cloned_list.appendSlice(
                            self.allocator,
                            value.items
                        ) catch return JMUErr.WriteErr;
                        @field(self.target, field_name) = cloned_list;
                    }
                    else {
                        return JMUErr.ValueTypeErr;
                    }
                }
            }
            if (!field_found) {
                return JMUErr.NoSuchFieldErr;
            }
        }

        /// A function to map a key-value
        /// pair to a structure field that
        /// takes a list of strings as a value.
        pub fn mapStringListAssign(
            self: *@This(),
            key: [*:0]const u8,
            value: ArrayList([*:0]const u8),
        ) !void {
            var field_found: bool = false;
            const info = @typeInfo(T).@"struct";
            inline for (info.field_names, info.field_types) |field_name, field_type| {
                if (std.mem.eql(u8, std.mem.span(key), field_name)){
                    field_found = true;
                    if (field_type == ArrayList([*:0]const u8)){
                        var cloned_list: ArrayList([*:0]const u8) = .empty;
                        errdefer {
                            for (cloned_list.items) |item| {
                                self.allocator.free(std.mem.span(item));
                            }
                            cloned_list.deinit(self.allocator);
                        }
                        for (value.items) |item| {
                            const cloned: [*:0]const u8 = cloneSlice(
                                item,
                                self.allocator
                            ) catch return JMUErr.AllocErr;
                            errdefer self.allocator.free(std.mem.span(cloned));
                            cloned_list.append(
                                self.allocator,
                                cloned
                            ) catch return JMUErr.WriteErr;
                        }
                        @field(self.target, field_name) = cloned_list;
                    }
                    else {
                        return JMUErr.ValueTypeErr;
                    }
                }
            }
            if (!field_found) {
                return JMUErr.NoSuchFieldErr;
            }
        }

        /// A function to map a key-value
        /// pair to a structure field that
        /// takes another block of assignments
        /// in the form of a structure as a value.
        pub fn mapBlockAssign(
            self: *@This(),
            key: [*:0]const u8,
            value: ArrayList(Assignment),
        ) !void {
            var field_found: bool = false;
            const info = @typeInfo(T).@"struct";
            inline for (info.field_names, info.field_types) |field_name, field_type| {
                if (std.mem.eql(u8, std.mem.span(key), field_name)){
                    field_found = true;
                    if (@typeInfo(field_type) == .@"struct"){
                        var des = Deserializer(field_type).init(
                            &value, 
                            self.allocator, 
                            &@field(self.target, field_name)
                        );
                        try des.deserialize();
                    }
                    else {
                        return JMUErr.ValueTypeErr;
                    }
                }
            }
            if (!field_found) {
                return JMUErr.NoSuchFieldErr;
            }
        }

        /// A function to map a key-value
        /// pair to a structure field that
        /// takes a list of a block of assignments
        /// in the form of a list of a structure. 
        pub fn mapBlockListAssign(
            self: *@This(),
            key: [*:0]const u8, 
            value: ArrayList(ArrayList(Assignment))
        ) !void {
            var field_found: bool = false;
            const super_info = @typeInfo(T).@"struct";
            inline for (
                super_info.field_names, 
                super_info.field_types
            ) |super_field_name, super_field_type| {
                if (std.mem.eql(u8, std.mem.span(key), super_field_name)){
                    field_found = true;
                    if (@typeInfo(super_field_type) == .@"struct") {
                        if (@hasField(super_field_type, "items")) {
                           comptime var ElementType: type = undefined;
                            const info = @typeInfo(super_field_type).@"struct";
                            inline for (info.field_names, info.field_types) |field_name, field_type| {
                                if (comptime std.mem.eql(u8, field_name, "items")) {
                                    ElementType = @typeInfo(field_type).pointer.child;
                                } 
                            }
                            if (@typeInfo(ElementType) != .@"struct") {
                                return JMUErr.ValueTypeErr;
                            }
                            var cloned_list: ArrayList(ElementType) = .empty;
                            errdefer cloned_list.deinit(self.allocator);
                            for (value.items) |block| {
                                var element: ElementType = undefined;
                                @memset(std.mem.asBytes(&element), 0);
                                var des = Deserializer(ElementType).init(
                                    &block,
                                    self.allocator,
                                    &element
                                );
                                try des.deserialize();
                                cloned_list.append(
                                    self.allocator,
                                    element
                                ) catch return JMUErr.WriteErr;
                            }
                            @field(self.target, super_field_name) = cloned_list;
                        }
                    }
                }
            }
            if (!field_found) {
                return JMUErr.NoSuchFieldErr;
            }
        }    
    };
}
