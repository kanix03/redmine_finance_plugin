class AddTransaction < ActiveRecord::Migration
  def up
    add_column :time_entries, :trans, :integer
  end

  def down
    remove_column :time_entries, :trans
  end
end
