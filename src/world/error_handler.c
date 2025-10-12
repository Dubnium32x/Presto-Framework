// Error handling functions for the game
#include "error_handler.h" 
#include "raylib.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Global error handler instance definition
ErrorHandler g_errorHandler;

void InitErrorHandler(void) {
    g_errorHandler.lastError = ERROR_NONE;
    memset(g_errorHandler.lastErrorMessage, 0, sizeof(g_errorHandler.lastErrorMessage));
}

void SetError(ErrorCode code, const char* message) {
    g_errorHandler.lastError = code;
    strncpy(g_errorHandler.lastErrorMessage, message, sizeof(g_errorHandler.lastErrorMessage) - 1);
    g_errorHandler.lastErrorMessage[sizeof(g_errorHandler.lastErrorMessage) - 1] = '\0'; // Ensure null-termination
}

void ClearError(void) {
    g_errorHandler.lastError = ERROR_NONE;
    memset(g_errorHandler.lastErrorMessage, 0, sizeof(g_errorHandler.lastErrorMessage));
}

bool HasError(void) {
    return g_errorHandler.lastError != ERROR_NONE;
}

void PrintLastError(void) {
    if (HasError()) {
        printf("Error [%04X]: %s\n", g_errorHandler.lastError, g_errorHandler.lastErrorMessage);
    } else {
        printf("No errors.\n");
    }
}

const char* GetErrorMessage(ErrorCode code) {
    switch (code) {
        case ERROR_NONE: return "No error.";
        case ERROR_FILE_NOT_FOUND: return "File not found.";
        case ERROR_FILE_READ_FAILED: return "File read failed.";
        case ERROR_FILE_WRITE_FAILED: return "File write failed.";
        case ERROR_MEMORY_ALLOCATION_FAILED: return "Memory allocation failed.";
        case ERROR_RENDERING_FAILED: return "Rendering failed.";
        case ERROR_INPUT_FAILED: return "Input handling failed.";
        case ERROR_NETWORK_FAILED: return "Network operation failed.";
        case ERROR_DISK_FAILED: return "Disk operation failed.";
        case ERROR_FATAL: return "Fatal error occurred.";
        case ERROR_UNHANDLED_EXCEPTION: return "Unhandled exception occurred.";
        case ERROR_INVALID_ARGUMENT: return "Invalid argument provided.";
        case ERROR_OUT_OF_BOUNDS: return "Out of bounds access.";
        case ERROR_UNKNOWN: return "Unknown error.";
        default: return "Unrecognized error code.";
    }
}

void FatalError(const char* message) {
    SetError(ERROR_FATAL, message);
    PrintLastError();
    // Optionally, you could add more cleanup code here
    CloseWindow(); // Close Raylib window if open
}

void HandleError(ErrorCode code, const char* message) {
    SetError(code, message);
    PrintLastError();
    // Depending on the severity, you might want to exit or recover
    if (code == ERROR_FATAL || code == ERROR_UNHANDLED_EXCEPTION) {
        FatalError(message);
    }
}

void CloseErrorHandler(void) {
    // Any necessary cleanup can be done here
    ClearError();
}

