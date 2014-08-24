class Transaction < ActiveRecord::Base
  unloadable
  belongs_to :project
  belongs_to :version
  belongs_to :contact, :foreign_key => :from_id
  belongs_to :user, :foreign_key => :from_id
  belongs_to :contact, :foreign_key => :from_id
  belongs_to :project_from, :class_name => 'Project', :foreign_key => :from_id
  belongs_to :category

  attr_accessible :typ, :version_id, :category_id, :name, :description, :amount, :issuance_date, :due_to, :paid_on, :from_type, :from_id, :plan, :period, :period_parent_id, :period_start, :period_end


  validates :plan,:typ,:name, :amount,:issuance_date,:from_type,:from_id, presence: true
  validates_numericality_of :amount, :greater_than_or_equal_to => 0.01
  validates_numericality_of :typ, :only_integer => true, :greater_than_or_equal_to => 0,:less_than_or_equal_to => 1, :message => "is not selected"
end
