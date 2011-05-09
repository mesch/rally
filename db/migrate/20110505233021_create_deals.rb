class CreateDeals < ActiveRecord::Migration
  def self.up
    create_table :deals do |t|
      t.integer     "merchant_id"
      t.string      "title"
      t.date        "start_date"
      t.date        "end_date"
      t.date        "expiration_date"
      t.integer     "deal_price_in_cents"
      t.integer     "deal_value_in_cents"
      t.integer     "max",          :default => 0
      t.integer     "limit",        :default => 1
      t.text        "description"
      t.text        "terms"
      t.string      "video"
      t.boolean     "active",       :default => true
      t.timestamps
    end
    
    add_index :deals, :merchant_id
  end

  def self.down
    remove_index :deals, :merchant_id
    
    drop_table :deals
  end
end
