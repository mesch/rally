require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  self.use_instantiated_fixtures  = true
  fixtures :users

  def test_send_activation
    sent = UserMailer.send_activation(OPTIONS[:site_url], @test_user.email, @test_user.email, @test_user.id, @test_user.activation_code)
    assert sent
    assert_equal sent.to[0], @test_user.email
    assert_equal sent.subject, "Please activate your account"
    assert_match Regexp.new("Please activate your account to start purchasing deals."), sent.body.raw_source
    assert_match Regexp.new("#{OPTIONS[:site_url]}/activate"), sent.body.raw_source
    assert_match Regexp.new("user_id=#{@test_user.id}"), sent.body.raw_source
    assert_match Regexp.new("activation_code=#{@test_user.activation_code}"), sent.body.raw_source    
    # test another subdomain
    sent = UserMailer.send_activation("bob.rcom.com", @test_user.email, @test_user.email, @test_user.id, @test_user.activation_code)
    assert sent
    assert_equal sent.to[0], @test_user.email
    assert_equal sent.subject, "Please activate your account"
    assert_match Regexp.new("Please activate your account to start purchasing deals."), sent.body.raw_source
    assert_match Regexp.new("bob.rcom.com/activate"), sent.body.raw_source
    assert_match Regexp.new("user_id=#{@test_user.id}"), sent.body.raw_source
    assert_match Regexp.new("activation_code=#{@test_user.activation_code}"), sent.body.raw_source    
  end
  
  def test_send_forgot_password
    new_password = 'newpassword'
    sent = UserMailer.send_forgot_password(OPTIONS[:site_url], @test_user.email, @test_user.email, new_password)
    assert sent
    assert_equal sent.to[0], @test_user.email
    assert_equal sent.subject, "Your password is ..."
    assert_match Regexp.new("Your email is #{@test_user.email}."), sent.body.raw_source
    assert_match Regexp.new("Your new password is #{new_password}"), sent.body.raw_source    
  end
  
  def test_send_changed_email
    old_email = 'old_email@rallycommerce.com'
    sent = UserMailer.send_changed_email(OPTIONS[:site_url], @test_user.email, old_email, @test_user.email)
    assert sent
    assert_equal sent.to[0], @test_user.email
    assert_equal sent.subject, "You have changed your email"
    assert_match Regexp.new("You have made the following changes to your account"), sent.body.raw_source
    assert_match Regexp.new("Changed email from #{old_email} to #{@test_user.email}."), sent.body.raw_source 
  end
  
  def test_send_confirmation
    sent = UserMailer.send_confirmation(OPTIONS[:site_url], @test_user.email, @burger_deal)
    assert sent
    assert_equal sent.to[0], @test_user.email
    assert_equal sent.subject, "Congratulations! Your deal has tipped."
    assert_match Regexp.new("#{OPTIONS[:site_url]}/login"), sent.body.raw_source
    assert_match Regexp.new("\"#{@burger_deal.title}\" has tipped."), sent.body.raw_source
    # test another subdomain
    sent = UserMailer.send_confirmation("bob.rcom.com", @test_user.email, @burger_deal)
    assert sent
    assert_equal sent.to[0], @test_user.email
    assert_equal sent.subject, "Congratulations! Your deal has tipped."
    assert_match Regexp.new("bob.rcom.com/login"), sent.body.raw_source
    assert_match Regexp.new("\"#{@burger_deal.title}\" has tipped."), sent.body.raw_source
  end
  
end