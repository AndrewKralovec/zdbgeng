// NOTE: Following examples from https://www.osronline.com/article.cfm%5Earticle=559.htm
const std = @import("std");
const windows = std.os.windows;
const GUID = @import("./bindings.zig").GUID;

const HRESULT = windows.HRESULT;
const WINAPI = windows.WINAPI;

/// IDebugOutputCallbacks COM interface structures
const IDebugOutputCallbacksVtbl = extern struct {};
