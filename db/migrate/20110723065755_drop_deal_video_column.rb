class DropDealVideoColumn < ActiveRecord::Migration
  def self.up
    remove_column :deals, "video"
  end

  def self.down
    add_column :deals, "video", :string
  end
end
