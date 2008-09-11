require 'digest/sha1'

class HadoopUtils
  def self.copy_local_file_to_dfs(jobconf, src_path, destination_directory, delete_source = false)
    copy_local_file_to_dfs_with_checksum(jobconf, src_path, destination_directory, delete_source)
  end

  def self.copy_local_file_to_dfs_with_checksum(jobconf, src_path, destination_directory, delete_source = false)
    chksum = sha1_for_file(src_path)
    src_path = src_path.to_hadoop_path
    src_fs = jobconf.get_local_filesystem
    dst_path = "#{destination_directory}/#{chksum}".to_hadoop_path
    dst_fs = dst_path.get_file_system(jobconf)

    # Make sure the directory exists
    dst_fs.mkdirs(dst_path) or
      raise "failed to create destination directory #{destination_directory}"

    dst_file = org.apache.hadoop.fs.Path.new(dst_path, src_path.name)

    exists = file_exists?(dst_file, jobconf)
    
    if !exists
      org.apache.hadoop.fs.FileUtil.copy(src_fs, src_path, dst_fs, dst_path, false, delete_source, jobconf) or
        raise "failed to copy #{src_path} to #{destination_directory}"
    end

    dst_file
  end

  def self.sha1_for_file f
    Digest::SHA1.hexdigest(File.read(f))
  end

  def self.file_exists?(hadoop_path, jobconf)
    fs = hadoop_path.getFileSystem(jobconf)
    fs.exists(hadoop_path)
  end
end