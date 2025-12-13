# zdbgeng
Native Windows debugging tools in Zig, powered by dbgeng.

While reading a [blog series](https://www.timdbg.com/posts/writing-a-debugger-from-scratch-part-1/) on how debuggers are implemented on Windows, I learned that the core engine behind WinDbg is called DbgEng. It exposes a set of APIs through the IDebugClient interface and related components.
I thought it would be fun to try using the C API from Zig to build some debugger tools and see how far I could take it.

## Table of Contents

- [Getting Started](#getting-started)
- [Resources](#resources)

## Getting Started

### Prerequisites

- [Zig](https://ziglang.org/) (version 0.14.0 or later)

### Building

To build the project, use the following command

```bash
zig build
```

### Testing

To run the project tests

```bash
zig build test
```

## Resources

- The original windows debugger [blog series](https://www.timdbg.com/posts/writing-a-debugger-from-scratch-part-1/).
- This [article](https://www.osronline.com/article.cfm^article=559.htm) was helpful in explaining the structure of DbgEng and how its COM interfaces fit together.
