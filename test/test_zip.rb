require File.dirname(__FILE__) + "/test_helper"
require File.dirname(__FILE__) + "/../lib/radoop_zip"
require 'mocha'

class ZipTest < Test::Unit::TestCase
  test "create zip file for directory" do
    expects(:must_call)
    test_files = File.dirname(__FILE__) + "/ziptestfiles"
#    Zip::ZipFile.any_instance.expects(:add).with('ziptestfiles/test1', test_files + "/test1")
    RadoopZip.create_temporary_zipfile("", test_files) do |z|
      must_call
      puts "z is #{z}"
      sleep 60
    end
  end
end

