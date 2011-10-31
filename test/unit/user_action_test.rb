require 'test_helper'

class UserActionTest < ActiveSupport::TestCase
  self.use_instantiated_fixtures  = true
  
  def test_create_basic
    ua = UserAction.new(:controller => 'user', :action => 'home', :method => 'get')
    assert ua.save
    assert_equal ua.controller, 'user'
    assert_equal ua.action, 'home'
    assert_equal ua.method, 'get'
    assert_nil ua.visitor
    assert_nil ua.user
    assert_nil ua.merchant
    assert_nil ua.deal
    assert_nil ua.share 
  end
  
  def test_create_full
    v = Visitor.create
    u = @test_user
    m = @bob
    d = @burger_deal
    ua = UserAction.new(:controller => 'user', :action => 'home', :method => 'get',
      :visitor_id => v.id, :user_id => u.id, :merchant_id => m.id, :deal_id => d.id)
    assert ua.save
    assert_equal ua.controller, 'user'
    assert_equal ua.action, 'home'
    assert_equal ua.method, 'get'
    assert_equal ua.visitor, v
    assert_equal ua.user, u
    assert_equal ua.merchant, m
    assert_equal ua.deal, d
  end  
  
  def test_create_multiple
    ua = UserAction.new(:controller => 'user', :action => 'home', :method => 'get',
      :visitor_id => 10000, :user_id => 1000, :merchant_id => 10, :deal_id => 1)
    assert ua.save
    ua = UserAction.new(:controller => 'user', :action => 'home', :method => 'get',
      :visitor_id => 10000, :user_id => 1000, :merchant_id => 10, :deal_id => 1)
    assert ua.save      
  end
  
  def test_missing_fields
    ua = UserAction.new(:controller => nil, :action => 'home', :method => 'get')
    assert !ua.save
    ua = UserAction.new(:controller => 'user', :action => nil, :method => 'get')
    assert !ua.save
    ua = UserAction.new(:controller => 'user', :action => 'home', :method => nil)
    assert !ua.save
    # nor empty strings
    ua = UserAction.new(:controller => '', :action => 'home', :method => 'get')
    assert !ua.save
    ua = UserAction.new(:controller => 'user', :action => '', :method => 'get')
    assert !ua.save
    ua = UserAction.new(:controller => 'user', :action => 'home', :method => '')
    assert !ua.save
  end
end
