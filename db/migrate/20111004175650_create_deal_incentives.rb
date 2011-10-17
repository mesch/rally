class CreateDealIncentives < ActiveRecord::Migration
  def self.up
    create_table :deal_incentives do |t|
      t.integer     "deal_id"
      t.integer     "incentive_price_in_cents"
      t.integer     "incentive_value_in_cents"
      t.string      "metric_type"
      t.integer     "number_required"
      t.integer     "max",                      :default => 0
      t.timestamps
    end
  end

  def self.down
    drop_table :deal_incentives
  end
end
