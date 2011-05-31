desc "This task is called by the Heroku cron add-on"
task :cron => :environment do
  if Time.now.hour % 1 == 0 # run every hour
    p "Resetting expired orders ..."
    Order.reset_orders
    p "Done."
    
    p "Charging authorized orders ..."
    Deal.charge_orders
    p "Done."
    
  end
  
end