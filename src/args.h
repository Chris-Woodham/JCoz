#ifndef JCOZ_ARGS_H
#define JCOZ_ARGS_H

#include <string>
#include <iostream>

#include "spdlog/spdlog.h"

enum profiler_option
{
  _unknown,
  _search_scopes,
  _ignored_scopes,
  _progress_point,
  _end_to_end,
  _warmup,
  _fix_exp,
  _logging_level,
};

namespace agent_args
{
  profiler_option from_string(std::string &option)
  {
    if (option == "pkg" || option == "package" || option == "search") return _search_scopes;
    if (option == "ignore") return _ignored_scopes;
    if (option == "progress-point") return _progress_point;
    if (option == "end-to-end") return _end_to_end;
    if (option == "warmup") return _warmup;
    if (option == "fix-exp") return _fix_exp;
    if (option == "logging-level") return _logging_level;

    return _unknown;
  }

  void print_usage()
  {
    std::cout
      << "usage: java -agentpath:<absolute_path_to_agent>="
      << "pkg=<package_name>_"
      << "progress-point=<class:line_no>_"
      << "end-to-end (optional)_"
      << "warmup=<warmup_time_ms> (optional - default 5000 ms)"
      << std::endl;
  }

  void report_error(const char *message)
  {
    std::cerr << message << std::endl;
    print_usage();
    exit(1);
  }

  spdlog::level::level_enum parse_logging_level(std::string logging_level_input) {
      switch (logging_level_input.front())
      {
      case 't':
          if (logging_level_input == "trace")
              return spdlog::level::trace;
          break;
      case 'd':
          if (logging_level_input == "debug")
              return spdlog::level::debug;
          break;
      case 'i':
          if (logging_level_input == "info")
              return spdlog::level::info;
          break;
      case 'w':
          if (logging_level_input == "warn")
              return spdlog::level::warn;
          break;
      case 'e':
          if (logging_level_input == "error")
              return spdlog::level::err;
          break;
      case 'c':
          if (logging_level_input == "critical")
              return spdlog::level::critical;
          break;
      case 'o':
          if (logging_level_input == "off")
              return spdlog::level::off;
          break;
      default:
          agent_args::report_error(fmt::format("Invalid logging level passed as input: {}", logging_level_input).c_str());
      }
      agent_args::report_error(fmt::format("Invalid logging level passed as input: {}", logging_level_input).c_str());
  }
} // namespace agent_args

#endif //JCOZ_ARGS_H
