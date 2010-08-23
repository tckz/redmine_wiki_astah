class ChangePath < ActiveRecord::Migration
  def self.up
    change_column :astahs, :path, :string
  end

  def self.down
  end
end

# vim: set ts=2 sw=2 sts=2:

