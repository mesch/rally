require 'test_helper'

class ProcessLogTest < ActiveSupport::TestCase
  self.use_instantiated_fixtures  = true
  
  def setup
    @start = Time.zone.now
    @end = Time.zone.now + 1.minutes
  end
  
  def test_process_log_create_basic
    pl = ProcessLog.new(:name => "reset_orders", :start_time => @start, :end_time => @end,
      :considered => 100, :successes => 98, :failures => 2)
    assert pl.save
  end
  
  def test_process_log_field_length
    string = ""
    length = 50
    length.times{ string << "a"}
    pl = ProcessLog.new(:name => string, :start_time => @start, :end_time => @end,
      :considered => 100, :successes => 98, :failures => 2)
    assert pl.save
    length = 51
    length.times{ string << "a"}
    pl = ProcessLog.new(:name => string, :start_time => @start, :end_time => @end,
      :considered => 100, :successes => 98, :failures => 2)
    assert !pl.save
  end
  
  def test_process_log_create_multiple
    pl = ProcessLog.new(:name => "reset_orders", :start_time => @start, :end_time => @end,
      :considered => 100, :successes => 98, :failures => 2)
    assert pl.save
    # same record - ok
    pl = ProcessLog.new(:name => "reset_orders", :start_time => @start, :end_time => @end,
      :considered => 100, :successes => 98, :failures => 2)
    assert pl.save      
  end
  
  def test_process_log_missing_fields
    pl = ProcessLog.new(:name => nil, :start_time => @start, :end_time => @end,
      :considered => 100, :successes => 98, :failures => 2)
    assert !pl.save
    pl = ProcessLog.new(:name => "reset_orders", :start_time => nil, :end_time => @end,
      :considered => 100, :successes => 98, :failures => 2)
    assert !pl.save
    pl = ProcessLog.new(:name => "reset_orders", :start_time => @start, :end_time => nil,
      :considered => 100, :successes => 98, :failures => 2)
    assert !pl.save
    pl = ProcessLog.new(:name => "reset_orders", :start_time => @start, :end_time => @end,
      :considered => nil, :successes => 98, :failures => 2)
    assert !pl.save
    pl = ProcessLog.new(:name => "reset_orders", :start_time => @start, :end_time => @end,
      :considered => 100, :successes => nil, :failures => 2)
    assert !pl.save
    pl = ProcessLog.new(:name => "reset_orders", :start_time => @start, :end_time => @end,
      :considered => 100, :successes => 98, :failures => nil)
    assert !pl.save
  end
  
  def test_process_log_run_time
    pl = ProcessLog.new(:name => "reset_orders", :start_time => @start, :end_time => @end,
      :considered => 100, :successes => 98, :failures => 2)
    assert pl.save
    assert_equal pl.run_time, 60.0
  end
  
  def test_process_log_failed_runs
    pl = ProcessLog.new(:name => "reset_orders", :start_time => @start, :end_time => @end,
      :considered => 100, :successes => 98, :failures => 2)    
    pl.save
    failed_runs = ProcessLog.failed_runs
    assert_equal failed_runs.length, 1
    failed_runs = ProcessLog.failed_runs(:end_time => @start + 1.minutes, :start_time => @start - 1.minutes)
    assert_equal failed_runs.length, 1    
    failed_runs = ProcessLog.failed_runs(:end_time => @start - 1.minutes)
    assert_equal failed_runs.length, 0
    failed_runs = ProcessLog.failed_runs(:end_time => @start + 1.minutes, :start_time => @start + 1.minutes)
    assert_equal failed_runs.length, 0    
    # add another - +1
    pl = ProcessLog.new(:name => "reset_orders", :start_time => @start, :end_time => @end,
      :considered => 100, :successes => 98, :failures => 2)
    pl.save
    failed_runs = ProcessLog.failed_runs
    assert_equal failed_runs.length, 2    
    # add a run with no failures - +0
    pl = ProcessLog.new(:name => "reset_orders", :start_time => @start, :end_time => @end,
      :considered => 100, :successes => 100, :failures => 0)
    pl.save    
    failed_runs = ProcessLog.failed_runs
    assert_equal failed_runs.length, 2
  end 
  
end