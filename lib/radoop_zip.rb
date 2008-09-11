require 'rubygems'
require 'multi'
require 'zip/zip'
require 'pathname'
require 'tempfile'

module Zip
  class ZipFile
    def add_directory(destination_base, src_path)
      destination_base ||= ""
      Dir.glob(src_path + '/**/*').select do |f|
        partial_filename = f[(src_path.length + 1) .. -1]
        basename_plus_partial_filename = File.join(File.basename(src_path), partial_filename)
        destination = destination_base == "" ? basename_plus_partial_filename :
          File.join(destination_base, basename_plus_partial_filename)
        destination = partial_filename
        stat = File.stat(f)
        if stat.directory?
          mkdir destination
        elsif stat.size != 1
          # XXX Hack Hack Hack
          # The rubyzip library dies on files that contain a single byte
          # 0x0000.
          add(destination, f)
        end
      end
    end
  end
end

class RadoopZip
  def self.create_temporary_zipfile destination_path, src_path, prefix = "zipfile"
    Tempfile.open(prefix) do |t|
      zip_path = "#{t.path}.zip"
      Zip::ZipFile.open(zip_path, Zip::ZipFile::CREATE) do |zipfile|
        s = File.stat(src_path)
        if s.directory?
          zipfile.add_directory(destination_path, src_path)
        elsif s.file?
          zipfile.add(destination_path, src_path)
        end
      end
      yield zip_path if block_given?
      File.unlink(zip_path)
    end
  end
end
