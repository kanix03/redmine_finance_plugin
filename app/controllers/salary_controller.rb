class SalaryController < ApplicationController
  unloadable

  before_filter :global_authorize

 def global_authorize
   if User.current.allowed_to?({:controller => :salary, :action => self.action_name}, nil, {:global => true})
	@right_to_new_salary = User.current.allowed_to?({:controller => :salary, :action => :new}, nil, {:global => true})
	true
   elsif action_name.to_s == "index" || action_name.to_s == "show"
	if params[:id].to_i == User.current.id && action_name.to_s == "show"
		true
	else
		redirect_to salary_path(:id => User.current.id) 
	end
   else
 	render_403
   end
 end

  def index
   @users = User.where("status = 1").includes(:salary).order("users.lastname ASC,salaries.valid_from DESC")
  end

  def show
   @user = User.find(params[:id])
   @newsal = Salary.new() 
   @salaries = Salary.where(:user_id => params[:id]).order("valid_from DESC")
   @sal = Array.new
   @mon = Array.new
   @s = Salary.where(:user_id => params[:id]).limit(20).order("valid_from ASC")
   @s.each do |s|
     @mon << s.valid_from.to_s
     @sal << s.hours_rate
   end
   @trans = Transaction.where(:from_type => 3,:from_id => params[:id]).order("issuance_date ASC").select("issuance_date , sum(amount) as amount").group("issuance_date")
  end

  def new
   @salary = Salary.new() 
   @users = User.where("status = 1")
  end

  def create
   @salary = Salary.new(params[:salary])
   #error variable
   error = false
   if params[:salary][:valid_from].present? && params[:salary][:valid_to].present?
	#Overlap? => (StartA <= EndB) and (EndA >= StartB)
	sal = Salary.where(:user_id => @salary.user_id).where("valid_from <= ? AND valid_to >= ? ",params[:salary][:valid_to],params[:salary][:valid_from]).first
	if sal.present?
		error = true
	else
		#overlap with no end salary?
		sal = Salary.where(:user_id => @salary.user_id).where("valid_to IS NULL AND valid_from > ? AND valid_from < ? ",params[:salary][:valid_from],params[:salary][:valid_to]).first
		if sal.present?
			error = true
		else
			#if no end salary exist, end it
			sal = Salary.where(:user_id => @salary.user_id).where("valid_to IS NULL AND valid_from < ? ",params[:salary][:valid_from]).first
			if sal.present?
				sal.update_attribute(:valid_to,(params[:salary][:valid_from].to_date-1)) 
			end
		end
	end
   #no end salary
   elsif params[:salary][:valid_from].present?
	#overlap?
	sal = Salary.where(:user_id => @salary.user_id).where("valid_from > ? OR valid_to > ? ",params[:salary][:valid_from],params[:salary][:valid_from]).first
	if sal.present?
		error = true
	else
		#if no end salary exist, end it
		sal = Salary.where(:user_id => @salary.user_id).where("valid_to IS NULL").first
		if sal.present?
			sal.update_attribute(:valid_to,(params[:salary][:valid_from].to_date-1)) 
		end
	end
  else
	#valid_from missing
	error = true
  end
  respond_to do |format|
	unless error
		@salary.save
		create_timelogs
   		format.html { redirect_to salary_path(@salary.user_id), notice: 'salary was successfully created.' }
       		format.json { render json: @salary, status: :created, location: @salary }
      	else
        	format.html { redirect_to salary_path(@salary.user_id), alert: 'dates cannot overlap.'}
       		format.json { render json: @salary.errors, status: :unprocessable_entity }
      	end
  end
 end

  def edit
    @salary = Salary.find(params[:sal])
  end

  def update
	@salary = Salary.find(params[:sal])
	error = false
	if params[:salary][:valid_from].present? && params[:salary][:valid_to].present?
		#Overlap? => (StartA <= EndB) and (EndA >= StartB)
		sal = Salary.where(:user_id => @salary.user_id).where("valid_from <= ? AND valid_to >= ? ",params[:salary][:valid_to], params[:salary][:valid_from]).where("id != ? ",@salary.id).first
		if sal.present?
			error = true
		else
			#overlap with no end salary?
			sal = Salary.where(:user_id => @salary.user_id).where("valid_to IS NULL AND valid_from >= ? AND valid_from <= ? ",params[:salary][:valid_from], params[:salary][:valid_to]).where("id != ? ",@salary.id).first
			if sal.present?
				error = true
			end
		end
	elsif params[:salary][:valid_from].present?
		#overlap?
		sal = Salary.where(:user_id => @salary.user_id).where("valid_from >= ? OR valid_to >= ? ",params[:salary][:valid_from],params[:salary][:valid_from]).where("id != ? ",@salary.id).first
		if sal.present?
			error = true 
		end
	else
		#valid_from missing
		error = true
	end
	unless error
		#before deleting salary, remove timelogs from sums
		delete_timelogs
		@salary.update_attributes(params[:salary])
		#after updating salary, recalculate timelogs sums
		create_timelogs
		redirect_to salary_path(:id => @salary.user_id), notice: 'salary was successfully updated.'
	else
		redirect_to salary_path(:id => @salary.user_id), alert: 'dates cannot overlap.'
	end
  end

  def delete
	@salary = Salary.find(params[:sal])
	delete_timelogs
	@salary.destroy
	respond_to do |format|
        	format.html { redirect_to salary_path(params[:id]), notice: 'salary was successfully deleted.' }
       		format.json { head :no_content }
        end
  end
