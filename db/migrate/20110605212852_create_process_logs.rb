class CreateProcessLogs < ActiveRecord::Migration
  def self.up
    create_table :process_logs do |t|
      t.string    "name"
      t.timestamp "start_time"
      t.timestamp "end_time"
      t.integer   "considered"
      t.integer   "successes"
      t.integer   "failures"
      t.timestamps
    end
  end

  def self.down
    drop_table :process_logs
  end
end
