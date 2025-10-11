// Error Handler header
#ifndef ERROR_HANDLER_H
#define ERROR_HANDLER_H
#include "raylib.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

typedef enum {
    ERROR_NONE = 0x0000,
    ERROR_FILE_NOT_FOUND = 0x0001,
    ERROR_FILE_READ_FAILED = 0x0002,
    ERROR_FILE_WRITE_FAILED = 0x0003,
    ERROR_MEMORY_ALLOCATION_FAILED = 0x0004,
    ERROR_RENDERING_FAILED = 0x0005,
    ERROR_INPUT_FAILED = 0x0006,
    ERROR_NETWORK_FAILED = 0x0007,
    ERROR_DISK_FAILED = 0x0008,
    ERROR_FATAL = 0x0009,
    ERROR_UNHANDLED_EXCEPTION = 0x000A,
    ERROR_INVALID_ARGUMENT = 0x000B,
    ERROR_OUT_OF_BOUNDS = 0x000C,

    ERROR_UNKNOWN = 0xFFFF
} ErrorCode;

// Error handler structure
typedef struct {
    ErrorCode lastError;
    char lastErrorMessage[256];
} ErrorHandler;

// Global error handler instance
extern ErrorHandler g_errorHandler;
// Error handler functions
void InitErrorHandler(void);
void SetError(ErrorCode code, const char* message);
void ClearError(void);
bool HasError(void);
void PrintLastError(void);
const char* GetErrorMessage(ErrorCode code);
void FatalError(const char* message);
void HandleError(ErrorCode code, const char* message);
void CloseErrorHandler(void);
#endif // ERROR_HANDLER_H