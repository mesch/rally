class AddVerisignTrusted < ActiveRecord::Migration
  def self.up
    add_column :merchants, "verisign_trusted", :boolean, :default => false
  end

  def self.down
    remove_column :merchants, "verisign_trusted"
  end
end
