class Category < ActiveRecord::Base
  unloadable

  has_many :transaction
end
