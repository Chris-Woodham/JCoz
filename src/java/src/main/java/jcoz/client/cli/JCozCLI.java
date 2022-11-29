/*
 * This file is part of JCoz.
 *
 * JCoz is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * JCoz is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with JCoz.  If not, see <https://www.gnu.org/licenses/>.
 *
 * This file has been modified from lightweight-java-profiler
 * (https://github.com/dcapwell/lightweight-java-profiler). See APACHE_LICENSE for
 * a copy of the license that was included with that original work.
 */
package jcoz.client.cli;

import com.sun.tools.attach.VirtualMachine;
import com.sun.tools.attach.VirtualMachineDescriptor;
import jcoz.profile.Experiment;
import jcoz.profile.Profile;
import jcoz.service.JCozException;
import jcoz.service.VirtualMachineConnectionException;
import org.apache.commons.cli.*;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * @author matt
 */
public class JCozCLI {

    private static final Logger logger = LoggerFactory.getLogger(JCozCLI.class);

    public static void main(String[] args) throws ParseException, VirtualMachineConnectionException, JCozException, InterruptedException {
        Options ops = new Options();

        Option ppClassOption = new Option("c", "ppClass", true, "Class of ProgressPoint");
        ppClassOption.setRequired(true);
        ops.addOption(ppClassOption);

        Option ppLineNoOption = new Option("l", "ppLineNo", true, "Line number of progress point");
        ppLineNoOption.setRequired(true);
        ops.addOption(ppLineNoOption);

        Option pidOption = new Option("p", "pid", true, "ProcessID to jcoz.profile");
        pidOption.setRequired(true);
        ops.addOption(pidOption);

        Option scopeOption = new Option("s", "scope", true, "scope to jcoz.profile (package)");
        scopeOption.setRequired(true);
        ops.addOption(scopeOption);

        Option remoteHostOption = new Option("h", "host", true, "Remote hostname containing JVM process to profile");
        remoteHostOption.setRequired(false);
        ops.addOption(remoteHostOption);

        Option existingProfileOption = new Option("e", "existingProfile", true, "Name of .coz file to load existing profile from");
        remoteHostOption.setRequired(false);
        ops.addOption(existingProfileOption);

        CommandLineParser parser = new DefaultParser();
        CommandLine cl = parser.parse(ops, args);
        String ppClass = cl.getOptionValue('c');
        String scopePkg = cl.getOptionValue('s');
        int ppLineNo = -1;
        int pid = -1;
        try {
            ppLineNo = Integer.parseInt(cl.getOptionValue('l'));
        } catch (NumberFormatException e) {
            logger.error("Invalid Line Number: {}", cl.getOptionValue('l'));
            System.exit(-1);
        }
        try {
            pid = Integer.parseInt(cl.getOptionValue('p'));
        } catch (NumberFormatException e) {
            logger.error("Invalid pid: {}", cl.getOptionValue('l'));
            System.exit(-1);
        }

        String remoteHost = cl.getOptionValue('h');
        boolean isRemote = remoteHost != null && !remoteHost.equals("");
        if (isRemote) {
            logger.info("Connecting to remote host {}", remoteHost);
            try {
                String existingProfileName = cl.getOptionValue("e");
                Profile profile = new Profile(remoteHost, existingProfileName);
                final RemoteServiceWrapper remoteService = new RemoteServiceWrapper(remoteHost);
                TargetProcessInterface profiledClient = remoteService.attachToProcess(pid);
                profiledClient.setProgressPoint(ppClass, ppLineNo);
                profiledClient.setScope(scopePkg);
                profiledClient.startProfiling();

                while (true) {
                    // Sleep for 2 seconds
                    Thread.sleep(2000);

                    List<Experiment> experiments = profiledClient.getProfilerOutput();
                    profile.addExperiments(experiments);
                }
            } catch (JCozException e) {
                StringWriter stringWriter = new StringWriter();
                e.printStackTrace(new PrintWriter(stringWriter));
                logger.error("Unable to connect to target process, stacktrace: {}", stringWriter);
            }
        } else {
            logger.info("Connecting to localhost");
            VirtualMachineDescriptor descriptor = null;
            for (VirtualMachineDescriptor vmDesc : VirtualMachine.list()) {
                if (vmDesc.id().equals(Integer.toString(pid))) {
                    descriptor = vmDesc;
                    break;
                }
            }
            if (descriptor == null) {
                logger.error("Could not find java process with pid: {}", pid);
                return;
            }

            final LocalProcessWrapper wrapper = new LocalProcessWrapper(descriptor);
            //catch SIGINT and end profiling
            Runtime.getRuntime().addShutdownHook(new Thread(() -> {
                try {
                    logger.debug("Caught shutdown hook, ending profiling.");
                    wrapper.endProfiling();
                    System.exit(0);
                } catch (JCozException e) {
                    // we are dying, do nothing
                }
            }));
            wrapper.setProgressPoint(ppClass, ppLineNo);
            wrapper.setScope(scopePkg);
            wrapper.startProfiling();
            while (true) {
                for (Experiment e : wrapper.getProfilerOutput()) {
                    logger.info("Experiment: {}", e);
                }
                Thread.sleep(1000);
            }
        }
    }
}
