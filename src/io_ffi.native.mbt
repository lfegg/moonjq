///| FFI implementations for native backend

///|
/// This file is only compiled for native backend

// External C functions for stdin operations
// Use #borrow to indicate C function does not take ownership
#borrow(buf)
extern "C" fn ffi_read_line(buf : Bytes, size : Int) -> Int = "fgets_wrapper"

///|
#borrow(buf)
extern "C" fn ffi_read_stdin(buf : Bytes, size : Int) -> Int = "read_stdin_wrapper"

///|
extern "C" fn ffi_stdin_has_data() -> Int = "stdin_has_data"
