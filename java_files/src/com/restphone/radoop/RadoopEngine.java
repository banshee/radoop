package com.restphone.radoop;

import java.io.FileNotFoundException;
import java.io.IOException;

import javax.script.ScriptException;

import org.apache.hadoop.filecache.DistributedCache;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.mapred.JobConf;
import org.apache.hadoop.mapred.Mapper;
import org.apache.hadoop.mapred.Reducer;

/**
 * A RubyEngine specific to Radoop.
 * 
 * @author james
 * 
 */
public class RadoopEngine extends RubyEngine {
	private static final String JRUBY_HADOOP_ENVIRONMENT_RB = "/lib/jruby_hadoop_environment.rb";

	Object rubyRadoopObject;
	Mapper<Object, Object, Object, Object> mapper = null;
	Reducer<Object, Object, Object, Object> reducer = null;

	@SuppressWarnings("unchecked")
	public Mapper<Object, Object, Object, Object> getRubyRadoopObjectAsMapper() {
		if (mapper == null)
			mapper = (Mapper<Object, Object, Object, Object>) callRadoopMethod("get_mapper_interface_implementor");
		return mapper;
	}

	@SuppressWarnings("unchecked")
	public Reducer<Object, Object, Object, Object> getRubyRadoopObjectAsReducer() {
		if (reducer == null)
			reducer = (Reducer<Object, Object, Object, Object>) callRadoopMethod("get_reducer_interface_implementor");
		return reducer;
	}

	RadoopJobConf jobConfiguration;

	public RadoopEngine(JobConf jc) throws FileNotFoundException,
			ScriptException, NoSuchMethodException {
		this((RadoopJobConf) jc);
	}

	public RadoopEngine(RadoopJobConf jc) throws FileNotFoundException,
			ScriptException, NoSuchMethodException {
		jobConfiguration = jc;
		if (jc == null)
			throw new Error("illegal job conf");
		setupJrubyHadoopEnvironment();
		loadMainRadoopScript();
		rubyRadoopObject = eval(jobConfiguration.getMainObjectCreator() + ".new");
	}

	/**
	 * Sends a #configure message to the Ruby configuration object.
	 * 
	 * Normally includes the command-line arguments.
	 * 
	 * @param conf
	 *            Job configuration
	 * @param args
	 *            Command-line arguments
	 * @throws FileNotFoundException
	 * @throws NoSuchMethodException
	 * @throws ScriptException
	 */
	public void configure(RadoopJobConf conf, Object[] args)
			throws FileNotFoundException, NoSuchMethodException,
			ScriptException {
		send(rubyRadoopObject, "configure", conf, args);
	}

	Object callRadoopMethod(String methodName, Object... args) {
		Object result = null;
		try {
			result = send(rubyRadoopObject, methodName, args);
		} catch (FileNotFoundException e) {
		} catch (ScriptException e) {
		} catch (NoSuchMethodException e) {
		}
		return result;
	}

	String distributedCacheArchiveNameStartsWith(String startsWith) {
		String result = null;
		try {
			Path[] archives = DistributedCache
					.getLocalCacheArchives(jobConfiguration);
			if (archives != null) {
				for (Path p : archives) {
					String basename = p.getName();
					if (basename.toString().startsWith(startsWith)) {
						result = p.toString();
					}
				}
			}
		} catch (IOException e) {
			throw new Error(e);
		}
		return result;
	}

	// Return the environment setup file. In the distributed case, it's
	// the archive stored through DistributedCache whose name starts
	// with "radoop_lib." For the executable, it's given in the job
	// configuration.
	String environmentSetupFile() throws IOException {
		String result = distributedCacheArchiveNameStartsWith(jobConfiguration
				.getRadoopDirZip());
		if (result == null) {
			// If result is null, we're running the main script. Get the
			// file from the job config object.
			result = jobConfiguration.getEnvironmentSetupFile();
		} else {
			result += JRUBY_HADOOP_ENVIRONMENT_RB;
		}
		return result;
	}

	void loadMainRadoopScript() throws FileNotFoundException, ScriptException,
			NoSuchMethodException {
		String mainScript = distributedCacheArchiveNameStartsWith(jobConfiguration
				.getMainRubyDirZip());
		if (mainScript == null) {
			String f = jobConfiguration.getRubyFile();
			loadRubyFile(f);
		} else {
			String f = mainScript + "/"
					+ jobConfiguration.getDistributedRubyFile();
			loadRubyFile(f);
		}
	}

	void setupJrubyHadoopEnvironment() throws FileNotFoundException,
			ScriptException, NoSuchMethodException {
		// The script engine starts JRuby without a useful $LOAD_PATH. Call
		// the function that creates the right load path.

		try {
			String envSetupFile = environmentSetupFile();
			loadRubyFile(envSetupFile);
			Object o = callFunction(jobConfiguration
					.getEnvironmentConfigurationObject());
			send(o, "setup_jruby_environment", jobConfiguration);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
}
