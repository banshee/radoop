package com.restphone.radoop;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.conf.Configured;
import org.apache.hadoop.mapred.JobClient;
import org.apache.hadoop.util.Tool;
import org.apache.hadoop.util.ToolRunner;

/**
 * Implements a JRuby environment for Hadoop.
 * <p>
 * Normally you start radoop jobs using the JRuby script 'radoop'. You don't use
 * the Java classes directly.
 * 
 * @author James Moore (james@restphone.com)
 */
public class Radoop extends Configured implements Tool {
	private static final String JRUBY_HOME = "jruby.home";

	/**
	 * @param conf
	 *            The Configuration object for this job
	 */
	public Radoop(Configuration conf) {
		super(conf);
	}

	/**
	 * Starts a Radoop job.
	 * 
	 * @param args
	 *            Command-line arguments
	 */
	public static void main(String[] args) throws Exception {
		RadoopJobConf radoopConf = new RadoopJobConf(Radoop.class);

		int res = ToolRunner.run(radoopConf, new Radoop(radoopConf), args);

		System.exit(res);
	}

	/**
	 * Starts a Radoop job.
	 * 
	 * @param args
	 *            Command-line arguments
	 */
	public static void ruby_main(String[] args) throws Exception {
		RadoopJobConf radoopConf = new RadoopJobConf(Radoop.class);

		int res = ToolRunner.run(radoopConf, new Radoop(radoopConf), args);

		System.exit(res);
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see org.apache.hadoop.util.Tool#run(java.lang.String[])
	 */
	@Override
	public int run(String[] args) throws Exception {
		RadoopJobConf conf = (RadoopJobConf) getConf();

		setupJrubyHome(conf);

		// Make sure radoop.home is set
		if (conf.getRadoopHome() == null)
			throw new Error("radoop.home must be set");

		// Create and configure the Ruby engine
		RadoopEngine radoopRubyEngine = new RadoopEngine(conf);
		radoopRubyEngine.configure(conf, args);

		JobClient.runJob(conf);

		return 0;
	}

	/**
	 * Ensure jruby.home is set correctly.
	 * 
	 * @param conf
	 *            The RadoopJobConf for this job
	 */
	void setupJrubyHome(RadoopJobConf conf) {
		// Make sure that java home gets passed through from the hadoop
		// configuration
		String systemJrubyHome = System.getProperty(JRUBY_HOME);
		if (systemJrubyHome == null)
			System.setProperty(JRUBY_HOME, conf.get(JRUBY_HOME));

		if (System.getProperty(JRUBY_HOME) == null)
			throw new Error(JRUBY_HOME + " must be set");
	}
}
