require 'rubygems'
require File.dirname(__FILE__) + "/test_helper"
require File.dirname(__FILE__) + "/../lib/radoop"
require 'mocha'

# Steps for Hadoop
%w(
Startup
radoop_lib
Ruby file

Zip files added to DistributedCache:
jruby.home
GEM_HOME
GEM_PATH
$radoop_home - the Radoop Ruby files
The directory containing the Radoop script
User-specified directories that will be added to the load path

Scripts that need to be run by the environment:
jruby_hadoop_environment.rb
The Radoop script

Jars:
jruby.jar
jruby-engine.jar
All the other jars are included by Hadoop.

Additions to LOAD_PATH
Set GEM_HOME to $java_base/lib/ruby/gems/1.8
If GEM_HOME is set on the master, add the unziped GEM_HOME files to GEM_HOME
All Ruby directories specified by radoop.rubyDirectories
  Note that this always includes the directory containing the main ruby file
)

class RadoopTest < Test::Unit::TestCase
  class TestWithInputAndOutput < Radoop
    input_format org.apache.hadoop.mapred.TextInputFormat
    output_format org.apache.hadoop.mapred.TextOutputFormat
  end

  class TestWithSequenceFile < Radoop
    sequence_file_output_compression_type :record
  end

  test "the class definition can contain all the job configuration elements"
  test "map can be provided by a java class"
  test "map can be provided by a ruby class"
  test "map can be provided by a method"
  test "input files are provided on the command line"
  
  test "java_object_for returns a org.apache.hadoop.io.Text object" do
    r = Radoop.java_object_for :text
    assert_equal(org.apache.hadoop.io.Text, r)
  end
  
  test "input_format calls job configuration" do
    r = TestWithInputAndOutput.new
    jobconf = org.apache.hadoop.mapred.JobConf.new
#    jobconf.expects(:set_input_format).with(org.apache.hadoop.mapred.TextInputFormat)
#    jobconf.expects(:set_output_format).with(org.apache.hadoop.mapred.TextOutputFormat)
    r.configure(jobconf, [])
  end
  
  test "sequence_file_output_compression_type does the right thing" do
    r = TestWithInputAndOutput.new
    jobconf = stub('JobConf object')
    SequenceFileOutputFormat.expects(:setCompressOutput).with(jobconf, true)
    SequenceFileOutputFormat.expects(:setOutputCompressionType).with(
      jobconf,
      Java::OrgApacheHadoopIo::SequenceFile::CompressionType::RECORD
    )
    r.configure(jobconf)
  end

  test "configure_job works" do

  end
end
#
#
# input_format TextInputFormat.class
#  output_format SequenceFileOutputFormat.class
#  map_output_key_class Text.class
#  map_output_value_class Text.class

class Object
  def minfo
    ancstrs = ancestors.inspect if kind_of? Module
    ancstrs ||= self.class.ancestors.inspect

    puts "-------------------"
    puts "Var              : " + self.inspect
    puts "Instance variabs : " + to_indented_multiline_string(instance_variables)
    puts "Class            : " + self.class.inspect
    puts "Ancestors        : " + ancstrs
    puts "Methods          : " + to_indented_multiline_string(self.methods - Object.methods)
    puts "Singleton methods: " + to_indented_multiline_string(self.singleton_methods(false))
    puts "Instance methods : " + to_indented_multiline_string(self.class.instance_methods(false))
    puts "------------------"
  end
  def to_indented_multiline_string ary
    lbreak = "\n  "
    lbreak + ary.sort.join(lbreak)
  end
end

class TstRadoop < Radoop
  include_package "org.apache.hadoop.io"
  include_package "org.apache.hadoop.fs"
  include_package "org.apache.hadoop.mapred"

  input_path Path.new('/user/james/tmp/tale*.txt')
  output_path Path.new('/tmp/hadoopoutput' + Process.pid.to_s)

  output_format SequenceFileOutputFormat

  output_key_class Text
  output_value_class IntWritable

  def map(k, v, output, reporter)
    values = v.to_s.split(/\W+/)
    values.each do |v|
      output.collect(v.to_hadoop_text, 1.to_int_writable)
    end
  end
end
