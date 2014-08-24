class AddPost < ActiveRecord::Migration
  def up
    add_column :time_entries, :post, :boolean, default: false
  end

  def down
    remove_column :time_entries, :post
  end
end
