require 'test_helper'

class MerchantMailerTest < ActionMailer::TestCase
  self.use_instantiated_fixtures  = true
  fixtures :users

  def test_send_activation
    sent = MerchantMailer.send_activation(@bob.email, @bob.username, @bob.id, @bob.activation_code)
    assert sent
    assert_equal sent.to[0], @bob.email
    assert_equal sent.subject, "Please activate your account"
    assert_match Regexp.new("Please activate your account to start creating deals."), sent.body.raw_source
    assert_match Regexp.new("#{OPTIONS[:site_url]}/merchant/activate"), sent.body.raw_source
    assert_match Regexp.new("merchant_id=#{@bob.id}"), sent.body.raw_source
    assert_match Regexp.new("activation_code=#{@bob.activation_code}"), sent.body.raw_source      
  end
  
  def test_send_forgot_password
    new_password = 'newpassword'
    sent = MerchantMailer.send_forgot_password(@bob.email, @bob.username, new_password)
    assert sent
    assert_equal sent.to[0], @bob.email
    assert_equal sent.subject, "Your password is ..."
    assert_match Regexp.new("Your username is #{@bob.username}."), sent.body.raw_source
    assert_match Regexp.new("Your new password is #{new_password}"), sent.body.raw_source    
  end
  
  def test_send_changed_email
    old_email = 'old_email@rallycommerce.com'
    sent = MerchantMailer.send_changed_email(@bob.email, @bob.username, old_email, @bob.email)
    assert sent
    assert_equal sent.to[0], @bob.email
    assert_equal sent.subject, "You have changed your email"
    assert_match Regexp.new("You have made the following changes to your account"), sent.body.raw_source
    assert_match Regexp.new("Changed email from #{old_email} to #{@bob.email}."), sent.body.raw_source 
  end
  
end