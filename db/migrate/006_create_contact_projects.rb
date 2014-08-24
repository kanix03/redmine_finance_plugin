class CreateContactProjects < ActiveRecord::Migration
  def change
    create_table :contact_projects do |t|
      t.integer :contact_id
      t.integer :project_id
    end
  end
end
