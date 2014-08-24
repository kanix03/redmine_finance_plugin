class Salary < ActiveRecord::Base
  unloadable
  belongs_to :user
  attr_accessible :user_id, :valid_from, :valid_to, :hours_rate, :active
  validates :user_id, :valid_from, :hours_rate, presence: true
  validates_numericality_of :hours_rate, :greater_than_or_equal_to => 0.01
end
