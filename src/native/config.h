#ifndef CONFIG_H
#define CONFIG_H

// Logger level
#include "spdlog/cfg/env.h"
const spdlog::level::level_enum profiler_log_level = spdlog::level::info;

// ---------- PROFILER --------
#define OUTPUT_LOG_FILENAME "/home/ubuntu/jcoz-log.txt"

#define SIGNAL_FREQ 1000000L
// Experiment time in milliseconds
#define MIN_EXP_TIME 5000
#define MAX_EXP_TIME 80000

#define INC_EXP_TIME_THRESHOLD 5
#define DEC_EXP_TIME_THRESHOLD 20

#define NUM_CALL_FRAMES 200

// Unsigned long for how long to wait before starting an experiment
#define PROFILER_WARMUP_TIME 5000000

// ---------- don't know what catetory yet -----------

// Maximum number of frames to store from the stack traces sampled.
// int from globals.h
#define KMAX_FRAMES_TO_CAPTURE 128

// int from stacktraces.h
#define KNUM_CALL_TRACE_ERROS 10

#endif