const std = @import("std");
const print = std.debug.print;
const dbgeng = @import("../dbgeng/bindings.zig");

// TODO: Do i like this name better ? [DbgEngSession, DbgEngWrapper, DbgEngExtension] .
pub const DbgEngExtension = struct {
    client: ?*dbgeng.IDebugClient,
    control: ?*dbgeng.IDebugControl,
    symbols: ?*dbgeng.IDebugSymbols,

    pub fn init() !DbgEngExtension {
        var self = DbgEngExtension{
            .client = null,
            .control = null,
            .symbols = null,
        };

        var client: ?*dbgeng.IDebugClient = null;
        var hr = dbgeng.DebugCreate(&IID_IDebugClient, @ptrCast(&client));
        if (hr != dbgeng.S_OK) {
            print("Failed to create debug client: 0x{x:0>8}\n", .{hr});
            return error.DebugCreateFailed;
        }
        self.client = client;

        var control: ?*dbgeng.IDebugControl = null;
        hr = client.?.lpVtbl.*.QueryInterface.?(client.?, &IID_IDebugControl, @ptrCast(&control));
        if (hr != dbgeng.S_OK) {
            print("Failed to get control interface: 0x{x:0>8}\n", .{hr});
            return error.QueryInterfaceFailed;
        }
        self.control = control;

        var symbols: ?*dbgeng.IDebugSymbols = null;
        hr = client.?.lpVtbl.*.QueryInterface.?(client.?, &IID_IDebugSymbols, @ptrCast(&symbols));
        if (hr != dbgeng.S_OK) {
            print("Failed to get symbols interface: 0x{x:0>8}\n", .{hr});
            return error.QueryInterfaceFailed;
        }
        self.symbols = symbols;

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

    pub fn createProcess(self: *DbgEngExtension, cmdline: [*:0]u8) !void {
        const hr = self.client.?.lpVtbl.*.CreateProcessA.?(
            self.client.?,
            0, // Server (local)
            cmdline,
            dbgeng.DEBUG_PROCESS, // Create flags
            // NOTE: When you use DEBUG_PROCESS, DbgEng creates the process but doesn't automatically attach the debugger properly for event processing.
            // The process is created in a state where the debugger needs additional setup.
            // https://learn.microsoft.com/en-us/windows/win32/debug/process-functions-for-debugging
            // https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/dbgeng/nf-dbgeng-idebugclient5-createprocessandattach
        );
        if (hr != dbgeng.S_OK) {
            print("Failed to create process: 0x{x:0>8}\n", .{hr});
            return error.CreateProcessFailed;
        }
    }

    /// Returns information about the execution status of the debugger engine.
    pub fn currentStatus(self: *DbgEngExtension) !DebugStatus {
        var status: u32 = 0;
        const hr = self.control.?.lpVtbl.*.GetExecutionStatus.?(self.control.?, &status);
        if (hr != dbgeng.S_OK) {
            print("GetExecutionStatus failed: 0x{x:0>8}\n", .{hr});
            return error.GetExecutionStatusFailed;
        }
        return DebugStatus.from(status);
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
const DebugStatus = enum {
    no_change,
    no_debuggee,
    step_over,
    step_into,
    step_branch,
    go,
    status_break,
    unknown,
    pub fn from(code: u32) DebugStatus {
        return switch (code) {
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
