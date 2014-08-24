class CreateSalaries < ActiveRecord::Migration
  def change
    create_table :salaries do |t|
      t.integer :user_id
      t.date :valid_from
      t.date :valid_to
      t.decimal :hours_rate
      t.integer :active
    end
  end
end
