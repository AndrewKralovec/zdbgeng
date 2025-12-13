const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const dbgeng = @import("../dbgeng/bindings.zig");
const OutputCallbacksImpl = @import("../dbgeng/callbacks.zig").OutputCallbacksImpl;
const IDebugOutputCallbacks = @import("../dbgeng/callbacks.zig").IDebugOutputCallbacks;

pub const DbgEngExtension = struct {
    client: ?*dbgeng.IDebugClient,
    control: ?*dbgeng.IDebugControl,
    symbols: ?*dbgeng.IDebugSymbols,
    output_callbacks: ?*OutputCallbacksImpl,
    allocator: Allocator,

    pub fn init(allocator: Allocator) !DbgEngExtension {
        var self = DbgEngExtension{
            .client = null,
            .control = null,
            .symbols = null,
            .output_callbacks = null,
            .allocator = allocator,
        };

        // Create debug client.
        var client: ?*dbgeng.IDebugClient = null;
        var hr = dbgeng.DebugCreate(&IID_IDebugClient, @ptrCast(&client));
        if (hr != dbgeng.S_OK) {
            print("failed to create debug client: 0x{x:0>8}\n", .{hr});
            return error.DebugCreateFailed;
        }
        self.client = client;

        // Get control interface.
        var control: ?*dbgeng.IDebugControl = null;
        hr = client.?.lpVtbl.*.QueryInterface.?(client.?, &IID_IDebugControl, @ptrCast(&control));
        if (hr != dbgeng.S_OK) {
            print("failed to get control interface: 0x{x:0>8}\n", .{hr});
            return error.QueryInterfaceFailed;
        }
        self.control = control;

        // Get symbols interface.
        var symbols: ?*dbgeng.IDebugSymbols = null;
        hr = client.?.lpVtbl.*.QueryInterface.?(client.?, &IID_IDebugSymbols, @ptrCast(&symbols));
        if (hr != dbgeng.S_OK) {
            print("failed to get symbols interface: 0x{x:0>8}\n", .{hr});
            return error.QueryInterfaceFailed;
        }
        self.symbols = symbols;

        // Set engine options to enable initial break.
        // TODO: Make configurable.
        hr = control.?.lpVtbl.*.AddEngineOptions.?(control.?, dbgeng.DEBUG_ENGOPT_INITIAL_BREAK);
        if (hr != dbgeng.S_OK) {
            print("failed to set initial break option: 0x{x:0>8}\n", .{hr});
        }

        // Create and register output callbacks.
        const callbacks = OutputCallbacksImpl.create(allocator) catch |err| {
            print("failed to create output callbacks: {}\n", .{err});
            return self; // Continue without callbacks.
        };
        self.output_callbacks = callbacks;

        // Cast to dbgeng IDebugOutputCallbacks interface pointer.
        const callbacks_iface: ?*dbgeng.IDebugOutputCallbacks = @ptrCast(callbacks);
        hr = client.?.lpVtbl.*.SetOutputCallbacks.?(client.?, callbacks_iface);
        if (hr != dbgeng.S_OK) {
            // Clean up the callbacks since we couldnt register them.
            print("Warning: Failed to set output callbacks: 0x{x:0>8}\n", .{hr});
            allocator.destroy(callbacks);
            self.output_callbacks = null;
        } else {
            // Release our reference - DbgEng holds its own reference via AddRef
            // This brings ref_count from 2 (ours + DbgEngs) to 1 (just DbgEngs)
            const iface_for_release: *IDebugOutputCallbacks = @ptrCast(callbacks);
            _ = iface_for_release.lpVtbl.Release(iface_for_release);
        }

        return self;
    }

    pub fn deinit(self: *DbgEngExtension) void {
        if (self.symbols) |symbols| {
            _ = symbols.lpVtbl.*.Release.?(symbols);
        }
        if (self.control) |control| {
            _ = control.lpVtbl.*.Release.?(control);
        }
        if (self.client) |client| {
            _ = client.lpVtbl.*.Release.?(client);
        }
    }

    /// Creates a new process to be debugged with the given command line.
    // NOTE: When you use DEBUG_PROCESS, DbgEng creates the process but doesn't automatically attach the debugger properly for event processing.
    // The process is created in a state where the debugger needs additional setup.
    // https://learn.microsoft.com/en-us/windows/win32/debug/process-functions-for-debugging
    // https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/dbgeng/nf-dbgeng-idebugclient5-createprocessandattach
    pub fn createProcess(self: *DbgEngExtension, cmdline: [*:0]u8) !void {
        const hr = self.client.?.lpVtbl.*.CreateProcessA.?(
            self.client.?,
            0, // Server (local)
            cmdline,
            dbgeng.DEBUG_PROCESS, // Create flags
        );
        if (hr != dbgeng.S_OK) {
            print("Failed to create process: 0x{x:0>8}\n", .{hr});
            return error.CreateProcessFailed;
        }
    }

    /// Returns information about the execution status of the debugger engine.
    pub fn executionStatus(self: *DbgEngExtension) !DebugStatus {
        var status: u32 = 0;
        const hr = self.control.?.lpVtbl.*.GetExecutionStatus.?(self.control.?, &status);
        if (hr != dbgeng.S_OK) {
            print("GetExecutionStatus failed: 0x{x:0>8}\n", .{hr});
            return error.GetExecutionStatusFailed;
        }
        return DebugStatus.from(status);
    }

    pub fn setExecutionStatus(self: *DbgEngExtension, status: u32) !void {
        const hr = self.control.?.lpVtbl.*.SetExecutionStatus.?(self.control.?, status);
        if (hr != dbgeng.S_OK) {
            print("SetExecutionStatus failed: 0x{x:0>8}\n", .{hr});
            return error.SetExecutionStatusFailed;
        }
    }

    pub fn executeCommand(self: *DbgEngExtension, command: [*:0]const u8) !void {
        const hr = self.control.?.lpVtbl.*.Execute.?(
            self.control.?,
            dbgeng.DEBUG_OUTCTL_ALL_CLIENTS,
            command,
            0,
        );
        if (hr != dbgeng.S_OK) {
            print("Execute command failed: 0x{x:0>8}\n", .{hr});
            return error.ExecuteCommandFailed;
        }
    }

    pub fn waitForEvent(self: *DbgEngExtension, timeout_ms: u32) !void {
        const hr = self.control.?.lpVtbl.*.WaitForEvent.?(self.control.?, 0, timeout_ms);
        // S_OK means event occurred, S_FALSE means timeout
        if (hr != dbgeng.S_OK) {
            print("WaitForEvent failed: {any}\n", .{hr});
            return error.WaitForEventFailed;
        }
    }
};

