#pragma once

#include <string>
#include <memory>

// Pull spdlog for clients via this header only. Clients shouldn't include spdlog directly.
// Public wrapper provides macros and hides direct spdlog usage from clients.
// We include spdlog to support the macros, but the client only needs to include this header.
#include <spdlog/spdlog.h>

#include <spdlog/fmt/ostr.h>

namespace spdlog { class logger; namespace level { enum level_enum : int; } }

namespace Limitless {

    enum class LogLevel {
        Trace,
        Debug,
        Info,
        Warn,
        Error,
        Critical,
        Off
    };

    class Log {
    public:
        // Initialize global async logger with console + rotating file sinks.
        // Safe to call multiple times; subsequent calls are no-ops.
        static void Init(
            const std::string &applicationName = "Limitless",
            const std::string &logsDirectory = "Logs",
            std::size_t maxFileSizeBytes = 10 * 1024 * 1024, // 10 MB
            std::size_t maxRotatedFiles = 5
        );

        // Shutdown logging and stop thread pool.
        static void Shutdown();

        // Runtime level control without exposing spdlog types.
        static void SetLevel(LogLevel level);
        static LogLevel GetLevel();

        // Internal accessors used by macros (raw pointers for SPDLOG_LOGGER_* macros)
        static spdlog::logger* GetCoreLoggerRaw();
        static spdlog::logger* GetClientLoggerRaw();

    private:
        static bool s_Initialized;
    };

    // Platform debug break helper
#if defined(_MSC_VER)
    #define LM_DEBUGBREAK() __debugbreak()
#elif defined(__GNUC__) || defined(__clang__)
    #include <signal.h>
    #define LM_DEBUGBREAK() raise(SIGTRAP)
#else
    #define LM_DEBUGBREAK() ((void)0)
#endif

    // Logger macros (compiled out according to SPDLOG_ACTIVE_LEVEL)
    // Use default logger configured by Log::Init
    // Client (game/app) logger macros
    #define LM_LOG_TRACE(...)    SPDLOG_LOGGER_TRACE(::Limitless::Log::GetClientLoggerRaw(), __VA_ARGS__)
    #define LM_LOG_DEBUG(...)    SPDLOG_LOGGER_DEBUG(::Limitless::Log::GetClientLoggerRaw(), __VA_ARGS__)
    #define LM_LOG_INFO(...)     SPDLOG_LOGGER_INFO(::Limitless::Log::GetClientLoggerRaw(), __VA_ARGS__)
    #define LM_LOG_WARN(...)     SPDLOG_LOGGER_WARN(::Limitless::Log::GetClientLoggerRaw(), __VA_ARGS__)
    #define LM_LOG_ERROR(...)    SPDLOG_LOGGER_ERROR(::Limitless::Log::GetClientLoggerRaw(), __VA_ARGS__)
    #define LM_LOG_CRITICAL(...) SPDLOG_LOGGER_CRITICAL(::Limitless::Log::GetClientLoggerRaw(), __VA_ARGS__)

    // Engine (core) logger macros
    #define LM_CORE_LOG_TRACE(...)    SPDLOG_LOGGER_TRACE(::Limitless::Log::GetCoreLoggerRaw(), __VA_ARGS__)
    #define LM_CORE_LOG_DEBUG(...)    SPDLOG_LOGGER_DEBUG(::Limitless::Log::GetCoreLoggerRaw(), __VA_ARGS__)
    #define LM_CORE_LOG_INFO(...)     SPDLOG_LOGGER_INFO(::Limitless::Log::GetCoreLoggerRaw(), __VA_ARGS__)
    #define LM_CORE_LOG_WARN(...)     SPDLOG_LOGGER_WARN(::Limitless::Log::GetCoreLoggerRaw(), __VA_ARGS__)
    #define LM_CORE_LOG_ERROR(...)    SPDLOG_LOGGER_ERROR(::Limitless::Log::GetCoreLoggerRaw(), __VA_ARGS__)
    #define LM_CORE_LOG_CRITICAL(...) SPDLOG_LOGGER_CRITICAL(::Limitless::Log::GetCoreLoggerRaw(), __VA_ARGS__)

    // Assertion macros that log with context and break in debug builds
    #if defined(LM_DEBUG)
        #define LM_ASSERT(cond)                                                         \
            do {                                                                        \
                if (!(cond)) {                                                          \
                    LM_CORE_LOG_CRITICAL("Assertion failed: {} | {}:{}", #cond, __FILE__, __LINE__); \
                    LM_DEBUGBREAK();                                                    \
                }                                                                       \
            } while (0)
        #define LM_ASSERT_MSG(cond, fmt, ...)                                           \
            do {                                                                        \
                if (!(cond)) {                                                          \
                    LM_CORE_LOG_CRITICAL("Assertion failed: {} | {}:{}", #cond, __FILE__, __LINE__); \
                    LM_CORE_LOG_CRITICAL(fmt, ##__VA_ARGS__);                                \
                    LM_DEBUGBREAK();                                                    \
                }                                                                       \
            } while (0)
    #else
        #define LM_ASSERT(cond) do { (void)sizeof(cond); } while(0)
        #define LM_ASSERT_MSG(cond, fmt, ...) do { (void)sizeof(cond); } while(0)
    #endif
}


