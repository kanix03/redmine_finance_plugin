class CreateContacts < ActiveRecord::Migration
  def change
    create_table :contacts do |t|
      t.integer :contact_type
      t.string :company_name
      t.string :contact_person
      t.string :email
      t.string :phone
      t.string :street
      t.string :city
      t.integer :zip_code
      t.string :state
      t.string :ICO
      t.string :DIC
      t.string :account_number
      t.string :picture
      t.string :pemail
      t.string :pphone
      t.string :position
      t.integer :parent_id
      t.string :department
      t.integer :def
    end
  end
end
