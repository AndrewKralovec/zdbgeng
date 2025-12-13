const std = @import("std");
const dbgeng = @import("./bindings.zig");

const windows = std.os.windows;
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const HRESULT = windows.HRESULT;
const WINAPI = windows.WINAPI;
const GUID = dbgeng.GUID;

const IID_IDebugOutputCallbacks = GUID{
    .Data1 = 0x4bf58045,
    .Data2 = 0xd654,
    .Data3 = 0x4c40,
    .Data4 = [_]u8{ 0xb0, 0xaf, 0x68, 0x30, 0x90, 0xf3, 0x56, 0xdc },
};

// IUnknown GUID.
const IID_IUnknown = GUID{
    .Data1 = 0x00000000,
    .Data2 = 0x0000,
    .Data3 = 0x0000,
    .Data4 = [_]u8{ 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 },
};

// Breakpoint type constants.
const DEBUG_BREAKPOINT_CODE: u32 = 0;
const DEBUG_BREAKPOINT_DATA: u32 = 1;

// Breakpoint flag constants.
const DEBUG_BREAKPOINT_ENABLED: u32 = 0x1;
const DEBUG_BREAKPOINT_DEFERRED: u32 = 0x2;
const DEBUG_BREAKPOINT_ONE_SHOT: u32 = 0x100;

// Output mask constants.
const DEBUG_OUTPUT_NORMAL: u32 = 0x00000001;
const DEBUG_OUTPUT_ERROR: u32 = 0x00000002;
const DEBUG_OUTPUT_WARNING: u32 = 0x00000004;
const DEBUG_OUTPUT_VERBOSE: u32 = 0x00000008;
const DEBUG_OUTPUT_PROMPT: u32 = 0x00000010;
const DEBUG_OUTPUT_PROMPT_REGISTERS: u32 = 0x00000020;
const DEBUG_OUTPUT_EXTENSION_WARNING: u32 = 0x00000040;
const DEBUG_OUTPUT_DEBUGGEE: u32 = 0x00000080;
const DEBUG_OUTPUT_DEBUGGEE_PROMPT: u32 = 0x00000100;
const DEBUG_OUTPUT_SYMBOLS: u32 = 0x00000200;

pub const IDebugOutputCallbacks = extern struct {
    lpVtbl: *const IDebugOutputCallbacksVtbl,
};

/// IDebugOutputCallbacks COM interface structures
pub const IDebugOutputCallbacksVtbl = extern struct {
    QueryInterface: *const fn (
        self: *IDebugOutputCallbacks,
        riid: *const GUID,
        ppvObject: ?*?*anyopaque,
    ) callconv(WINAPI) HRESULT,

    AddRef: *const fn (
        self: *IDebugOutputCallbacks,
    ) callconv(WINAPI) u32,

    Release: *const fn (
        self: *IDebugOutputCallbacks,
    ) callconv(WINAPI) u32,

    Output: *const fn (
        self: *IDebugOutputCallbacks,
        Mask: u32,
        Text: [*:0]const u8,
    ) callconv(WINAPI) HRESULT,
};

pub const OutputCallbacksImpl = struct {
    // NOTE: MUST be first field!
    vtbl_ptr: *const IDebugOutputCallbacksVtbl,
    ref_count: std.atomic.Value(u32),
    allocator: Allocator,

    pub fn create(allocator: Allocator) !*OutputCallbacksImpl {
        const self = try allocator.create(OutputCallbacksImpl);
        self.* = OutputCallbacksImpl{
            .vtbl_ptr = &vtable,
            .ref_count = std.atomic.Value(u32).init(1),
            .allocator = allocator,
        };
        return self;
    }

    pub fn queryInterface(
        iface: *IDebugOutputCallbacks,
        riid: *const GUID,
        ppvObject: ?*?*anyopaque,
    ) callconv(WINAPI) HRESULT {
        // Check if riid matches IUnknown or IDebugOutputCallbacks.
        const is_unknown = std.mem.eql(u8, std.mem.asBytes(riid), std.mem.asBytes(&IID_IUnknown));
        const is_output_callbacks = std.mem.eql(u8, std.mem.asBytes(riid), std.mem.asBytes(&IID_IDebugOutputCallbacks));

        if (is_unknown or is_output_callbacks) {
            const self: *OutputCallbacksImpl = @fieldParentPtr("vtbl_ptr", &iface.lpVtbl);
            _ = self.ref_count.fetchAdd(1, .seq_cst);
            if (ppvObject) |obj| {
                obj.* = iface;
            }
            return dbgeng.S_OK;
        }

        if (ppvObject) |obj| {
            obj.* = null;
        }
        return dbgeng.E_NOINTERFACE;
    }

    pub fn addRef(iface: *IDebugOutputCallbacks) callconv(WINAPI) u32 {
        const self: *OutputCallbacksImpl = @fieldParentPtr("vtbl_ptr", &iface.lpVtbl);
        const new_count = self.ref_count.fetchAdd(1, .seq_cst) + 1;
        return new_count;
    }

    pub fn release(iface: *IDebugOutputCallbacks) callconv(WINAPI) u32 {
        const self: *OutputCallbacksImpl = @fieldParentPtr("vtbl_ptr", &iface.lpVtbl);
        const old_count = self.ref_count.fetchSub(1, .seq_cst);
        const new_count = old_count - 1;

        if (new_count == 0) {
            const allocator = self.allocator;
            allocator.destroy(self);
            return 0;
        }

        return new_count;
    }

    pub fn output(
        iface: *IDebugOutputCallbacks,
        mask: u32,
        text: [*:0]const u8,
    ) callconv(WINAPI) HRESULT {
        _ = iface; // Discard self.
        const text_slice = std.mem.span(text); // Convert to slice for easier handling.

        const prefix = if (mask & DEBUG_OUTPUT_ERROR != 0)
            "[ERROR] "
        else if (mask & DEBUG_OUTPUT_WARNING != 0)
            "[WARNING] "
        else if (mask & DEBUG_OUTPUT_VERBOSE != 0)
            "[VERBOSE] "
        else if (mask & DEBUG_OUTPUT_PROMPT != 0)
            "[PROMPT] "
        else if (mask & DEBUG_OUTPUT_DEBUGGEE != 0)
            "[DEBUGGEE] "
        else if (mask & DEBUG_OUTPUT_SYMBOLS != 0)
            "[SYMBOLS] "
        else
            "[INFO] ";

        print("{s}{s}", .{ prefix, text_slice });

        return dbgeng.S_OK;
    }

    const vtable = IDebugOutputCallbacksVtbl{
        .QueryInterface = queryInterface,
        .AddRef = addRef,
        .Release = release,
        .Output = output,
    };
};
