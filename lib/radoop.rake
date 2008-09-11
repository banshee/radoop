require 'java'
require 'rubygems'
require 'rake'
require 'pathname'
require File.dirname(__FILE__) + '/rake_zip'

hadoop_home = ENV["HADOOP_HOME"] or raise "Environment variable HADOOP_HOME must be set"
radoop_class = ENV["radoop_class"] or raise "Environment variable radoop_class must be set"
gem_zipfiles = []
ruby_dir_zipfiles = []
jruby_lib_zip = ''

jruby_home = java.lang.System.get_property('jruby.home') or raise "jruby.home must be set"
local_zipfile_location = ENV["RADOOP_LOCAL_ZIP_FILES"] || ENV["TMPDIR"] || "/tmp/radoop"
FileUtils.mkdir_p local_zipfile_location or
  raise("Could not create directory #{local_zipfile_location}")

###############################################################################
# Create zip files for gem directories
task :gem_zipfiles
%w(GEM_HOME GEM_PATH).each do |g|
  zip_directory_via_env g, "#{local_zipfile_location}/gem_dir", :gem_zipfiles do |f|
    gem_zipfiles << f
  end
end
task :radoop => :gem_zipfiles

###############################################################################
# Create a zip file for jruby.home
jruby_lib_zip = "#{local_zipfile_location}/jruby.zip"
create_zipfile_task jruby_lib_zip, jruby_home, :radoop

###############################################################################
# Create a zip file for the Ruby script directory

ruby_file = ENV['radoop_file']
ruby_dir_zip = "#{local_zipfile_location}/main_script_#{Process.pid}.zip"
create_zipfile_task ruby_dir_zip, File.dirname(ruby_file), :radoop
ruby_dir_zipfiles << ruby_dir_zip

###############################################################################
# Create a zip file for the Radoop library

ENV['RADOOP_HOME'] ||= File.dirname(__FILE__) + "/.."
radoop_dir_zip = "#{local_zipfile_location}/radoop_lib_#{Process.pid}.zip"
create_zipfile_task radoop_dir_zip, ENV['RADOOP_HOME'], :radoop
ruby_dir_zipfiles << radoop_dir_zip

###############################################################################
# Create a zip file for any other Ruby directories

ruby_libs = ENV['RUBYLIB'] || ''
ruby_libs.split(':').each do |rlib|
  location = "#{local_zipfile_location}/ruby_lib_#{rlib.gsub('/', '_')}.zip"
  create_zipfile_task location, rlib, :radoop
  ruby_dir_zipfiles << location
end


###############################################################################
# Build everything
desc "Build all radoop zip files, then launch the radoop job"
task :radoop

task :default => :radoop

hadoop_jars = Pathname.glob(hadoop_home + "/*.jar")
hadoop_jars += Pathname.glob(hadoop_home + "/lib/*.jar")
hadoop_jars = hadoop_jars.map {|j| j.to_s.gsub(' ', '\\ ') }

zip_params = gem_zipfiles.map {|z| "--gem_zip #{z}"}.join(" ")
radoop_dir_zip_params = ruby_dir_zipfiles.map {|z| "--ruby_dir_zip #{z}"}.join(" ")
radoop_home = Pathname.new(ENV["RADOOP_HOME"] || File.dirname(__FILE__) + "/..").cleanpath
radoop_jar = Pathname.new(File.dirname(__FILE__) + "/../jars/radoop.jar").cleanpath

classpath =<<-EOS
-classpath #{hadoop_home}/conf:#{hadoop_jars.join(":")}:#{jruby_home}/lib/jruby.jar:#{radoop_home}/jars/jruby-engine.jar
EOS

cmd =<<-EOS
java
#{classpath}
org.apache.hadoop.mapred.JobShell
#{radoop_jar}
com.restphone.radoop.Radoop
-Dradoop.home=#{radoop_home}
-Dradoop.jruby.rubyFile=#{ruby_file}
-Dmapred.jar=#{radoop_jar}
-Dradoop.class=#{radoop_class}
#{zip_params}
--jruby_home_zip #{jruby_lib_zip}
#{radoop_dir_zip_params}
--radoop_file #{File.basename(ruby_dir_zip) + "/" + File.basename(ENV['radoop_file'])}
--radoop_dir #{radoop_dir_zip}
--jruby_home #{jruby_home}
EOS
%w(output_path input_path).each do |env_var|
  cmd += " --#{env_var} #{ENV[env_var]}" if ENV[env_var]
end
cmd.gsub!(/[\r\n\s]+/, ' ')

task :runcmd => :radoop do
  puts cmd if ENV["VERBOSE"]
  exec cmd
end
