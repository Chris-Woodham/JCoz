#ifndef JCOZ_ARGS_H
#define JCOZ_ARGS_H

#include <string>
#include <iostream>
#include <iomanip>
#include <ctime>

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
  _output_file,
};

namespace agent_args
{
  profiler_option from_string(std::string &option)
  {
    if (option == "pkg" || option == "search")
      return _search_scopes;
    if (option == "ignore")
      return _ignored_scopes;
    if (option == "progress-point")
      return _progress_point;
    if (option == "end-to-end")
      return _end_to_end;
    if (option == "warmup")
      return _warmup;
    if (option == "fix-exp")
      return _fix_exp;
    if (option == "logging-level")
      return _logging_level;
    if (option == "output-file")
      return _output_file;

    return _unknown;
  }

  void print_usage()
  {
    std::cout
        << "usage: java -agentpath:<absolute_path_to_agent>="
        << "pkg=<package_name>_"
        << "search=<package_name>|<another_package_name> (optional if pkg is specified)"
        << "progress-point=<class:line_no>_"
        << "ignore=<package_name>|<another_package_name> (optional)"
        << "end-to-end (optional)_"
        << "fix-exp (optional)_"
        << "warmup=<warmup_time_ms> (optional - default 0 ms)"
        << "logging-level=<desired_logging_level> (optional - default info)"
        << "output-file=<output_filename> (optional - default jcoz-output.csv)"
        << "\n"
        << "progress-point class MUST follow JVM spec class signature conventions"
        << "e.g. java.lang.String has the signature Ljava/lang/String"
        << std::endl;
  }

  void report_error(const char *message)
  {
    std::cerr << message << std::endl;
    print_usage();
    exit(1);
  }

  spdlog::level::level_enum parse_logging_level(std::string logging_level_input)
  {
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

    return spdlog::level::off; // UNREACHABLE
  }

  void set_output_file(std::string output_string_from_command_line)
  {
    auto c_time = std::time(nullptr);
    auto current_time = *std::localtime(&c_time);
    std::stringstream output_stringstream;
    auto position = output_string_from_command_line.find('.');
    if (position != std::string::npos)
    {
      output_stringstream << output_string_from_command_line.substr(0, position) << std::put_time(&current_time, "-%d-%m-%Y-%H-%M-%S") << ".csv";
    }
    else
    {
      output_stringstream << output_string_from_command_line << std::put_time(&current_time, "-%d-%m-%Y-%H-%M-%S") << ".csv";
    }
    kOutputFile = output_stringstream.str();
  }

} // namespace agent_args

#endif // JCOZ_ARGS_H
