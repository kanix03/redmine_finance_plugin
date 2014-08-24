class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.integer :project_id
      t.integer :version_id
      t.integer :category_id
      t.integer :plan
      t.integer :typ
      t.decimal :amount, :precision => 12, :scale => 2
      t.string :name
      t.string :description
      t.date :created_on
      t.date :updated_on
      t.date :issuance_date
      t.date :due_to
      t.date :paid_on
      t.integer :from_type
      t.integer :from_id
      t.integer :parent_id
      t.integer :period
      t.integer :period_end
      t.integer :between_project
    end
  end
end
