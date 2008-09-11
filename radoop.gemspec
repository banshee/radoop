Gem::Specification.new do |s|
  s.name = %q{radoop}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["James Moore"]
  s.date = %q{2008-09-10}
  s.default_executable = %q{radoop}
  s.description = %q{radoop is a jruby interface to Hadoop}
  s.email = ["james@restphone.com"]
  s.executables = ["radoop"]
  s.extra_rdoc_files = ["README.txt", "test/ziptestfiles/dir1/file2.txt"]
  s.files = ["bin/radoop", "jars/jruby-engine.jar", "jars/radoop.jar", "lib/radoop_support.rb", "lib/jruby_hadoop_environment.rb", "lib/rake_zip.rb", "lib/radoop.rb", "lib/hadoop_utils.rb", "lib/radoop_zip.rb", "lib/radoop.rake", "lib/implements_mapper.rb", "LICENSE", "README.txt", "test/test_zip.rb", "test/test_helper.rb", "test/test_radoop.rb", "test/test_jruby_hadoop_environment.rb", "test/ziptestfiles/test1", "test/ziptestfiles/dir1/file2.txt"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/banshee/radoop/tree}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{radoop}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{radoop is a jruby interface to Hadoop}
  s.test_files = ["test/test_zip.rb", "test/test_helper.rb", "test/test_radoop.rb", "test/test_jruby_hadoop_environment.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_development_dependency(%q<hoe>, [">= 1.7.0"])
    else
      s.add_dependency(%q<hoe>, [">= 1.7.0"])
    end
  else
    s.add_dependency(%q<hoe>, [">= 1.7.0"])
  end
end
