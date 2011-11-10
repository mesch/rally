class ChangeCodeText < ActiveRecord::Migration
  def self.up
    change_column :deal_codes, "code", :text
  end

  def self.down
        change_column :deal_codes, "code", :string
  end
end
