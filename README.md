# zdbgeng
Native Windows debugging tools in Zig, powered by dbgeng.

While reading a [blog series](https://www.timdbg.com/posts/writing-a-debugger-from-scratch-part-1/) on how debuggers are implemented on Windows, I learned that the core engine behind WinDbg is called DbgEng. It exposes a set of APIs through the [IDebugClient interface and related components](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/dbgeng/nn-dbgeng-idebugclient).
I thought it would be fun to try using the C API from Zig to build some debugger tools and see how far I could take it.

## Table of Contents

- [Getting Started](#getting-started)
- [Usage](#usage)
- [Resources](#resources)

## Getting Started

### Prerequisites

- [Zig](https://ziglang.org/) (version 0.14.0 or later)
- [Windows](https://www.microsoft.com/en-us/windows?r=1) (DbgEng is Windows only)

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

## Usage
Right now, zdbgeng is a basic interactive debugger. To debug a program, just pass it as an argument:

```bash
zig build run -- program.exe [program args]
```

This will start the debugger and drop you into the REPL. The debugger will automatically break at the entry point (will make configure this later if needed).
You will have most, (if not all), of the available commands that the DbgEng has. The debugger will automatically wait for events after execution commands, so you can just type `g` and it'll run until the next break like any other debugger

**Example**:
```
zig build run -- program.exe
zdbg> bp `program.zig:8`
zdbg> bl
zdbg> g
```

## Resources

- The original windows debugger [blog series](https://www.timdbg.com/posts/writing-a-debugger-from-scratch-part-1/).
- This [article](https://www.osronline.com/article.cfm^article=559.htm) was helpful in explaining the structure of DbgEng and how its COM interfaces fit together.
- Microsoft [Input and Output](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/using-input-and-output#output-callbacks) callback docs
