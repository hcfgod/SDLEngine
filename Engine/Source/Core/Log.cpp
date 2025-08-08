#include "lmpch.h"
#include "Core/Log.h"

#include <filesystem>
#include <chrono>

#include <spdlog/spdlog.h>
#include <spdlog/sinks/stdout_color_sinks.h>
#include <spdlog/sinks/rotating_file_sink.h>
#include <spdlog/async.h>

namespace Limitless {

    bool Log::s_Initialized = false;

    static std::string BuildLogFilePath(const std::string &logsDirectory,
                                        const std::string &applicationName)
    {
        namespace fs = std::filesystem;
        fs::path dir(logsDirectory);
        if (!dir.empty() && !fs::exists(dir)) {
            std::error_code ec;
            fs::create_directories(dir, ec);
        }

        // Name pattern: <AppName>_YYYY-MM-DD.log (rotation numbers appended by sink)
        auto now = std::chrono::system_clock::now();
        std::time_t t = std::chrono::system_clock::to_time_t(now);
        std::tm tm_buf{};
#if defined(_WIN32)
        localtime_s(&tm_buf, &t);
#else
        localtime_r(&t, &tm_buf);
#endif
        char datebuf[16]{};
        std::strftime(datebuf, sizeof(datebuf), "%Y-%m-%d", &tm_buf);

        fs::path fileName = applicationName + std::string("_") + datebuf + ".log";
        return (dir / fileName).string();
    }

    void Log::Init(const std::string &applicationName,
                   const std::string &logsDirectory,
                   std::size_t maxFileSizeBytes,
                   std::size_t maxRotatedFiles)
    {
        if (s_Initialized) return;
        s_Initialized = true;

        // Async thread pool (shared across async loggers)
        // Queue size 8192, 1 background thread. Adjust as needed.
        spdlog::init_thread_pool(8192, 1);

        auto consoleSink = std::make_shared<spdlog::sinks::stdout_color_sink_mt>();
        consoleSink->set_pattern("[%Y-%m-%d %T.%e] [%^%l%$] [%n] %v");

        auto logfile = BuildLogFilePath(logsDirectory, applicationName);
        auto rotatingSink = std::make_shared<spdlog::sinks::rotating_file_sink_mt>(
            logfile, maxFileSizeBytes, maxRotatedFiles
        );
        rotatingSink->set_pattern("[%Y-%m-%d %T.%e] [%l] [%n] %v");

        std::vector<spdlog::sink_ptr> sinks{ consoleSink, rotatingSink };

        // Create two loggers sharing sinks: core (engine) and client (application)
        auto coreLogger = std::make_shared<spdlog::async_logger>(
            "LimitlessCore",
            sinks.begin(), sinks.end(),
            spdlog::thread_pool(),
            spdlog::async_overflow_policy::block
        );
        auto clientLogger = std::make_shared<spdlog::async_logger>(
            applicationName,
            sinks.begin(), sinks.end(),
            spdlog::thread_pool(),
            spdlog::async_overflow_policy::block
        );

        spdlog::register_or_replace(coreLogger);
        spdlog::register_or_replace(clientLogger);
        spdlog::set_default_logger(clientLogger);

        // Levels and flushing
#if defined(LM_DEBUG)
        spdlog::set_level(spdlog::level::trace);
#else
        spdlog::set_level(spdlog::level::info);
#endif
        spdlog::flush_on(spdlog::level::warn);
        spdlog::flush_every(std::chrono::seconds(2));

        spdlog::get("LimitlessCore")->info("Core logger initialized. File: {}", logfile);
        spdlog::get(applicationName)->info("Client logger initialized. File: {}", logfile);
    }

    void Log::Shutdown()
    {
        if (!s_Initialized) return;
        spdlog::get("LimitlessCore")->info("Logger shutting down");
        spdlog::shutdown();
        s_Initialized = false;
    }

    void Log::SetLevel(LogLevel level)
    {
        using spdlog::level::level_enum;
        level_enum spdLevel = spdlog::level::info;
        switch (level) {
            case LogLevel::Trace:    spdLevel = spdlog::level::trace; break;
            case LogLevel::Debug:    spdLevel = spdlog::level::debug; break;
            case LogLevel::Info:     spdLevel = spdlog::level::info; break;
            case LogLevel::Warn:     spdLevel = spdlog::level::warn; break;
            case LogLevel::Error:    spdLevel = spdlog::level::err; break;
            case LogLevel::Critical: spdLevel = spdlog::level::critical; break;
            case LogLevel::Off:      spdLevel = spdlog::level::off; break;
        }
        spdlog::set_level(spdLevel);
    }

    LogLevel Log::GetLevel()
    {
        auto lvl = spdlog::get_level();
        switch (lvl) {
            case spdlog::level::trace:    return LogLevel::Trace;
            case spdlog::level::debug:    return LogLevel::Debug;
            case spdlog::level::info:     return LogLevel::Info;
            case spdlog::level::warn:     return LogLevel::Warn;
            case spdlog::level::err:      return LogLevel::Error;
            case spdlog::level::critical: return LogLevel::Critical;
            case spdlog::level::off:      return LogLevel::Off;
            default:                       return LogLevel::Info;
        }
    }

    spdlog::logger* Log::GetCoreLoggerRaw()
    {
        auto logger = spdlog::get("LimitlessCore");
        return logger ? logger.get() : spdlog::default_logger_raw();
    }

    spdlog::logger* Log::GetClientLoggerRaw()
    {
        return spdlog::default_logger_raw();
    }
}


