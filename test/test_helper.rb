require 'rubygems'
require 'mocha'

class Test::Unit::TestCase
  def self.only_test *args
    @only_test = args.map { |n| to_test_name(n) }
  end

  # test "verify something" do
  # ...
  # end
  def self.test(name, &block)
    test_name = to_test_name(name)
    raise "#{test_name} is already defined in #{self}" if self.instance_methods.include?(test_name.to_s)
    block ||= lambda {assert false, "no implementation for this test"}
    if (@only_test && @only_test.include?(test_name)) || !@only_test
      define_method(test_name, &block)
    end
  end

  def self.to_test_name name
    "test_#{name.gsub(/[\s'"]/,'_')}".to_sym
  end
end

class Object
  def minfo
    ancstrs = ancestors.inspect if kind_of? Module
    ancstrs ||= self.class.ancestors.inspect
    
    puts "-------------------"
    puts "Var              : " + self.inspect
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