def create_timelogs
    #find time_entries for this salary
    if @salary.valid_to.nil?
	e = TimeEntry.where(:user_id => @salary.user_id,:post => false).where("spent_on >= ?",@salary.valid_from)
    else
	e = TimeEntry.where(:user_id => @salary.user_id,:post => false).where("spent_on >= ? AND spent_on <= ?",@salary.valid_from,@salary.valid_to)
    end
    unless e.nil?
	e.each do |r|
	    #find issue for this time entry
	    i = Issue.find(r.issue_id) if r.issue_id.present?
	    #date of first day next month
	    date = DateTime.new(r.tyear,r.tmonth,1) + 1.month
	    #find transaction for this date, user and type
	    t = Transaction.find(r.trans) unless r.trans.blank?
	    if i.nil? || i.fixed_version_id.nil?
		t = Transaction.where(:project_id => r.project_id,:from_type => 3,:from_id => r.user_id,:issuance_date => date).first() if r.trans.blank?
	    else
		t = Transaction.where(:project_id => r.project_id,:version_id => i.fixed_version_id,:from_type => 3,:from_id => r.user_id,:issuance_date => date).first() if r.trans.blank?
	    end
	    amount = ((@salary.hours_rate)*r.hours)
	    #if transaction doesnt exist - make one
	    if t.nil?
		p = Transaction.new(:from_type => 3,:from_id => r.user_id,:issuance_date => date,:typ => 1,:plan => 1,:name => "Payments",:amount => amount)
		#if issue is assigned to a version
		if i.present? && i.fixed_version_id.present?
			p.version_id = i.fixed_version_id
		end
		#Is a category for payments set?
		category = Category.where(:payments => 1).first
		if category.present?
			p.category_id = category.id
			p.name = category.name
		end
		#protected attributes
		p.project_id = r.project_id
		p.from_id = r.user_id
		p.save
	    else
		#if transaction exist add new amount
		amount += t.amount
		#and update
		t.update_attribute(:amount,amount)
 	    end
	    #update time_entry with post and trans id - update_column skip callbacks - it would make a loop
	    r.update_column(:post, true)
	    r.update_column(:trans, p.id) unless p.nil?
	 end
    end
  end
  
  def delete_timelogs
	#find time_entries for this salary
	if @salary.valid_to.nil?
		entry = TimeEntry.where(:user_id => @salary.user_id,:post => true).where("spent_on >= ?",@salary.valid_from)
	else
		entry = TimeEntry.where(:user_id => @salary.user_id,:post => true).where("spent_on >= ? AND spent_on <= ?",@salary.valid_from,@salary.valid_to)
	end
	entry.each do |r|
		#date of first day next month
		date = DateTime.new(r.tyear,r.tmonth,1) + 1.month
		#find transaction for this time entry
		t = Transaction.find(r.trans) unless r.trans.blank?
		amount = ((@salary.hours_rate)*r.hours)
		if t.present?
			#if transaction exist remove amount
			t.amount = t.amount - amount
			#if new amount is zero => delete transaction
			if t.amount == 0
				t.destroy
			else
			#otherwise update
				t.update_attribute(:amount,amount)
			end
		end
		#update time_entry with post and trans id - update_column skip callbacks - it would make a loop
	    	r.update_column(:post, false)
	    	r.update_column(:trans, nil)
	end
  end
end
