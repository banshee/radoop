package com.restphone.radoop;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.mapred.JobConf;

public class RadoopJobConf extends JobConf {

	/**
	 * Construct a map/reduce job configuration.
	 * 
	 * @param conf
	 *            a Configuration whose settings will be inherited.
	 * @param exampleClass
	 *            a class whose containing jar is used as the job's jar.
	 */
	public RadoopJobConf(Configuration conf, Class<?> exampleClass) {
		super(conf, exampleClass);
	}

	public RadoopJobConf(Class<?> exampleClass) {
		super(exampleClass);
	}

	public RadoopJobConf(Configuration conf) {
		super(conf);
	}

	public String getRubyGems() {
		return get("mapred.rubyGems");
	}

	public void setRubyGems(String s) {
		set("mapred.rubyGems", s);
	}

	public String getMainObjectCreator() {
		return get("radoop.class");
	}

	public void setMainObjectCreator(String s) {
		set("radoop.class", s);
	}

	public String getEnvironmentSetupFile() {
		return get("radoop.environmentSetupFile", getRadoopHome()
				+ "/lib/jruby_hadoop_environment.rb");
	}

	public void setEnvironmentSetupFile(String s) {
		set("radoop.environmentSetupFile", s);
	}

	public String getRadoopDirZip() {
		return get("radoop.dir.zip");
	}

	public void setRadoopDirZip(String s) {
		set("radoop.dir.zip", s);
	}

	public String getEnvironmentConfigurationObject() {
		return get("radoop.environment.createSetupObject",
				"get_jruby_hadoop_env_config_object");
	}

	public void setEnvironmentConfigurationObject(String s) {
		set("radoop.environment.createSetupObject", s);
	}

	public String getJrubyBaseZipfile() {
		return get("radoop.jruby.home.zipfile");
	}

	public void setJrubyBaseZipfile(String s) {
		set("radoop.jruby.home.zipfile", s);
	}

	public String getRubyFile() {
		return get("radoop.jruby.rubyFile");
	}

	public void setRubyFile(String s) {
		set("radoop.jruby.rubyFile", s);
	}

	public String getRubyDirectories() {
		return get("radoop.rubyDirectories");
	}

	public void setRubyDirectories(String s) {
		set("radoop.rubyDirectories", s);
	}

	public String getDistributedRubyFile() {
		return get("radoop.distributedRubyFile");
	}

	public void setDistributedRubyFile(String s) {
		set("radoop.distributedRubyFile", s);
	}

	public String getMainRubyDirZip() {
		return get("radoop.mainRubyDirZip");
	}

	public void setMainRubyDirZip(String s) {
		set("radoop.mainRubyDirZip", s);
	}

	public String getRadoopHome() {
		return get("radoop.home");
	}

	public void setRadoopHome(String s) {
		set("radoop.home", s);
	}

	public String getRadoopDistributedCacheLocation() {
		return get("radoop.distributedCacheLocation", "/tmp/radoop");
	}

	public void setRadoopDistributedCacheLocation(String s) {
		set("radoop.distributedCacheLocation", s);
	}
}
