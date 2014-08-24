class ContactProject < ActiveRecord::Base
  unloadable

  has_many :project, :foreign_key => :project_id
  belongs_to :contact, :foreign_key => :contact_id

  attr_accessible :project_id,:contact_id

end
