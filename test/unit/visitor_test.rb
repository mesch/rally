require 'test_helper'

class VisitorTest < ActiveSupport::TestCase
  self.use_instantiated_fixtures = true
  
  def test_visitor_create
    v = Visitor.new
    assert_nil v.id
    assert v.save
    assert v.id
  end
  
  def test_visitor_create_multiple
    v = Visitor.new
    assert v.save
    v = Visitor.new
    assert v.save    
  end
  
end