require_dependency 'user'

module UserPatch
  def self.included(base)
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    base.class_eval do
      unloadable
      has_many :salary
      has_many :time_entries
    end

  end
  
  module ClassMethods
    
  end
  
  module InstanceMethods
    		
  end
end

User.send(:include, UserPatch)
