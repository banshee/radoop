class ImplementsMapper
  include Java::OrgApacheHadoopMapred::Mapper

  attr_accessor :parent_object

  def initialize(p)
    self.parent_object = p
  end

  def map(k, v, output, reporter)
    parent_object.map(k, v, output, reporter)
  end

  def reduce(k, v, output, reporter)
    parent_object.reduce(k, v, output, reporter)
  end
end
