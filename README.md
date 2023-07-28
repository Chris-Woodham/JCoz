# JCoz

JCoz is the world's first causal profiler for Java (and eventually all JVM) programs. It was inspired by [coz](https://github.com/plasma-umass/coz), the original causal profiler.

## Get Started

### Architecture

Currently the JCoz profiler can only be built on x86 machines (in the future we will work on porting the JCoz profiler to aarch64 platforms).

### Dependencies

- [spdlog](https://github.com/gabime/spdlog) (`0.11.0` or higher)
  - `apt-get install libspdlog-dev` for debian/ubuntu
  - `yum install spdlog-devel` for fedora/rhel/centos
- make
- g++

On an ubuntu machine,

```sh
sudo apt install -y make g++ libspdlog-dev
```

You also need a JDK installed on the machine.

*Note* - if you are running JCoz on Ubuntu 18, you will need to clone the `spdlog` GitHub repo and copy some of the include files over to `/usr/local/include` (as `sudo apt install libspdlog-dev` does not install all header files on Ubuntu 18) using:

```sh
git clone https://github.com/gabime/spdlog.git
sudo cp -r $path_to_spdlog/include/. /usr/local/include
```

### Building the native agent

Once all the dependencies have been installed, the native agent is built using make

```sh
# On Ubuntu 22
make clean
make all-22

# On Ubuntu 18 and 20
make clean
male all-18-20
```

This will build a native agent, which can be found in `build-<bits_in_platfrom_architecture>` directory.

## Profiling a Java application

To launch your application with the JCoz profiler, Java's `-agentpath` argument is used (see [Java docs for further info](https://docs.oracle.com/en/java/javase/18/docs/specs/man/java.html#standard-options-for-java)). The command would take the form,

```sh
java -agentpath:pathname[=options] Main
```

### Running the examples

1. You can run the Java application in [JCoz/example/src/simple-single-threaded-example](./example/src/simple-single-thread-example/) using only the required options with the following commands

```sh
cd JCoz/example/src/simple-single-threaded-example
javac Main.java
java -agentpath:$pathToJCoz/JCoz/build-64/liblagent.so=progress-point=LMain:11_pkg=model Main
```

This would set a progress point in line 11 of the class `Main` (in [src/simple-single-threaded-example/Main.java](example/src/simple-single-threaded-example/Main.java)) and any code within the `model` directory would be in the scope for profiling (i.e. [model.Help](example/src/simple-single-thread-example/model/Main.java).

2. You can run the Java application in [JCoz/example/src/simple-multi-threaded-example](./example/src/simple-multi-threaded-example/) using only the required options with the following commands

```sh
cd JCoz/example/src/simple-multi-threaded-example
javac Main.java
java -agentpath:$pathToJCoz/JCoz/build-64/liblagent.so=progress-point=LMain:21_pkg=model Main
```

This would set a progress point in line 21 of the class `Main` (in [src/simple-multi-threaded-example/Main.java](example/src/simple-multi-threaded-example/Main.java)) and any code within the `model` directory would be in the scope for profiling (i.e. [model.FastThread](example/src/simple-multi-threaded-example/model/FastThread.java); [model.SlowThread](example/src/simple-multi-threaded-example/model/SlowThread.java); and [model.Result](example/src/simple-multi-threaded-example/model/Result.java)).

For all the available options, see the [_options_ section below](#cli-options)

For use with Tomcat, the agent path option needs to be added to `CATALINA_OPTS`. If it's not possible to change `CATALINA_OPTS` the program is launched with, it can be appended `CATALINA_OPTS` to using `setenv.sh` place within the tomcat bin, see example below.

  ```bash
  #!/bin/sh

  export CATALINA_OPTS="$CATALINA_OPTS -agentpath:/path/to/libagent.so=progress-point=Ldummy/Main:11_pkg=dummy dummy/Main"
  ```

### Troubleshooting if JCoz does not work

1. Options to agent path are delimited using an underscore `_`
   - And therefore if the value of any of the options contain an underscore, this will result in incorrect parsing
2. Value is associated with an option to the agent using an equals `=`
3. If program crashes immediately, make sure the version of jvm which will run your application is the same as the path to `path_to_java/lib` or `path_to_java/lib/server` in `LD_LIBRARY_PATH/DYLD_LIBRARY_PATH`. It might be that agent is unable to find `libjvm.so`/`libjvm.dylib` library
4. If the program does not have write permissions to the folder it is executed in, it will fail. This is due to the default path of the output and logger file being the current working directory
   - Output file path can be changed using [CLI options](#cli-options)
   - Logger file path can only be changed in [src/globals.h](src/globals.h) (see [agent options](#advanced-agent-options) below) and will require rebuilding the agent
5. JCoz can be run using Java 8, 11 and 17 - but make sure that the java version used when building JCoz is the same as the java (and javac) version used to compile and run your application

### CLI Options

For more details and examples of how the options can be used, see the [readme in examples folder](example/readme.md).

Note:

- `pkg` and `search` options are equivalent and one of the two _must_ be specified
- `search` and `ignore` are delimited by `|` but this is a special character in most shells and needs to be escaped (e.g. in bash `\|`)
- Class specified in `progress-point` _must_ follow the JVM specification class signature conventions, e.g. `java.lang.String` is `Ljava/lang/String`. If experiment has no points hit, this will be due to the progress point not being set.

| Option | Is required? | Default | What does it do? | Example |
|---|:---:|:---:|---|---|
| `pkg` | ✓  if no `search` | ― | Specifies which single package is within scope for Java to profile | java.util |
| `search` | ✓  if no `pkg` | ― | Allows specifying multiple scopes to profile using `\|` as a delimiter | java.util.concurrent\|java.util.stream |
| `ignore` | ✗ | ― | Scopes to ignore when profiling the application using `\|` as a delimiter | java.util.function\|java.util.random |
| `progress-point` | ✓ | ― |  | Lcom/google/Main:12 |
| `logging-level` | ✗ | info | Sets the logging level of profiler's logger. Only those in next column are accepted | trace, debug, info, warn, error, critical, off |
| `output-file` | ✗ | jcoz-output.coz | Specifies path and name of output file. Ensure this is in a writable location. The actual name of the output file will have the time stamp of when the program was started appended to it | /home/ubuntu/profiler-output.coz |
| `warmup` | ✗  | 0 | Amount of time for agent thread to sleep in milliseconds | 5000 |
| `end-to-end` | ✗ | false | NOT RECOMMENDED Sets progress point to be when the application finishes running |  |
| `fix_exp` | ✗  | false | Fixes the experiment length to be `MIN_EXP_TIME` in [globals.h](src/globals.h) | |

### [Advanced] Agent Options

[src/globals.h](src/globals.h) contains constants that control how agent behaves. Changing __any__ of these constant will require __rebuilding the native agent__

| Agent Option | Default Value | Description |
|---|:---:|---|
| `PROFILER_LOG_FILE` | `"profiler_log.txt"` | File path to profiler log. If path is not absolute, it will be treated as relative to directory program is executed in |
| `MIN_EXP_TIME` | 5000 | Minimum experiment time in milliseconds |
| `MAX_EXP_TIME` | 80000 | Maximum experiment time in milliseconds |
| `HITS_TO_INC_EXP_TIME` | 5 | Points hit below this threshold will increase experiment time by `EXP_TIME_FACTOR` |
| `HITS_TO_DEC_EXP_TIME` | 20 | Points hit above this threshold will decrease experiment time by `EXP_TIME_FACTOR` |
| `EXP_TIME_FACTOR` | 2 | Controls how exeperiment time grows exponentially. Min and max experiment time must be selected with this in mind |
| `NUM_STATIC_CALL_FRAMES` | 200 | Maximum number of frames that can be considered for a given experiment. Must be greater than `kMaxFramesToCapture` |
| `kMaxFramesToCapture` | 128 | Maximum number of frames that can be captured in a single sampling. Must be less than `NUM_STATIC_CALL_FRAMES` |
| `kNumCallTraceErrors` | - | __Do NOT change__ Constant based on Asgct kNumCallTraceErrors enum in [stacktraces.h](src/stacktraces.h) |

Note: Asgct is `AsyncGetCallTrace` API for more info on how that works [this blog post](https://foojay.io/today/asyncgetstacktrace-a-better-stack-trace-api-for-the-jvm/) provides an overview of how it works

## Analysing results

### Visualising profiler output

### Interpretation of results

### Accuracy of measuring throughput

- The vast majority of the time JCoz accurately measures the throughput of an application during experiments
  - `throughput (number of progress point hits per unit time) = number progress point hits / effective duration of experiment`
    - `effective duration = experiment duration - total delay` (_where total delay is the total length of pauses inserted during the experiment_)
- However, on a small number of occasions JCoz will produce inaccurate results.
  - JCoz updates the accumulative local_delay for each executing application thread during an experiment and then at the end of the experiment sums these `local_delays` to calculate the `total_delay`
  - Between experiments - the `local_delay` variable for each application thread is reset to 0, in preparation for the next experiment
  - However, if an application thread is blocking throughout the period between experiments and then resumes execution during the next experiment, the `local_delay` will not have been reset and an inaccurate throughput will consequently be calculated

#### Mitigation

- We have implemented a change that means that reduces the frequency of these inaccurate throughput calculations
  - However, as it always possible than an application thread could block for a period of time (and we would not want the profiler interrupting the execution of a program), it is not possible to completely eliminate mistakes when calculating throughput
- Before the causal profile data is plotted by the UI - it is filtered, and any clearly incorrect throughput data is removed
- We enforce a minimum sample size of 30 to plot a graph with the UI (this reduces the likelihood that erroneous throughput values are driving the observed trend)  
