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
pub const IDebugOutputCallbacks = dbgeng.IDebugOutputCallbacks;

pub const INFINITE = dbgeng.INFINITE;

pub const S_OK = dbgeng.S_OK;
pub const S_FALSE = dbgeng.S_FALSE;

pub const DEBUG_PROCESS = dbgeng.DEBUG_PROCESS;

// https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/debug-outctl-xxx
pub const DEBUG_OUTCTL_ALL_CLIENTS = dbgeng.DEBUG_OUTCTL_ALL_CLIENTS;
pub const E_NOINTERFACE = dbgeng.E_NOINTERFACE;

pub const DEBUG_ENGOPT_INITIAL_BREAK = dbgeng.DEBUG_ENGOPT_INITIAL_BREAK;

pub const DEBUG_STATUS_NO_CHANGE = dbgeng.DEBUG_STATUS_NO_CHANGE;
pub const DEBUG_STATUS_GO = dbgeng.DEBUG_STATUS_GO;
pub const DEBUG_STATUS_STEP_OVER = dbgeng.DEBUG_STATUS_STEP_OVER;
pub const DEBUG_STATUS_STEP_INTO = dbgeng.DEBUG_STATUS_STEP_INTO;
pub const DEBUG_STATUS_BREAK = dbgeng.DEBUG_STATUS_BREAK;
pub const DEBUG_STATUS_NO_DEBUGGEE = dbgeng.DEBUG_STATUS_NO_DEBUGGEE;
pub const DEBUG_STATUS_STEP_BRANCH = dbgeng.DEBUG_STATUS_STEP_BRANCH;

// Output mask constants.
pub const DEBUG_OUTPUT_NORMAL = dbgeng.DEBUG_OUTPUT_NORMAL;
pub const DEBUG_OUTPUT_ERROR = dbgeng.DEBUG_OUTPUT_ERROR;
pub const DEBUG_OUTPUT_WARNING = dbgeng.DEBUG_OUTPUT_WARNING;
pub const DEBUG_OUTPUT_VERBOSE = dbgeng.DEBUG_OUTPUT_VERBOSE;
pub const DEBUG_OUTPUT_PROMPT = dbgeng.DEBUG_OUTPUT_PROMPT;
pub const DEBUG_OUTPUT_PROMPT_REGISTERS = dbgeng.DEBUG_OUTPUT_PROMPT_REGISTERS;
pub const DEBUG_OUTPUT_EXTENSION_WARNING = dbgeng.DEBUG_OUTPUT_EXTENSION_WARNING;
pub const DEBUG_OUTPUT_DEBUGGEE = dbgeng.DEBUG_OUTPUT_DEBUGGEE;
pub const DEBUG_OUTPUT_DEBUGGEE_PROMPT = dbgeng.DEBUG_OUTPUT_DEBUGGEE_PROMPT;
pub const DEBUG_OUTPUT_SYMBOLS = dbgeng.DEBUG_OUTPUT_SYMBOLS;

pub const DebugCreate = dbgeng.DebugCreate;
