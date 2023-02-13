[![Join the chat at https://gitter.im/JCoz-profiler/community](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/JCoz-profiler/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# JCoz

JCoz is the world's first causal profiler for Java (and eventually all JVM) programs. It was inspired by [coz](https://github.com/plasma-umass/coz), the original causal profiler.

## Get Started

### Dependencies

- [spdlog](https://github.com/gabime/spdlog) (`0.11.0` or higher)
  - `apt-get install libspdlog-dev` for debian/ubuntu
  - `yum install spdlog-devel` for fedora/rhel/centos
- make
- jdk, of course

Constraints on platform???

What has it been tested on so far

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

Using the Java application in the [example folder](example/) and only specifying the required options, the command would be

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
4. See example folder for tomcat case

The `-agentpath` argument has the following format:

```
-agentpath:/path/to/liblagent=progress-point=<progress point class fqn>:<line number>
    _search=<search scope name 1>|<search scope name 2>|...|<scope to ignore N>
    _ignore=<scope to ignore 1>|<scope to ignore 2>|...|<scope to ignore M> 
```

For example, to run profiler on progress point `com.example.MyClass:42`, search scope `java.util` and scopes `java.util.concurrent` and `java.util.stream`, the argument will be

```
-agentpath:/path/to/liblagent=progress-point=Lcom/example/MyClass:42_search=java.util_ignore=java.util.concurrent|java.util.stream
```

#### Options

Note: `pkg` and `search` options are equivalent and one of the two _must_ be specified

CHECK THIS

| Option | Is required? | Default | What does it do? | Example |
|---|:---:|:---:|---|---|
| `pkg` | &#10003; if no `search` | &#8213; | Specifies which single package is within scope for Java to profile | java.util |
| `search` | &#10003; if no `pkg` | &#8213; | Allows specifying multiple scopes to profile using `\|` as a delimiter | java.util.concurrent\|java.util.stream |
| `ignore` | &#10007; | &#8213; | Scopes to ignore when profiling the application using `\|` as a delimiter | java.util.function\|java.util.random |
| `progress-point` | &#10003; | &#8213; |  | Lcom/google/Main:12 |
| `logging-level` | &#10007; | info | Sets the logging level of profiler's logger. Only those in next column are accepted | trace, debug, info, warn, error, critical, off |
| `end-to-end` | &#10007; | false | NOT RECOMMENDED Sets progress point to be when the application finishes running |  |
| `output-file` | &#10007; | jcoz-output.coz | Specifies path and name of output file. Ensure this is in a writable location | /home/ubuntu/profiler-output.coz |
| `warmup` | &#10007; | 5000 | Amount of time for agent thread to sleep in milliseconds IMPLMENTATION COMMENTED OUT | 120000 |

## Getting a profiling visualisation

Experiment results will be in file `output.coz`.

Open the [coz UI here](https://plasma-umass.org/coz/), and upload the file and review the output.

## Profiling a real application

You should now be in a position to profile a real application. Use the JCozCLI
and capture some samples!

Be aware for that a real sized application there will be lots of code and lots
of experiments that JCoz needs to run. You should plan to keep JCoz running for
some hours to be confident in the results.
