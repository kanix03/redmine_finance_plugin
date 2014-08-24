require_dependency 'issue'

module IssuePatch
  def self.included(base)
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    base.class_eval do
      unloadable
      after_save :check_version
    end

  end
  
  module ClassMethods
    
  end
  
  module InstanceMethods
    def check_version
	if self.id.present?
		iss = Issue.find(self.id)
		entry = TimeEntry.where(:issue_id => iss,:post => true).first()
		trans = Transaction.find(entry.trans)
		unless iss.fixed_version_id == trans.version_id
			entries = TimeEntry.where(:issue_id => iss,:post => true).uniq{|p| p.trans}
			entries.each do |e|
				if e.trans.present?
					trans = Transaction.find(e.trans)
					trans.update_attribute(:version_id, iss.fixed_version_id)
				end
			end
		end
        end
    end
  end
end

Issue.send(:include, IssuePatch)
