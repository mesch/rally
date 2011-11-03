class ChangeDealsDateFormat < ActiveRecord::Migration
  def self.up
    change_column :deals, "start_date", :datetime
    change_column :deals, "end_date", :datetime
    change_column :deals, "expiration_date", :datetime  
  end

  def self.down
    change_column :deals, "start_date", :date
    change_column :deals, "end_date", :date
    change_column :deals, "expiration_date", :date
  end
end
