require_dependency 'time_entry'

module TimeEntryPatch
  def self.included(base)
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    base.class_eval do
      unloadable
      #if time entry is going to be changed, first the old one must be remove from monthly sum
      before_save :decrease_trans
      #and than add new one with new parameters
      after_save :increase_trans
      #if time entry is going to be deleted, first it must be remove from monthly sum
      before_destroy :decrease_trans
    end

  end
  
  module ClassMethods
    
  end
  
  module InstanceMethods
    def decrease_trans
      #if time_entry exist (no creating new)
      if self.id.present?
	#if time_entry was add to monthly sum
	if self.trans.present?
		#find time_entry by id
		entry = TimeEntry.find(self.id)
		#find time_entrys transaction
		trans = Transaction.find(entry.trans)
		#check if trans exist
		if trans.present?
			#find salary - between dates
			sal = Salary.where(:user_id => entry.user_id).where("valid_from <= ? AND valid_to >= ?",entry.spent_on,entry.spent_on).first()
			#or with no valid_to
			if sal.nil?
				sal = Salary.where(:user_id => entry.user_id).where("valid_from <= ? AND valid_to IS NULL",entry.spent_on).first()
			end
			#if salary exist
			if sal.present?
				#count sum
				amount = ((sal.hours_rate.to_i)*entry.hours).to_i
				#get old amount and increase it
				new_amount = trans.amount
				new_amount -= amount
				#if its last time_entry delete, otherwise update
				if new_amount == 0
					trans.destroy
				else
					trans.update_column(:amount,new_amount)
				end
			end
		end
		entry.update_column(:trans,nil)
		entry.update_column(:post,false)
	end
      end
    end
    def increase_trans
	#find time_entry by id
	entry = TimeEntry.find(self.id)
	#date of first day next month
	date = DateTime.new(entry.tyear,entry.tmonth,1) + 1.month
	#find issue - assigned trans to version
	iss = Issue.find(entry.issue_id)
	#find transaction for this date, user and type
	trans = Transaction.find(entry.trans) unless entry.trans.blank?
	if iss.nil? || iss.fixed_version_id.nil?
		trans = Transaction.where(:project_id => entry.project_id,:from_type => 3,:from_id => entry.user_id,:issuance_date => date,:version_id => nil).first() if entry.trans.blank?
	else
		trans = Transaction.where(:project_id => entry.project_id,:version_id => iss.fixed_version_id,:from_type => 3,:from_id => entry.user_id,:issuance_date => date).first() if entry.trans.blank?
	end
	#find salary - between dates
	sal = Salary.where(:user_id => entry.user_id).where("valid_from <= ? AND valid_to >= ?",entry.spent_on,entry.spent_on).first()
	#or with no valid_to
	if sal.nil?
		sal = Salary.where(:user_id => entry.user_id).where("valid_from <= ? AND valid_to IS NULL",entry.spent_on).first()
	end
	#if sal exist - if not, time_entry attribute transaction will be NULL, which gives warning in budget
	if sal.present?
		#count amount
		amount = ((sal.hours_rate.to_i)*entry.hours).to_i
		#if transaction doesnt exist - make one
		if trans.nil?
			#Is a category for payments set?
			category = Category.where(:payments => 1).first
			#if issue is not assigned to any version
			if iss.nil? || iss.fixed_version_id.nil?
				if category.present?
				trans = Transaction.new(:from_type => 3,:from_id => entry.user_id,:issuance_date => date,:typ => 1,:plan => 1,:name => "Payments",:amount => amount,:description => entry.id,:category_id => category.id)
				else
				trans = Transaction.new(:from_type => 3,:from_id => entry.user_id,:issuance_date => date,:typ => 1,:plan => 1,:name => "Payments",:amount => amount,:description => entry.id)
				end
				#protected attributes
				trans.project_id = entry.project_id
				trans.from_id = entry.user_id
				trans.save
			else
				if category.present?
				trans = Transaction.new(:from_type => 3,:from_id => entry.user_id,:issuance_date => date,:typ => 1,:plan => 1,:name => category.name,:amount => amount,:version_id => issue.fixed_version_id,:category_id => category.id)
				else
				trans = Transaction.new(:from_type => 3,:from_id => entry.user_id,:issuance_date => date,:typ => 1,:plan => 1,:name => "Payments",:amount => amount,:version_id => issue.fixed_version_id)
				end
				#protected attributes
				trans.project_id = entry.project_id
				trans.from_id = entry.user_id
				trans.save
			end
		else
			#if transaction exist add new amount
			amount += trans.amount
			#and update
			trans.update_column(:amount,amount)
		end
		#update time_entry with trans id - update_column skip callbacks - it would make a loop
		entry.update_column(:trans, trans.id)
		entry.update_column(:post, true)
	end
    end
  end
end

TimeEntry.send(:include, TimeEntryPatch)
