require 'test_helper'

class MerchantReportTest < ActiveSupport::TestCase
  self.use_instantiated_fixtures  = true
  fixtures :merchant_reports

  def setup
    MerchantReport.delete_all
  end
  
  def test_merchant_report_basic
    r = MerchantReport.new(:merchant_id => 10, :report_type => MerchantReport::COUPON_REPORT, :state => MerchantReport::GENERATING, :deal_id => 1)
    assert_not_nil r.merchant_id
    assert_not_nil r.report_type
    assert_not_nil r.state
    assert_nil r.generated_at
    assert r.save
  end
  
  def test_required_filters
    # Coupon Report
    r = MerchantReport.new(:merchant_id => 10, :report_type => MerchantReport::COUPON_REPORT, :state => MerchantReport::GENERATING, :deal_id => 1)
    assert r.save
    r = MerchantReport.new(:merchant_id => 10, :report_type => MerchantReport::COUPON_REPORT, :state => MerchantReport::GENERATING, :deal_id => nil)
    assert !r.save
  end 
  
  def test_merchant_report_state
    r = MerchantReport.new(:merchant_id => 10, :report_type => MerchantReport::COUPON_REPORT, :state => MerchantReport::GENERATING, :deal_id => 1)
    assert r.save
    r.state = 'SOMETHING_ELSE'
    assert !r.save
    r = MerchantReport.new(:merchant_id => 10, :report_type => MerchantReport::COUPON_REPORT, :state => MerchantReport::GENERATED, :deal_id => 1)
    assert r.save
    r = MerchantReport.new(:merchant_id => 10, :report_type => MerchantReport::COUPON_REPORT, :state => 'SOMETHING_ELSE', :deal_id => 1)
    assert !r.save
    r = MerchantReport.new(:merchant_id => 10, :report_type => MerchantReport::COUPON_REPORT, :state => nil, :deal_id => 1)
    assert !r.save    
  end
  
  def test_merchant_report_type
    r = MerchantReport.new(:merchant_id => 10, :report_type => MerchantReport::COUPON_REPORT, :state => MerchantReport::GENERATING, :deal_id => 1)
    assert r.save
    r.report_type = 'SOMETHING_ELSE'
    assert !r.save
    r = MerchantReport.new(:merchant_id => 10, :report_type => "SOMETHING_ELSE", :state => MerchantReport::GENERATING, :deal_id => 1)
    assert !r.save
    r = MerchantReport.new(:merchant_id => 10, :report_type => nil, :state => MerchantReport::GENERATING, :deal_id => 1)
    assert !r.save
  end 
  
  def test_merchant_report_missing_fields
    r = MerchantReport.new(:merchant_id => nil, :report_type => MerchantReport::COUPON_REPORT, :state => MerchantReport::GENERATING, :deal_id => 1)
    assert !r.save
    r = MerchantReport.new(:merchant_id => 10, :report_type => nil, :state => MerchantReport::GENERATING, :deal_id => 1)
    assert !r.save
    # missing some other filters - ok
    r = MerchantReport.new(:merchant_id => 10, :report_type => MerchantReport::COUPON_REPORT, :start => nil, :state => MerchantReport::GENERATING, :deal_id => 1)
    assert r.save
    r = MerchantReport.new(:merchant_id => 10, :report_type => MerchantReport::COUPON_REPORT, :end => nil, :state => MerchantReport::GENERATING, :deal_id => 1)
    assert r.save
    # missing generated_at - ok
    r = MerchantReport.new(:merchant_id => 10, :report_type => MerchantReport::COUPON_REPORT, :generated_at => :nil, :state => MerchantReport::GENERATING, :deal_id => 1)    
  end
  
  def test_merchant_report_multiple
    r = MerchantReport.new(:merchant_id => 10, :report_type => MerchantReport::COUPON_REPORT, :state => MerchantReport::GENERATING, :deal_id => 1)
    assert r.save
    # same merchant, same type, same state - ok 
    r = MerchantReport.new(:merchant_id => 10, :report_type => MerchantReport::COUPON_REPORT, :state => MerchantReport::GENERATING, :deal_id => 1)
    assert r.save       
  end
  
  def test_generate_file_name
    generated_at = Time.zone.now
    # Coupon Report
    r = MerchantReport.new(:merchant_id => 10, :report_type => MerchantReport::COUPON_REPORT, :state => MerchantReport::GENERATING, :deal_id => 1)
    assert r.save
    assert_equal r.generate_file_name(generated_at), "coupon_report_10_1_#{generated_at.strftime(OPTIONS[:time_format_file])}.csv" 
  end
  
  def test_column_names
    # Coupon Report
    r = MerchantReport.new(:merchant_id => 10, :report_type => MerchantReport::COUPON_REPORT, :state => MerchantReport::GENERATING, :deal_id => 1)
    assert r.save
    assert_equal r.column_names, ["coupon_code", "email", "first_name", "last_name", "authorized_at"]
  end
  
  def test_generate_header
    generated_at = Time.zone.now
    # Coupon Report
    r = MerchantReport.new(:merchant_id => 10, :report_type => MerchantReport::COUPON_REPORT, :state => MerchantReport::GENERATING, :deal_id => 1)
    assert r.save
    assert_equal r.generate_header, "Filters: Merchant ID (10), Deal ID (1)"
  end

  # also testing generate_row
  def test_coupon_results
    m = @emptybob
    u = @empty_user
    d = Deal.new(:merchant_id => m.id, :title => 'dealio', :start_date => Time.zone.today.beginning_of_day, :end_date => Time.zone.today.end_of_day, 
      :expiration_date => Time.zone.today.end_of_day, :deal_price => '10.00', :deal_value => '20.00', :published => true, :max => 2)
    assert d.save
    r = MerchantReport.new(:merchant_id => m.id, :report_type => MerchantReport::COUPON_REPORT, :state => MerchantReport::GENERATING, :deal_id => d.id)
    assert r.save
    # no coupon codes
    results = r.generate_results()
    assert_equal results.size, 0
    results = r.generate_results(:all => true)
    assert_equal results.size, 0    
    # add one unreserved code
    dc = DealCode.new(:deal_id => d.id, :code => 'abc123')
    assert dc.save
    results = r.generate_results
    assert_equal results.size, 0
    results = r.generate_results(:all => true)
    assert_equal results.size, 1
    assert_equal r.generate_row(results[0]), ["abc123", nil, nil, nil, ""]     
    # reserve (and authorize) it
    o = Order.new(:user_id => u.id, :deal_id => d.id)
    assert o.reserve_quantity(1)
    assert o.process_authorization(:gateway => 'authorize_net', :transaction_type => 'auth_only', :amount => '10.00', 
      :confirmation_code => 'XYZ123')
    authorized_at = o.authorized_at.strftime(OPTIONS[:time_format])
    results = r.generate_results
    assert_equal results.size, 1
    assert_equal r.generate_row(results[0]), ["abc123", u.email, u.first_name, u.last_name, authorized_at]
    results = r.generate_results(:all => true)
    assert_equal results.size, 1
    assert_equal r.generate_row(results[0]), ["abc123", u.email, u.first_name, u.last_name, authorized_at]
    # add another unreserved code
    dc = DealCode.new(:deal_id => d.id, :code => 'abc124')
    assert dc.save    
    results = r.generate_results
    assert_equal results.size, 1
    assert_equal r.generate_row(results[0]), ["abc123", u.email, u.first_name, u.last_name, authorized_at]
    results = r.generate_results(:all => true)
    assert_equal results.size, 2
    assert_equal r.generate_row(results[0]), ["abc123", u.email, u.first_name, u.last_name, authorized_at]
    assert_equal r.generate_row(results[1]), ["abc124", nil, nil, nil, ""] 
    # reserve (and authorize) it
    u2 = @test_user
    o = Order.new(:user_id => u2.id, :deal_id => d.id)
    assert o.reserve_quantity(1)
    assert o.process_authorization(:gateway => 'authorize_net', :transaction_type => 'auth_only', :amount => '10.00', 
      :confirmation_code => 'XYZ123')
    authorized_at2 = o.authorized_at.strftime(OPTIONS[:time_format])
    results = r.generate_results
    assert_equal results.size, 2
    assert_equal r.generate_row(results[0]), ["abc123", u.email, u.first_name, u.last_name, authorized_at]
    assert_equal r.generate_row(results[1]), ["abc124", u2.email, u2.first_name, u2.last_name, authorized_at2]
    assert_equal results.size, 2
    assert_equal r.generate_row(results[0]), ["abc123", u.email, u.first_name, u.last_name, authorized_at ]
    assert_equal r.generate_row(results[1]), ["abc124", u2.email, u2.first_name, u2.last_name, authorized_at2]        
  end
  
  # also test destroy
  def test_generate_report
    m = @emptybob
    d = Deal.new(:merchant_id => m.id, :title => 'dealio', :start_date => Time.zone.today.beginning_of_day, :end_date => Time.zone.today.end_of_day, 
      :expiration_date => Time.zone.today.end_of_day, :deal_price => '10.00', :deal_value => '20.00', :published => true, :max => 2)
    assert d.save
    r = MerchantReport.new(:merchant_id => m.id, :report_type => MerchantReport::COUPON_REPORT, :state => MerchantReport::GENERATING, :deal_id => d.id)
    assert r.save
    assert r.generate_report
    assert_equal r.state, MerchantReport::GENERATED
    assert_not_nil r.generated_at
    assert_not_nil r.report.url
    # tmp file is no longer there
    assert !File.exists?(OPTIONS[:temp_file_directory] + r.generate_file_name(r.generated_at))
    # paperclip file is there (local file for test environment)
    local_file = Rails.root + Pathname.new('public') + r.report.url.gsub(/^\/(.*)\?.*$/,'\1')
    assert File.exists?(local_file)
    # destroy - paperclip file is no longer there
    assert MerchantReport.destroy(r.id)
    assert !File.exists?(local_file)
  end

end
