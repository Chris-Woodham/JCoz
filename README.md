[![Join the chat at https://gitter.im/JCoz-profiler/community](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/JCoz-profiler/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# Overview

JCoz is the world's first causal profiler for Java (and eventually all JVM) programs. It was inspired by [coz](https://github.com/plasma-umass/coz), the original causal profiler.

For documentation, including installing, building, and using JCoz, please see our [Wiki page](https://github.com/Decave/JCoz/wiki) page.

## Dependencies

- [spdlog](https://github.com/gabime/spdlog) (`0.11.0` or higher)
  - `apt-get install libspdlog-dev` for debian/ubuntu
  - `yum install spdlog-devel` for fedora/rhel/centos
- make
- jdk, of course

# Getting Started Tutorial

## Build and shakeout

You can drive a basic test use case through the Makefile.

Start by building everything from scratch:

```
make clean
make all
```

This will build a native agent, which can be found in `build-$BITS` directory.

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

If program crashes immediately, make sure the version of jvm which will run your application is the same as the path to `path_to_java/lib` or `path_to_java/lib/server` in `LD_LIBRARY_PATH/DYLD_LIBRARY_PATH`. It might be that agent is unable to find `libjvm.so`/`libjvm.dylib` library.

## Getting a profiling visualisation

Experiment results will be in file `output.coz`.

Open the [coz UI here](https://plasma-umass.org/coz/), and upload the file and review the output.

## Profiling a real application

You should now be in a position to profile a real application. Use the JCozCLI
and capture some samples!

Be aware for that a real sized application there will be lots of code and lots
of experiments that JCoz needs to run. You should plan to keep JCoz running for
some hours to be confident in the results.


## Accuracy of measuring throughput

* The vast majority of the time JCoz accurately measures the throughput of an application during experiments
  * `throughput (number of progress point hits per unit time) = number progress point hits / effective duration of experiment`
	* `effective duration = experiment duration - total delay` (*where total delay is the total length of pauses inserted during the experiment*)
* However, on a small number of occasions JCoz will produce inaccurate results.
	* JCoz updates the accumulative local_delay for each executing application thread during an experiment and then at the end of the experiment sums these `local_delays` to calculate the `total_delay`
	* Between experiments - the `local_delay` variable for each application thread is reset to 0, in preparation for the next experiment
	* However, if an application thread is blocking throughout the period between experiments and then resumes execution during the next experiment, the `local_delay` will not have been reset and an inaccurate throughput will consequently be calculated

**Mitigation:**

* We have implemented a change that means that reduces the frequency of these inaccurate throughput calculations
  * However, as it always possible than an application thread could block for a period of time (and we would not want the profiler interrupting the execution of a program), it is not possible to completely eliminate mistakes when calculating throughput
* Before the causal profile data is plotted by the UI - it is filtered, and any clearly incorrect throughput data is removed
* We enforce a minimum sample size of 30 to plot a graph with the UI (this reduces the likelihood that erroneous throughput values are driving the observed trend)  
