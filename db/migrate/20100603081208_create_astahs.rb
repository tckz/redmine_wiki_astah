class CreateAstahs < ActiveRecord::Migration
  def self.up
    create_table :astahs do |t|
			t.column "project_id", :integer, :null => false
			t.column "path", :string, :null => false
			t.column "retrieved", :timestamp
			t.column "exported", :timestamp
			t.column "last_message", :text
			t.column "last_hash", :string
			t.column "created_at", :timestamp
    end

			add_index "astahs", ["project_id", "path"], :name => "astahs_project_id", :unique => true
  end

  def self.down
    drop_table :astahs
  end
end

# vim: set ts=2 sw=2 sts=2:

