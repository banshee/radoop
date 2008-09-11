require 'java'
require 'pathname'
require File.dirname(__FILE__) + '/radoop_zip'

# Given a pair
#
#   zipfile => a_directory
#
# If any file in the tree rooted at a_directory is newer than
# zipfile, then remove zipfile and create it by zipping up
# all the files in a_directory.
def zip_directory args, &blk
  prefix = args[:prefix] || ''
  args = args.dup
  args.delete(:prefix)
  args.each_pair do |zipfile, src_directory|
    all_files_in_directory = FileList.new((Pathname.new(src_directory) + '**' + '*').to_s)
    file zipfile => all_files_in_directory do
      blk.call(zipfile, src_directory) if blk
      File.unlink(zipfile) rescue nil
      Zip::ZipFile.open(zipfile, Zip::ZipFile::CREATE) do |z|
        z.add_directory(prefix, src_directory)
      end
    end
  end
end

# Given an environment variable containing a colon-separated list of paths,
# create a zipfile for each of those paths.  The zipfile path starts with
# zipfile_prefix.
def zip_directory_via_env env_var, zipfile_prefix, add_to_task
  each_separated_by_colons(ENV[env_var]) do |dir|
    destination_zipfile = zipfile_prefix + dir.to_s.gsub("/", "_") + ".zip"
    zip_directory destination_zipfile => dir
    task add_to_task => destination_zipfile
    yield destination_zipfile if block_given?
  end
end

def each_separated_by_colons s
  s.to_s.split(':').each do |dir|
    if dir && dir.length > 0
      yield dir
    end
  end
end

# Returns the last directory + basename.
#
# For example:
#
#   dir_plus_basename('/tmp/a/b') == 'a/b'
def dir_plus_basename f
  first = File.basename(File.dirname(f))
  first = '' if first == '/'
  second = File.basename(f)
  "#{first}/#{second}"
end

def create_zipfile_task destination_zipfile, source_directory, taskname, &blk
  zip_directory destination_zipfile => source_directory do |destination_zipfile, source_directory|
    puts "building #{destination_zipfile} from #{source_directory}" if ENV["VERBOSE"]
    blk.call if blk
  end
  task taskname => destination_zipfile
end
