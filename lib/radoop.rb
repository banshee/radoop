require 'java'
require 'rubygems'
require File.dirname(__FILE__) + '/radoop_zip'
require File.dirname(__FILE__) + '/hadoop_utils'

require "radoop_support"
require 'implements_mapper'

class Radoop
  VERSION = '0.0.1'
  attr_accessor :job_conf
  attr_accessor :jruby_archive
  attr_accessor :cleanup_procs

  include_package "org.apache.hadoop.fs"
  include_package "org.apache.hadoop.io"
  include_package "org.apache.hadoop.mapred"
  include_package "org.apache.hadoop.mapred.lib"

  def configure(jobconf, array_of_command_line_elements)
    self.job_conf = jobconf
    
    set_default_configuration(jobconf)
    
    self.class.configure_per_class_job_configurations(jobconf)

    process_options(jobconf, array_of_command_line_elements)
    
    copy_jruby_and_engine_jargs(jobconf)
  end

  def self.method_missing *args
    per_class_job_configurations << args.dup
  end

  def self.per_class_job_configurations
    @per_class_job_configurations ||= []
  end
  
  def self.configure_per_class_job_configurations(conf)
    per_class_job_configurations.each do |c|
      conf.send("set_#{c.first}", *c[1..-1])
    end
  end

  def create_zip_for_directory_containing_ruby_file(jobconf)
    ruby_file = jobconf.get_ruby_file
    ruby_dir = File.dirname(ruby_file)
    create_ruby_zipfile(jobconf, ruby_dir, nil, :setRubyDirectories, "main_script") do |zipfile|
      jobconf.set_distributed_ruby_file(File.basename(ruby_file))
    end
  end
  
  def create_zip_for_radoop_libs(jobconf)
    # XXX
    radoop_dir = "/home/james/dev/radoop/lib"
    create_ruby_zipfile(jobconf, radoop_dir, nil, :setRubyDirectories, "radoop_lib")
  end
  
  def copy_jruby_and_engine_jargs(jobconf)
    f = HadoopUtils.copy_local_file_to_dfs(jobconf, "#{jobconf.get_radoop_home}/jars/jruby-engine.jar", jobconf.getRadoopDistributedCacheLocation, true)
    jobconf.add_file_to_class_path(f)
    f = HadoopUtils.copy_local_file_to_dfs(jobconf, "#{Java::JavaLang::System.getProperty('jruby.home')}/lib/jruby.jar", jobconf.getRadoopDistributedCacheLocation, true)
    jobconf.add_file_to_class_path(f)
  end

  def add_archive_on_dfs_to_job_conf(jobconf, path, configuration_getter, configuration_setter)
    jobconf.add_archive_to_class_path(path)
    final_path_element = File.basename(path.to_s)
    add_element_to_jobconf_colon_separated_variable(jobconf, final_path_element, configuration_getter, configuration_setter)
  end

  def add_archives_on_dfs_to_job_conf(jobconf, paths, configuration_getter, configuration_setter)
    paths.each do |p|
      add_archive_on_dfs_to_job_conf(jobconf, p, configuration_getter, configuration_setter)
    end
  end

  # Add new_element to the JobConf variable given by configuration_getter.
  # Set the variable given in configuration_setter to the result.
  def add_element_to_jobconf_colon_separated_variable(jobconf, new_element, configuration_getter, configuration_setter)
    if configuration_getter
      starting_value = jobconf.send(configuration_getter).to_s
      starting_value += ':' if starting_value.length > 0
    end
    result = "#{starting_value}#{new_element}"
    jobconf.send(configuration_setter, result)
    result
  end
  
  # Given a JobConf object and a directory given in dir, create a zip file
  # of the directory.  configuration_setter will be set to the name of the
  # zip archive that's created.
  def create_ruby_zipfile(jobconf, dir, configuration_getter, configuration_setter, file_prefix = "zipfile")
    result = nil
    RadoopZip.create_temporary_zipfile("", dir, file_prefix) do |gem_archive|
      puts "put this local zip file to dfs: #{gem_archive}"
      # XXX
      path = HadoopUtils.copy_local_file_to_dfs(jobconf, gem_archive, "#{distributed_cache_location(jobconf)}/jruby_gems", true)
      result = add_archive_on_dfs_to_job_conf(jobconf, path, configuration_getter, configuration_setter)
      yield gem_archive if block_given?
    end

    result
  end

  def distributed_cache_location jobconf
    jobconf.getRadoopDistributedCacheLocation
  end

  def set_default_configuration(jobconf)
    {
      :input_format => TextInputFormat,
      :output_format => TextOutputFormat,
      :mapper_class => Java::ComRestphoneRadoop::RubyMapReducer
    }.each_pair do |k, v|
      jobconf.send("set_#{k}", *v)
    end
  end

  def mapper(k, v, output, reporter)
  end

  def reducer(k, vs, output, reporter, jobconf)
    raise "You must provide a definition for reducer"
  end

  def start_map_reduce
  end

  def process_options(jobconf, options_array)
    options = getoptions(options_array.to_ary)
    dfs_zip_directory = options['dfs_zip_directory'] || "#{distributed_cache_location(jobconf)}"
    options.each_pair do |name, val|
      dfs_files = []
      if name =~ /_zip$/
        val.each do |v|
          dfs_files << HadoopUtils.copy_local_file_to_dfs(jobconf, v, dfs_zip_directory)
        end
      end
      case name
      when /gem_zip/
        add_archives_on_dfs_to_job_conf(jobconf, dfs_files, :getRubyGems, :setRubyGems)
      when /jruby_home_zip/
        add_archives_on_dfs_to_job_conf(jobconf, dfs_files, :getJrubyBaseZipfile, :setJrubyBaseZipfile)
      when /ruby_dir_zip/
        add_archives_on_dfs_to_job_conf(jobconf, dfs_files, :getRubyDirectories, :setRubyDirectories)
      when /radoop_file/
        main_dir_zip, main_dir_file = val.first.split('/')
        jobconf.set_distributed_ruby_file(main_dir_file)
        jobconf.set_main_ruby_dir_zip(main_dir_zip)
      when /radoop_dir/
        jobconf.set_radoop_dir_zip(File.basename(val.first))
      when /radoop_distributed_cache_location/
        jobconf.setRadoopDistributedCacheLocation(val.to_s)
      when 'output_path'
        jobconf.send(name, val.first)
      when 'input_path'
        jobconf.send(name, val.first.to_hadoop_path)
      end

      dfs_files.each do |f|
        (self.cleanup_procs ||= []) << lambda do
          HadoopUtils.remove_file(jobconf, f)
        end
      end
    end
  end

  # Only used for debugging
  def puts_jobconf jobconf, c
    #    puts "xj jobbconf #{c} is #{jobconf.send(c)}"
  end

  def getoptions(o)
    result = {}
    while o.length > 0
      option = o.shift.gsub('--', '').strip
      value = o.shift
      (result[option] ||= []) << value
    end
    result
  end

  def get_mapper_interface_implementor
    @mapper ||= ImplementsMapper.new(self)
  end

  def get_reducer_interface_implementor
    get_mapper_interface_implementor
  end

  def self.jruby_libs(radoop_home)
    result = %w(
    jruby.jar
    jruby-engine.jar
    )
    result.map {|f| radoop_home + "/jars/#{f}" }
  end

  def jruby_libs(radoop_home)
    # XXX better way to call class method
    self.class.jruby_libs(radoop_home)
  end
end
