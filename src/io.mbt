///| IO operations for reading from stdin

///| This module provides functions to read from stdin

///| Read a line from stdin

///|
/// Returns Some(line) if successful, None if EOF or error
pub fn read_line_from_stdin() -> String? {
  let buffer_size = 4096
  let bytes = Bytes::make(buffer_size, b'\x00')
  let bytes_read = ffi_read_line(bytes, buffer_size)
  if bytes_read <= 0 {
    // EOF or error
    return None
  }

  // Convert bytes to string, removing null terminator and newline
  let result = bytes_to_string(bytes, bytes_read)
  Some(result)
}

///| Read all data from stdin until EOF

///|
/// Returns the complete input as a string
pub fn read_all_stdin() -> String {
  let chunk_size = 8192
  let mut result = ""
  while true {
    let bytes = Bytes::make(chunk_size, b'\x00')
    let bytes_read = ffi_read_stdin(bytes, chunk_size)
    if bytes_read <= 0 {
      break
    }
    result = result + bytes_to_string(bytes, bytes_read)
    if bytes_read < chunk_size {
      break
    }
  }
  result
}

///|
/// Check if stdin has data available (non-blocking)
pub fn has_stdin_data() -> Bool {
  ffi_stdin_has_data() != 0
}

///|
/// Helper function to convert bytes to string
fn bytes_to_string(bytes : Bytes, length : Int) -> String {
  let mut result = ""
  for i = 0; i < length; i = i + 1 {
    let byte = bytes[i]
    // Skip null terminator and stop at newline for read_line
    if byte.to_int() == 0 {
      break
    }
    result = result + Int::unsafe_to_char(byte.to_int()).to_string()
  }
  result
}
