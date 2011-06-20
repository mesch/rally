class ProcessLog < ActiveRecord::Base
  validates_length_of :name, :maximum => 50
  validates_presence_of :name, :start_time, :end_time, :considered, :successes, :failures
  
  attr_protected :id
  
  def run_time
    return (self.end_time - self.start_time).round(1)
  end
  
  # returns any runs that have started within the range passed and have failures
  def self.failed_runs(options={})
    end_time = options[:end_time] ? options[:end_time] : Time.zone.now
    start_time = options[:start_time] ? options[:start_time] : end_time - 7.days
    return ProcessLog.find(:all, :conditions => ["start_time >= ? AND start_time <= ? AND failures > 0", start_time, end_time])
  end

end
