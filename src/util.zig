/// Returns the length of a null terminated wide character string.
pub fn wcslen(ptr: [*:0]const u8) usize {
    var len: usize = 0;
    while (ptr[len] != 0) {
        len += 1;
    }
    return len;
}

/// Returns the length of a null terminated byte string.
pub fn bytlen(buff: []const u8) usize {
    var len: usize = 0;
    while (buff[len] != 0) {
        len += 1;
    }
    return len;
}
