///| FFI stub implementations for wasm-gc backend

///|
/// This file is only compiled for wasm-gc backend

// Stub implementations for WASM (stdin not available in WASM by default)
fn ffi_read_line(_buf : Bytes, _size : Int) -> Int {
  -1 // EOF - WASM doesn't support stdin
}

///|
fn ffi_read_stdin(_buf : Bytes, _size : Int) -> Int {
  -1 // EOF - WASM doesn't support stdin
}

///|
fn ffi_stdin_has_data() -> Int {
  0 // No data available in WASM
}
