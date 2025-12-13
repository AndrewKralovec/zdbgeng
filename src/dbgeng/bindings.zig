const std = @import("std");
const dbgeng = @cImport({
    @cInclude("windows.h");
    @cInclude("dbgeng.h");
});

pub const GUID = dbgeng.GUID;
pub const IID = dbgeng.IID;

pub const IDebugClient = dbgeng.IDebugClient;
pub const IDebugControl = dbgeng.IDebugControl;
pub const IDebugSymbols = dbgeng.IDebugSymbols;

pub const S_OK = dbgeng.S_OK;
pub const S_FALSE = dbgeng.S_FALSE;

pub const DEBUG_PROCESS = dbgeng.DEBUG_PROCESS;
pub const DEBUG_OUTCTL_ALL_CLIENTS = dbgeng.DEBUG_OUTCTL_ALL_CLIENTS;

pub const DEBUG_STATUS_NO_CHANGE = dbgeng.DEBUG_STATUS_NO_CHANGE;
pub const DEBUG_STATUS_GO = dbgeng.DEBUG_STATUS_GO;
pub const DEBUG_STATUS_STEP_OVER = dbgeng.DEBUG_STATUS_STEP_OVER;
pub const DEBUG_STATUS_STEP_INTO = dbgeng.DEBUG_STATUS_STEP_INTO;
pub const DEBUG_STATUS_BREAK = dbgeng.DEBUG_STATUS_BREAK;
pub const DEBUG_STATUS_NO_DEBUGGEE = dbgeng.DEBUG_STATUS_NO_DEBUGGEE;
pub const DEBUG_STATUS_STEP_BRANCH = dbgeng.DEBUG_STATUS_STEP_BRANCH;

pub const DebugCreate = dbgeng.DebugCreate;
