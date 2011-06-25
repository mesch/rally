class CreateUserActions < ActiveRecord::Migration
  def self.up
    create_table :user_actions do |t|
      t.integer     "visitor_id"
      t.integer     "user_id"
      t.integer     "merchant_id"
      t.integer     "deal_id"
      t.string      "controller"
      t.string      "action"
      t.string      "method"
      t.timestamps
    end
  end

  def self.down
    drop_table :user_actions
  end
end
