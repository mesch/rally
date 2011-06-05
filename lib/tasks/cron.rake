desc "This task is called by the Heroku cron add-on"
task :cron => :environment do
  if Time.now.hour % 1 == 0 # run every hour
    p "Resetting expired orders ..."
    start_time = Time.zone.now
    results = Order.reset_orders
    end_time = Time.zone.now
    ProcessLog.create(:name => 'reset_orders', :start_time => start_time, :end_time => end_time,
      :considered => results[:considered], :successes => results[:successes], :failures => results[:failures])    
    p "Done."
    
    p "Charging authorized orders ..."
    start_time = Time.zone.now
    results = Deal.charge_orders
    end_time = Time.zone.now
    ProcessLog.create(:name => 'charge_orders', :start_time => start_time, :end_time => end_time,
      :considered => results[:considered], :successes => results[:successes], :failures => results[:failures])
    p "Done."
    
  end
  
end