require 'java'
require 'rbconfig'

class JrubyHadoopEnvironment
  def setup_jruby_environment(jobconf)
    if jobconf.get_job_name == ""
      # We're running the setup task
      $LOAD_PATH.concat(jruby_load_path_elements(jobconf.get('jruby.home')))
      $LOAD_PATH << jobconf.get_radoop_home + "/lib"
      $LOAD_PATH.select { |p| p =~ /\.jar$/ }.each do |jar|
        if File.exists?(jar)
          require jar
        end
      end
    else
      set_jruby_load_path(jobconf)
      set_gem_load_path(jobconf)
      load_ruby_files(jobconf)
    end
  end

  protected

  # Append the unzipped file given in gzipped_file
  # to the GEM_PATH environment variable
  def append_to_gem_path gzipped_file
    p = ENV['GEM_PATH'] || ''
    p += ':' if p.length > 0
    p += gzipped_file
    ENV["GEM_PATH"] = p
  end

  # Execute block for each archive specified in method_name.
  def each_local_cache_archive jobconf, method_name
    archives = jobconf.send(method_name).to_s.split(':')
    get_local_cache_archives(jobconf).each do |f|
      archives.each do |a|
        if f.to_s.split('/').last == a
          yield f
        end
      end
    end
  end

  def get_local_cache_archives(jobconf)
    Java::OrgApacheHadoopFilecache::DistributedCache.get_local_cache_archives(jobconf) || []
  end

  def get_local_cache_files(jobconf)
    Java::OrgApacheHadoopFilecache::DistributedCache.get_local_cache_files(jobconf) || []
  end

  # Return an array of the elements that should be in LOAD_PATH
  # for the given prefix.
  def jruby_load_path_elements prefix
    %W(
#{prefix}/lib/ruby/site_ruby/1.8
#{prefix}/lib/ruby/site_ruby
#{prefix}/lib/ruby/1.8
#{prefix}/lib/ruby/1.8/java
lib/ruby/1.8
.
    )
  end

  # Add all the Ruby zip files to the Ruby LOAD_PATH.
  def load_ruby_files jobconf
    each_local_cache_archive(jobconf, :get_ruby_directories) do |f|
      f = f.to_s
      $LOAD_PATH << f
      # XXX we may only need this if we're not using a gem
      if File.basename(f) == jobconf.radoop_dir_zip
        $LOAD_PATH << "#{f}/lib"
      end
    end
  end

  # Append the unzipped files identified by jobconf.get_ruby_gems
  # to the GEM_PATH.
  def set_gem_load_path jobconf
    each_local_cache_archive(jobconf, :get_ruby_gems) do |f|
      append_to_gem_path(f)
    end
  end

  # Set the Ruby LOAD_PATH to the unzipped Ruby base directory
  # (stored in the job conf, availabel through getJrubyBaseZipfile)
  def set_jruby_load_path jobconf
    each_local_cache_archive(jobconf, :getJrubyBaseZipfile) do |f|
      $LOAD_PATH.concat(jruby_load_path_elements(f))
      #      append_to_gem_path("#{f}/lib/ruby/gems/1.8")
      fixup_rb_config f.to_s
    end
  end

  def fixup_rb_config new_prefix
    exec_prefix = RbConfig::CONFIG['exec_prefix']
    RbConfig::CONFIG.each_pair do |k, v|
      RbConfig::CONFIG[k] = v.sub(exec_prefix, new_prefix)
    end
  end
end

def get_jruby_hadoop_env_config_object
  JrubyHadoopEnvironment.new
end