pub const IID_IDebugClient = dbgeng.GUID{
    .Data1 = 0x27fe5639,
    .Data2 = 0x8407,
    .Data3 = 0x4f47,
    .Data4 = [_]u8{ 0x83, 0x64, 0xee, 0x11, 0x8f, 0xb0, 0x8a, 0xc8 },
};

pub const IID_IDebugControl = dbgeng.GUID{
    .Data1 = 0x5182e668,
    .Data2 = 0x105e,
    .Data3 = 0x416e,
    .Data4 = [_]u8{ 0xad, 0x92, 0x24, 0xef, 0x80, 0x04, 0x24, 0xba },
};

pub const IID_IDebugSymbols = dbgeng.GUID{
    .Data1 = 0x8c31e98c,
    .Data2 = 0x983a,
    .Data3 = 0x48a5,
    .Data4 = [_]u8{ 0x90, 0x16, 0x6f, 0xe5, 0xd6, 0x67, 0xa9, 0x50 },
};

/// Represents the current execution status of the debugger engine.
/// https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/dbgeng/nf-dbgeng-idebugcontrol-getexecutionstatus
/// https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/debug-status-xxx
pub const DebugStatus = enum {
    no_change,
    no_debuggee,
    step_over,
    step_into,
    step_branch,
    go,
    status_break,
    unknown,
    /// Converts the u32 execution status code to a DebugStatus enum value.
    pub fn from(status: u32) DebugStatus {
        return switch (status) {
            dbgeng.DEBUG_STATUS_NO_CHANGE => {
                return DebugStatus.no_change;
            },
            dbgeng.DEBUG_STATUS_NO_DEBUGGEE => {
                return DebugStatus.no_debuggee;
            },
            dbgeng.DEBUG_STATUS_STEP_OVER => {
                return DebugStatus.step_over;
            },
            dbgeng.DEBUG_STATUS_STEP_INTO => {
                return DebugStatus.step_into;
            },
            dbgeng.DEBUG_STATUS_STEP_BRANCH => {
                return DebugStatus.step_branch;
            },
            dbgeng.DEBUG_STATUS_GO => {
                return DebugStatus.go;
            },
            dbgeng.DEBUG_STATUS_BREAK => {
                return DebugStatus.status_break;
            },
            else => {
                return DebugStatus.unknown;
            },
        };
    }
};
