// C FFI implementation for stdin reading
#include <stdio.h>
#include <string.h>
#include <errno.h>

#ifdef _WIN32
#include <windows.h>
#include <io.h>
#include <fcntl.h>
#else
#include <unistd.h>
#include <sys/select.h>
#endif

// Wrapper for fgets to read a line from stdin
// Returns the length of the string read (including newline if present)
// Returns -1 on error or EOF
int fgets_wrapper(char* buf, int size) {
    if (buf == NULL || size <= 0) {
        return -1;
    }
    
    if (fgets(buf, size, stdin) == NULL) {
        // EOF or error
        return -1;
    }
    
    // Return the length of the string
    return (int)strlen(buf);
}

// Read data from stdin
// Returns the number of bytes read, or -1 on error
int read_stdin_wrapper(char* buf, int size) {
    if (buf == NULL || size <= 0) {
        return -1;
    }
    
    size_t bytes_read = fread(buf, 1, size, stdin);
    
    if (bytes_read == 0) {
        if (feof(stdin)) {
            return 0;  // EOF reached
        }
        if (ferror(stdin)) {
            return -1;  // Error occurred
        }
    }
    
    return (int)bytes_read;
}

// Check if stdin has data available (non-blocking check)
// Returns 1 if data is available, 0 if not, -1 on error
int stdin_has_data() {
#ifdef _WIN32
    // On Windows, check if stdin is a pipe or console
    HANDLE hStdin = GetStdHandle(STD_INPUT_HANDLE);
    DWORD mode;
    
    if (GetConsoleMode(hStdin, &mode)) {
        // It's a console, check if there are input events
        DWORD events;
        if (!GetNumberOfConsoleInputEvents(hStdin, &events)) {
            return -1;
        }
        return events > 0 ? 1 : 0;
    } else {
        // It's a pipe or file, use PeekNamedPipe
        DWORD bytesAvail;
        if (!PeekNamedPipe(hStdin, NULL, 0, NULL, &bytesAvail, NULL)) {
            return -1;
        }
        return bytesAvail > 0 ? 1 : 0;
    }
#else
    // Unix/Linux: use select with timeout 0
    fd_set readfds;
    struct timeval tv;
    
    FD_ZERO(&readfds);
    FD_SET(STDIN_FILENO, &readfds);
    
    tv.tv_sec = 0;
    tv.tv_usec = 0;
    
    int result = select(STDIN_FILENO + 1, &readfds, NULL, NULL, &tv);
    
    if (result < 0) {
        return -1;  // Error
    }
    
    return result > 0 ? 1 : 0;
#endif
}
