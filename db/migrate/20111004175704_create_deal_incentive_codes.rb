class CreateDealIncentiveCodes < ActiveRecord::Migration
  def self.up
    create_table :deal_incentive_codes do |t|
      t.integer  "deal_incentive_id"
      t.string   "code"
      t.boolean  "reserved",   :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :deal_incentive_codes
  end
end
