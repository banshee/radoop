module HadoopText
  def to_hadoop_text
    org.apache.hadoop.io.Text.new(self.to_s)
  end
end

class String
  include HadoopText

  def to_hadoop_path
    org.apache.hadoop.fs.Path.new(self)
  end
end

class Numeric
  include HadoopText

  def to_long_writable
    Java::OrgApacheHadoopIo::LongWritable.new(self.to_i)
  end

  def to_int_writable
    Java::OrgApacheHadoopIo::IntWritable.new(self.to_i)
  end
end

class Java::OrgApacheHadoopIo::LongWritable
  alias_method :to_i, :get
end

class Java::OrgApacheHadoopIo::IntWritable
  alias_method :to_i, :get
end

class Java::OrgApacheHadoopIo::FloatWritable
  alias_method :to_f, :get

  def to_i
    Integer(to_f)
  end
end

class Java::OrgApacheHadoopMapred::JobConf
  # This allows delcaring symbols in a Radoop object like this:
  #
  # class MyRadoop < Radoop
  #   input_format FileInputFormat
  #   ...
  #
  # These calls are turned into
  #
  #   a_jobconf_object.send(;input_format, FileInputFormat)
  def method_missing name, *args
    if args.length > 0
      if name.to_s !~ /^set_/
        return send("set_#{name}", *args)
      end
    else # No arguments passed - try the getter
      if name.to_s !~ /^get_/
        return send("get_#{name}")
      end
    end
    super
  end

  def input_paths f
    org.apache.hadoop.mapred.FileInputFormat.set_input_paths(self, f)
  end

  def add_input_paths f
    org.apache.hadoop.mapred.FileInputFormat.add_input_paths(self, f)
  end

  def output_path f
    org.apache.hadoop.mapred.FileOutputFormat.setOutputPath(self, f.to_hadoop_path)
  end

  def sequence_file_compress_output do_compression = true
    org.apache.hadoop.mapred.SequenceFileOutputFormat.setCompressOutput(conf, do_compression);
  end

  def sequence_file_output_compression_type t = :record
    t = eval("Java::OrgApacheHadoopIo::SequenceFile::CompressionType::#{t.upcase}")
    org.apache.hadoop.mapred.SequenceFileOutputFormat.setOutputCompressionType(t)
  end

  def get_local_filesystem
    org.apache.hadoop.fs.FileSystem.getLocal(self)
  end

  def add_file_to_class_path(f)
    org.apache.hadoop.filecache.DistributedCache.add_file_to_class_path(f.to_hadoop_path, self)
  end

  def add_archive_to_class_path(f)
    org.apache.hadoop.filecache.DistributedCache.add_archive_to_class_path(f.to_hadoop_path, self)
  end

  def get_local_cache_files
    org.apache.hadoop.filecache.DistributedCache.get_local_cache_files(self)
  end

  def get_local_cache_archives
    org.apache.hadoop.filecache.DistributedCache.get_local_cache_archives(self)
  end
end

class Java::OrgApacheHadoopFs::Path
  # So you can call #to_hadoop_path on either a String or a
  # Java::OrgApacheHadoopFs::Path object.
  def to_hadoop_path
    self
  end
end
