class ChangePostIdToString < ActiveRecord::Migration
  def self.up
    change_column :shares, :post_id, :string
  end

  def self.down
    change_column :shares, :post_id, :integer, :limit => 8
  end
end
