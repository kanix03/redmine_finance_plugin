class Contact < ActiveRecord::Base
  unloadable
  has_many :contact, :foreign_key => :parent_id, dependent: :destroy
  has_many :contact_project, dependent: :destroy
  has_many :transaction
 attr_accessible :company_name, :contact_person, :email, :phone, :street, :city, :state, :zip_code, :picture, :pemail, :pphone, :position, :contact_type, :parent_id, :ICO, :DIC, :account_number, :department, :def

  default_scope order('contacts.company_name,contacts.contact_person ASC')
  validates :company_name, presence: true, if: Proc.new { |a| a.contact_type == 0 }
  validates :contact_person, presence: true, if: Proc.new { |a| a.contact_type == 1 }
end
