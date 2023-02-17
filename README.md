[![Join the chat at https://gitter.im/JCoz-profiler/community](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/JCoz-profiler/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# JCoz

JCoz is the world's first causal profiler for Java (and eventually all JVM) programs. It was inspired by [coz](https://github.com/plasma-umass/coz), the original causal profiler.

## Get Started

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

Note: Ubuntu 22 is currently not supported as a symbol lookup error (de-mangled symbol: `fmt::v8::detail::dragonbox::decimal_fp<float>`) is thrown. JCoz has been tested on Ubuntu 20 and 18

### Building the native agent

Once all the dependencies have been installed, the native is built using make

```sh
make clean
make all
```

This will build a native agent, which can be found in `build-<bits_in_platfrom_architecture>` directory.

### Profiling a Java application

To launch your application with the JCoz profiler, Java's `-agentpath` argument is used (see [Java docs for further info](https://docs.oracle.com/en/java/javase/18/docs/specs/man/java.html#standard-options-for-java)). The command would take the form,

```sh
java -agentpath:pathname[=options] Main
```

Using the Java application in the [example folder](example/) and only specifying the required options, the command would be,

```sh
user@ubuntu:~/Jcoz/example/src $ java -agentpath:/path/to/libagent.so=progress-point=Ldummy/Main:11_pkg=dummy dummy/Main
```

This would set a progress point in line 11 of the class `Main` in the package `dummy` (in [src/dummy/Main.java](example/src/dummy/Main.java)) and any code within `src/dummy` would be in the scope for profiling, i.e. both [dummy.Main](example/src/dummy/Main.java) and [dummy.nested.Help](example/src/dummy/nested/Help.java).

For all the available options, see the [_options_ section below](#options).

Note:

1. Options to agent path are delimited using an underscore `_`
   - If the value of any of the options contain an underscore, this will result in incorrect parsing
2. Value is associated with an option to the agent using an equals `=`
3. If program crashes immediately, make sure the version of jvm which will run your application is the same as the path to `path_to_java/lib` or `path_to_java/lib/server` in `LD_LIBRARY_PATH/DYLD_LIBRARY_PATH`. It might be that agent is unable to find `libjvm.so`/`libjvm.dylib` library
4. For use in conjunction servlet such as tomcat, see [readme in example folder](example/readme.md) for details

#### Options

For more details and examples of how the options can be used, see the [readme in examples folder](example/readme.md).

Note:

- `pkg` and `search` options are equivalent and one of the two _must_ be specified
- `search` and `ignore` are delimited by `|` but this is a special character in most shells and needs to be escaped (e.g. in bash `\|`)
- Class specified in `progress-point` _must_ follow the JVM specification class signature conventions, e.g. `java.lang.String` is `Ljava/lang/String`. If experiment has no points hit, this will be due to the progress point not being set.

| Option | Is required? | Default | What does it do? | Example |
|---|:---:|:---:|---|---|
| `pkg` | ✓  if no `search` | ― | Specifies which single package is within scope for Java to profile | java.util |
| `search` | ✓  if no `pkg` | ― | Allows specifying multiple scopes to profile using `|` as a delimiter | java.util.concurrent\|java.util.stream |
| `ignore` | ✗ | ― | Scopes to ignore when profiling the application using `|` as a delimiter | java.util.function\|java.util.random |
| `progress-point` | ✓ | ― |  | Lcom/google/Main:12 |
| `logging-level` | ✗ | info | Sets the logging level of profiler's logger. Only those in next column are accepted | trace, debug, info, warn, error, critical, off |
| `output-file` | ✗ | jcoz-output.coz | Specifies path and name of output file. Ensure this is in a writable location. The actual name of the output file will have the time stamp of when the program was started appended to it | /home/ubuntu/profiler-output.coz |
| `warmup` | ✗  | 0 | Amount of time for agent thread to sleep in milliseconds | 5000 |
| `end-to-end` | ✗ | false | NOT RECOMMENDED Sets progress point to be when the application finishes running |  |
| `fix_exp` | ✗  | false | Fixes the experiment length to be `MIN_EXP_TIME` in [globals.h](src/globals.h) | |

## Getting a profiling visualisation

Experiment results will be in file `output.coz`.

Open the [coz UI here](https://plasma-umass.org/coz/), and upload the file and review the output.

## Profiling a real application

You should now be in a position to profile a real application. Use the JCozCLI
and capture some samples!

Be aware for that a real sized application there will be lots of code and lots
of experiments that JCoz needs to run. You should plan to keep JCoz running for
some hours to be confident in the results.

