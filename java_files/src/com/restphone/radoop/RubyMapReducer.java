package com.restphone.radoop;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.Iterator;

import javax.script.ScriptException;

import org.apache.hadoop.mapred.JobConf;
import org.apache.hadoop.mapred.MapReduceBase;
import org.apache.hadoop.mapred.Mapper;
import org.apache.hadoop.mapred.OutputCollector;
import org.apache.hadoop.mapred.Reducer;
import org.apache.hadoop.mapred.Reporter;

/**
 * The interface to the map/reduce methods in Ruby.
 */

public class RubyMapReducer extends MapReduceBase implements
		Mapper<Object, Object, Object, Object>,
		Reducer<Object, Object, Object, Object> {
	RadoopEngine rubyEngine;
	JobConf jobConfiguration;

	public RubyMapReducer() {
	}

	public void configure(RadoopJobConf jc) {
		jobConfiguration = jc;
		configureRadoop();
	}

	public void configure(JobConf jc) {
		configure(new RadoopJobConf(jc));
	}

	void configureRadoop() {
		sendRadoopMessage("job_conf=", jobConfiguration);
		sendRadoopMessage("start_map_reduce");
	}

	@Override
	public void map(Object key, Object value,
			OutputCollector<Object, Object> output, Reporter reporter)
			throws IOException {
		getRadoopEngine().getRubyRadoopObjectAsMapper().map(key, value, output,
				reporter);
	}

	@Override
	public void reduce(Object key, Iterator<Object> values,
			OutputCollector<Object, Object> output, Reporter reporter)
			throws IOException {
		getRadoopEngine().getRubyRadoopObjectAsReducer().reduce(key, values,
				output, reporter);
	}

	RadoopEngine getRadoopEngine() {
		Exception gotException = null;

		if (rubyEngine == null) {
			try {
				rubyEngine = new RadoopEngine((RadoopJobConf) jobConfiguration);
			} catch (FileNotFoundException e) {
				gotException = e;
			} catch (ScriptException e) {
				gotException = e;
			} catch (NoSuchMethodException e) {
				gotException = e;
			}
			if (gotException != null)
				throw new RubyError(gotException.getLocalizedMessage());
		}

		return rubyEngine;
	}

	/**
	 * Send a message to the main Radoop object.
	 * 
	 * @param message
	 *            The message to send
	 * @param args
	 *            Arguments for the message
	 */
	void sendRadoopMessage(final String message, Object... args) {
		getRadoopEngine().callRadoopMethod(message, args);
	}
}
