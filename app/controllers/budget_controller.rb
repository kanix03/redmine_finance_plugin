class BudgetController < ApplicationController
  unloadable

  before_filter :find_project,:authorize

 def find_project
    @project = Project.find(params[:id])
 end

  def index
    #find main project
    @project = Project.find(params[:id])
    @projects = Array.new
    #get main project hierarchy
    @hierarchy = @project.self_and_descendants
    #get where clause for search form
    get_query
    #get default kpi values if not set in configuration
    get_kpi_defaults
    #get sums for project
    get_this_project_sums
    @versions = Version.where(:project_id => @project)
    get_this_project_versions_sums
    @missing_salaries = User.includes(:time_entries).where("time_entries.post = false").where("time_entries.project_id IN (?) ",@hierarchy)
    #get sums for subprojects
    subprojects = @project.children
    subprojects.each do |p|
	@projects << p.id
	r = p.self_and_descendants
	versions = Version.where(:project_id => p)
	#sums for whole project
	plan_income = Transaction.where(:project_id => r,:typ => 0,:plan => 0).where(@query).sum(:amount)
	plan_expense = Transaction.where(:project_id => r,:typ => 1,:plan => 0).where(@query).sum(:amount)
	real_income = Transaction.where(:project_id => r,:typ => 0,:plan => 1).where(@query).sum(:amount)
	real_expense = Transaction.where(:project_id => r,:typ => 1,:plan => 1).where(@query).sum(:amount)
	if @project.id == p.id
	@sums_array << ["pr",p.id,p.name,plan_income,plan_expense,real_income,real_expense]
	else
	@sums_array << ["p",p.id,p.name,plan_income,plan_expense,real_income,real_expense]
	end
    end
    @categories = Category.all
    @real = Transaction.includes(:category).where(:project_id => @projects,:plan => 1).where(@query).order(params[:order])
    @plan = Transaction.includes(:category).where(:project_id => @projects,:plan => 0).where(@query).order(params[:order2])
    rsi = Transaction.where(:plan => 1,:typ => 0,:project_id => @projects).where(@query).sum(:amount)
    rse = Transaction.where(:plan => 1,:typ => 1,:project_id => @projects).where(@query).sum(:amount)
    @real_sum = (rsi - rse)
    psi = Transaction.where(:plan => 0,:typ => 0,:project_id => @projects).where(@query).sum(:amount)
    pse = Transaction.where(:plan => 0,:typ => 1,:project_id => @projects).where(@query).sum(:amount)
    @plan_sum = (psi - pse)
    #data for line chart
    @plan_income = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(@query).where(:project_id => @projects,:plan => 0,:typ => 0).order(:issuance_date)
    @plan_expense = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(@query).where(:project_id => @projects,:plan => 0,:typ => 1).order(:issuance_date)
    @real_income = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(@query).where(:project_id => @projects,:plan => 1,:typ => 0).order(:issuance_date)
    @real_expense = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(@query).where(:project_id => @projects,:plan => 1,:typ => 1).order(:issuance_date)
    #get all dates
    dates = []
    @plan_income.each do |p|
	dates << p.issuance_date unless dates.include?(p.issuance_date)
    end
    @plan_expense.each do |p|
	dates << p.issuance_date unless dates.include?(p.issuance_date)
    end
    @real_income.each do |p|
	dates << p.issuance_date unless dates.include?(p.issuance_date)
    end
    @real_expense.each do |p|
	dates << p.issuance_date unless dates.include?(p.issuance_date)
    end
    @dates = dates.sort
    @ri = Array.new 
    @re = Array.new 
    @pi = Array.new 
    @pe = Array.new
    @ria = 0 
    @rea = 0 
    @pia = 0 
    @pea = 0
    unless @dates.first.nil?
    h = [(@dates.first-1),0]
    @pe << h
    @re << h
    @ri << h
    @pi << h
    end
    @dates.each do |d| 
	f = 0
	@plan_expense.each do |a| 
		if a.issuance_date == d
			@pea += a.amount
			if a.issuance_date.to_date == @pe.last[0].to_date
				@pe.last[1] += a.amount
				@pe.last[2] += "-:-"+a.amount.to_s+' - '+a.name.to_s
			else
				h = [a.issuance_date,@pea,a.amount.to_s+' - '+a.name.to_s]
				@pe << h
			end
			f = 1
		end
	end 
	if f == 0 
		h = [d,@pea]
		@pe << h
	end
	f = 0
	@plan_income.each do |a| 
		if a.issuance_date == d
			@pia += a.amount
			if a.issuance_date.to_date == @pi.last[0].to_date
				@pi.last[1] += a.amount
				@pi.last[2] += "-:-"+a.amount.to_s+' - '+a.name.to_s
			else
				h = [a.issuance_date,@pia,a.amount.to_s+' - '+a.name.to_s]
				@pi << h
			end
			f = 1
		end
	end 
	if f == 0 
		h = [d,@pia]
		@pi << h
	end
	f = 0
	@real_expense.each do |a| 
		if a.issuance_date == d
			@rea += a.amount
			if a.issuance_date.to_date == @re.last[0].to_date
				@re.last[1] += a.amount
				@re.last[2] += "-:-"+a.amount.to_s+' - '+a.name.to_s
			else
				h = [a.issuance_date,@rea,a.amount.to_s+' - '+a.name.to_s]
				@re << h
			end
			f = 1
		end
	end 
	if f == 0 
		h = [d,@rea]
		@re << h
	end
	f = 0
	@real_income.each do |a| 
		if a.issuance_date == d
			@ria += a.amount
			if a.issuance_date.to_date == @ri.last[0].to_date
				@ri.last[1] += a.amount
				@ri.last[2] += "-:-"+a.amount.to_s+' - '+a.name.to_s
			else
				h = [a.issuance_date,@ria,a.amount.to_s+' - '+a.name.to_s]
				@ri << h
			end
			f = 1
		end
	end 
	if f == 0 
		h = [d,@ria]
		@ri << h
	end
    end
    #### End line chart data
    @activit = Enumeration.where(:type => "TimeEntryActivity")
    @activity = []
    @activity2 = []
    @mem = User.includes(:members).where("members.project_id = " + @project.id.to_s)
    @a = Array.new()
    @suma3 = 0
    @hours_sum = 0
    @mem.each do |m|
	suma1 = 0
	suma2 = 0
	suma3 = 0
	suma4 = 0
	t =  TimeEntry.where(:user_id => m.id).where("project_id = ?",@project.id.to_s)
        t.each do |e|
		s = Salary.where(:user_id => m.id).where("valid_from <= ? AND valid_to >= ?",e.spent_on,e.spent_on).first()
		if s.nil?
			s = Salary.where(:user_id => m.id).where("valid_from <= ? AND valid_to IS NULL",e.spent_on).first()
		end
		if s.present?
			suma1 += (s.hours_rate.to_i)*e.hours
			if (e.tyear == Time.now.year && e.tmonth == Time.now.month)
				suma2 += (s.hours_rate.to_i)*e.hours
			end
			if @activity[e.activity_id].nil? 
				@activity[e.activity_id] = 0 
			end
			@activity[e.activity_id] += (s.hours_rate.to_i)*e.hours
			if @activity2[e.activity_id].nil? 
				@activity2[e.activity_id] = 0 
			end
			@activity2[e.activity_id] += e.hours
		end
		suma3 += e.hours
		if (e.tyear == Time.now.year && e.tmonth == Time.now.month)
			suma4 += e.hours
		end
	end
		h = [m.id,m.lastname+' '+m.firstname,suma1,suma2,suma3,suma4]
		@a << h
		@hours_sum += suma3
		@suma3 += suma1
    end
    ### Data for expense by categories pie chart
    categories = Category.all
    @expense_by_categories = Array.new
    sum = Transaction.where("category_id IS NULL").where(:typ => 1,:project_id => @projects,:plan => 1).sum(:amount)
    unless sum == 0
        @expense_by_categories << [0, "No category", sum]
    end
    categories.each do |c|
	sum = Transaction.where(:category_id => c.id,:typ => 1,:project_id => @projects,:plan => 1).sum(:amount)
        @expense_by_categories << [c.id,c.name,sum]
    end
    ###
    get_users_expenses_chart_data()
  end

  def get_users_expenses_chart_data()
        @users_expenses_chart_data = Array.new
	@project.members.each do |member|
		amount = Transaction.where(:project_id => @hierarchy,:from_type => 3,:from_id => member.user.id).sum(:amount)
		@users_expenses_chart_data << {"user" => member.user.lastname, "amount" => amount}
	end
	
        
  end

  def show
    get_query
    get_kpi_defaults
    @project = Project.find(params[:id])
    @versions = Version.where(:project_id => @project)
    @version = Version.find(params[:idv])
    @real = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(:version_id => params[:idv],:project_id => @project,:plan => 1).where(@query).order(params[:order])
    @rsi = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(:version_id => params[:idv],:plan => 1,:project_id => @project,:typ => 0).where(@query).sum(:amount)
    @rse = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(:version_id => params[:idv],:plan => 1,:project_id => @project,:typ => 1).where(@query).sum(:amount)
    @real_sum = (@rsi - @rse)
    @plan = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(:version_id => params[:idv],:project_id => @project,:plan => 0).where(@query).order(params[:order2])
    @psi = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(:version_id => params[:idv],:plan => 0,:project_id => @project,:typ => 0).where(@query).sum(:amount)
    @pse = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(:version_id => params[:idv],:plan => 0,:project_id => @project,:typ => 1).where(@query).sum(:amount)
    @categories = Category.all
    @plan_sum = (@psi - @pse)
    @mem = User.includes(:members).where("members.project_id = " + @project.id.to_s)
    @first_issue = Issue.where(:fixed_version_id => params[:idv]).order(:start_date).first
    @a = Array.new()
    @mem.each do |m|
	suma1 = 0
	suma2 = 0
	suma3 = 0
	suma4 = 0
	t =  TimeEntry.where(:user_id => m.id).includes(:issue).where("issues.fixed_version_id = ?",params[:idv])
        t.each do |e|
		s = Salary.where(:user_id => m.id).where("valid_from <= ? AND valid_to >= ?",e.spent_on,e.spent_on).first()
		if s.nil?
			s = Salary.where(:user_id => m.id).where("valid_from <= ? AND valid_to IS NULL",e.spent_on).first()
		end
		if s.present?
			suma1 += (s.hours_rate.to_i)*e.hours
			if (e.tyear == Time.now.year && e.tmonth == Time.now.month)
				suma2 += (s.hours_rate.to_i)*e.hours
			end
		end
		suma3 += e.hours
		if (e.tyear == Time.now.year && e.tmonth == Time.now.month)
			suma4 += e.hours
		end
	end
		h = [m.id,m.lastname+' '+m.firstname,suma1,suma2,suma3,suma4]
		@a << h
    end
@plan_income = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(:version_id => @version.id,:plan => 0,:typ => 0).where(@query).order(:issuance_date)
    @plan_expense = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(:version_id => @version.id,:plan => 0,:typ => 1).where(@query).order(:issuance_date)
    @real_income = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(:version_id => @version.id,:plan => 1,:typ => 0).where(@query).order(:issuance_date)
    @real_expense = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(:version_id => @version.id,:plan => 1,:typ => 1).where(@query).order(:issuance_date)

    dates = []
    @plan_income.each do |p|
	unless dates.include?(p.issuance_date)
		dates << p.issuance_date
	end
    end
    @plan_expense.each do |p|
	unless dates.include?(p.issuance_date)
		dates << p.issuance_date
	end
    end
    @real_income.each do |p|
	unless dates.include?(p.issuance_date)
		dates << p.issuance_date
	end
    end
    @real_expense.each do |p|
	unless dates.include?(p.issuance_date)
		dates << p.issuance_date
	end
    end
    @dates = dates.sort
    @ri = Array.new 
    @re = Array.new 
    @pi = Array.new 
    @pe = Array.new
    @ria = 0 
    @rea = 0 
    @pia = 0 
    @pea = 0
    unless @dates.first.nil?
    h = [(@dates.first-1),0]
    end
    @pe << h
    @re << h
    @ri << h
    @pi << h
    @dates.each do |d| 
	f = 0
	@plan_expense.each do |a| 
		if a.issuance_date == d
			@pea += a.amount
			if a.issuance_date.to_date == @pe.last[0].to_date
				@pe.last[1] += a.amount
				@pe.last[2] += "-:-"+a.amount.to_s+' - '+a.name.to_s
			else
				h = [a.issuance_date,@pea,a.amount.to_s+' - '+a.name.to_s]
				@pe << h
			end
			f = 1
		end
	end 
	if f == 0 
		h = [d,@pea]
		@pe << h
	end
	f = 0
	@plan_income.each do |a| 
		if a.issuance_date == d
			@pia += a.amount
			if a.issuance_date.to_date == @pi.last[0].to_date
				@pi.last[1] += a.amount
				@pi.last[2] += "-:-"+a.amount.to_s+' - '+a.name.to_s
			else
				h = [a.issuance_date,@pia,a.amount.to_s+' - '+a.name.to_s]
				@pi << h
			end
			f = 1
		end
	end 
	if f == 0 
		h = [d,@pia]
		@pi << h
	end
	f = 0
	@real_expense.each do |a| 
		if a.issuance_date == d
			@rea += a.amount
			if a.issuance_date.to_date == @re.last[0].to_date
				@re.last[1] += a.amount
				@re.last[2] += "-:-"+a.amount.to_s+' - '+a.name.to_s
			else
				h = [a.issuance_date,@rea,a.amount.to_s+' - '+a.name.to_s]
				@re << h
			end
			f = 1
		end
	end 
	if f == 0 
		h = [d,@rea]
		@re << h
	end
	f = 0
	@real_income.each do |a| 
		if a.issuance_date == d
			@ria += a.amount
			if a.issuance_date.to_date == @ri.last[0].to_date
				@ri.last[1] += a.amount
				@ri.last[2] += "-:-"+a.amount.to_s+' - '+a.name.to_s
			else
				h = [a.issuance_date,@ria,a.amount.to_s+' - '+a.name.to_s]
				@ri << h
			end
			f = 1
		end
	end 
	if f == 0 
		h = [d,@ria]
		@ri << h
	end
    end
#####
    @activit = Enumeration.where(:type => "TimeEntryActivity")
    @activity = []
    @activity2 = []
    @mem = User.includes(:members).where("members.project_id = " + @project.id.to_s)
    @ar = Array.new()
    @suma3 = 0
    @hours_sum = 0
    @mem.each do |m|
	suma1 = 0
	suma2 = 0
	t =  TimeEntry.includes(:issue).where(:user_id => m.id).where("time_entries.project_id = ?",@project.id.to_s).where("issues.fixed_version_id = ?",@version.id)
        t.each do |e|
		s = Salary.where(:user_id => m.id).where("valid_from <= ? AND valid_to >= ?",e.spent_on,e.spent_on).first()
		if s.nil?
			s = Salary.where(:user_id => m.id).where("valid_from <= ? AND valid_to IS NULL",e.spent_on).first()
		end
		if s.present?
			suma1 += (s.hours_rate.to_i)*e.hours
			if @activity[e.activity_id].nil? 
				@activity[e.activity_id] = 0 
			end
			@activity[e.activity_id] += (s.hours_rate.to_i)*e.hours
			if @activity2[e.activity_id].nil? 
				@activity2[e.activity_id] = 0 
			end
			@activity2[e.activity_id] += e.hours
		end
		suma2 += e.hours
	end
		h = [m.lastname+' '+m.firstname,suma1,suma2]
		@ar << h
		@hours_sum += suma2
		@suma3 += suma1
    end
#####
    ### Data for expense by categories pie chart
    categories = Category.all
    @expense_by_categories = Array.new
    sum = Transaction.where("category_id IS NULL").where(:typ => 1,:project_id => @project,:plan => 1, :version_id => @version).sum(:amount)
    @sums_array = Array.new
    unless sum == 0
        @expense_by_categories << [0,"No category",sum]
	@sums_array << [0,"No category","No category","No category","No category","No category",sum]
    end
    categories.each do |c|
	sum = Transaction.where(:category_id => c.id,:typ => 1,:project_id => @project,:plan => 1,:version_id => @version).sum(:amount)
        @expense_by_categories << [c.id,c.name,sum]
        @sums_array << [c.id,c.name,c.name,c.name,c.name,c.name,sum]
    end
    ### 
  end

  def show_all
    #find main project
    @project = Project.find(params[:id])
    @projects = Array.new
    #hierarchy = only this project
    @hierarchy = @project
    #get where clause for search form
    get_query
    #get default kpi values if not set in configuration
    get_kpi_defaults
    #get sums for project
    get_this_project_sums
    @versions = Version.where(:project_id => @project)
    get_this_project_versions_sums

    @real = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(:project_id => @project,:plan => 1).where(@query).order(params[:order])
    @rsi = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(:plan => 1,:project_id => @project,:typ => 0).where(@query).sum(:amount)
    @rse = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(:plan => 1,:project_id => @project,:typ => 1).where(@query).sum(:amount)
    @real_sum = (@rsi - @rse)
    @plan = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(:project_id => @project,:plan => 0).where(@query).order(params[:order2])
    @psi = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(:plan => 0,:project_id => @project,:typ => 0).where(@query).sum(:amount)
    @pse = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(:plan => 0,:project_id => @project,:typ => 1).where(@query).sum(:amount)
    @plan_sum = (@psi - @pse)
@plan_income = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(:project_id => @project.id,:plan => 0,:typ => 0).where(@query).order(:issuance_date)
    @plan_expense = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(:project_id => @project.id,:plan => 0,:typ => 1).where(@query).order(:issuance_date)
    @real_income = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(:project_id => @project.id,:plan => 1,:typ => 0).where(@query).order(:issuance_date)
    @real_expense = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(:project_id => @project.id,:plan => 1,:typ => 1).where(@query).order(:issuance_date)

    dates = []
    @plan_income.each do |p|
	unless dates.include?(p.issuance_date)
		dates << p.issuance_date
	end
    end
    @plan_expense.each do |p|
	unless dates.include?(p.issuance_date)
		dates << p.issuance_date
	end
    end
    @real_income.each do |p|
	unless dates.include?(p.issuance_date)
		dates << p.issuance_date
	end
    end
    @real_expense.each do |p|
	unless dates.include?(p.issuance_date)
		dates << p.issuance_date
	end
    end
    @dates=dates.sort
    @ri = Array.new 
    @re = Array.new 
    @pi = Array.new 
    @pe = Array.new
    @ria = 0 
    @rea = 0 
    @pia = 0 
    @pea = 0
    unless @dates.first.nil?
    h = [(@dates.first-1),0]
    end
    @pe << h
    @re << h
    @ri << h
    @pi << h
    @dates.each do |d| 
	f = 0
	@plan_expense.each do |a| 
		if a.issuance_date == d
			@pea += a.amount
			if a.issuance_date.to_date == @pe.last[0].to_date
				@pe.last[1] += a.amount
				@pe.last[2] += "-:-"+a.amount.to_s+' - '+a.name.to_s
			else
				h = [a.issuance_date,@pea,a.amount.to_s+' - '+a.name.to_s]
				@pe << h
			end
			f = 1
		end
	end 
	if f == 0 
		h = [d,@pea]
		@pe << h
	end
	f = 0
	@plan_income.each do |a| 
		if a.issuance_date == d
			@pia += a.amount
			if a.issuance_date.to_date == @pi.last[0].to_date
				@pi.last[1] += a.amount
				@pi.last[2] += "-:-"+a.amount.to_s+' - '+a.name.to_s
			else
				h = [a.issuance_date,@pia,a.amount.to_s+' - '+a.name.to_s]
				@pi << h
			end
			f = 1
		end
	end 
	if f == 0 
		h = [d,@pia]
		@pi << h
	end
	f = 0
	@real_expense.each do |a| 
		if a.issuance_date == d
			@rea += a.amount
			if a.issuance_date.to_date == @re.last[0].to_date
				@re.last[1] += a.amount
				@re.last[2] += "-:-"+a.amount.to_s+' - '+a.name.to_s
			else
				h = [a.issuance_date,@rea,a.amount.to_s+' - '+a.name.to_s]
				@re << h
			end
			f = 1
		end
	end 
	if f == 0 
		h = [d,@rea]
		@re << h
	end
	f = 0
	@real_income.each do |a| 
		if a.issuance_date == d
			@ria += a.amount
			if a.issuance_date.to_date == @ri.last[0].to_date
				@ri.last[1] += a.amount
				@ri.last[2] += "-:-"+a.amount.to_s+' - '+a.name.to_s
			else
				h = [a.issuance_date,@ria,a.amount.to_s+' - '+a.name.to_s]
				@ri << h
			end
			f = 1
		end
	end 
	if f == 0 
		h = [d,@ria]
		@ri << h
	end
    end
    @categories = Category.all
    @plan_sum = (@psi - @pse)


    @mem = User.includes(:members).where("members.project_id = " + @project.id.to_s)
    @first_issue = Issue.where(:fixed_version_id => params[:idv]).order(:start_date).first
    @a = Array.new()
    @activit = Enumeration.where(:type => "TimeEntryActivity")
    @activity = []
    @activity2 = []
@ar = Array.new()
    @suma3 = 0
    @hours_sum = 0
    @mem.each do |m|
	suma1 = 0
	suma2 = 0
	suma3 = 0
	suma4 = 0
	t =  TimeEntry.where(:user_id => m.id).includes(:issue).where("issues.project_id = ?",@project.id)
        t.each do |e|
		s = Salary.where(:user_id => m.id).where("valid_from <= ? AND valid_to >= ?",e.spent_on,e.spent_on).first()
		if s.nil?
			s = Salary.where(:user_id => m.id).where("valid_from <= ? AND valid_to IS NULL",e.spent_on).first()
		end
		if s.present?
			suma1 += (s.hours_rate.to_i)*e.hours
			if (e.tyear == Time.now.year && e.tmonth == Time.now.month)
				suma2 += (s.hours_rate.to_i)*e.hours
			end
			if @activity[e.activity_id].nil? 
				@activity[e.activity_id] = 0 
			end
			@activity[e.activity_id] += (s.hours_rate.to_i)*e.hours
			if @activity2[e.activity_id].nil? 
				@activity2[e.activity_id] = 0 
			end
			@activity2[e.activity_id] += e.hours
		end
		suma3 += e.hours
		if (e.tyear == Time.now.year && e.tmonth == Time.now.month)
			suma4 += e.hours
		end
	end
		h = [m.id,m.lastname+' '+m.firstname,suma1,suma2,suma3,suma4]
		@a << h
		h = [m.lastname+' '+m.firstname,suma1,suma2]
		@ar << h
		@hours_sum += suma2
		@suma3 += suma1
    end
    ### Data for expense by categories pie chart
    categories = Category.all
    @expense_by_categories = Array.new
    sum = Transaction.where("category_id IS NULL").where(:typ => 1,:project_id => @project,:plan => 1).sum(:amount)
    unless sum == 0
        @expense_by_categories << [0,"No category",sum]
    end
    categories.each do |c|
	sum = Transaction.where(:category_id => c.id,:typ => 1,:project_id => @project,:plan => 1).sum(:amount)
        @expense_by_categories << [c.id,c.name,sum]
    end
    ### 
  end

  def show_no_version
    get_kpi_defaults
    get_query
    @project = Project.find(params[:id])
    @versions = Version.where(:project_id => @project)
    @real = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where("version_id IS NULL").where(:project_id => @project,:plan => 1).where(@query).order(params[:order])
    @rsi = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(:plan => 1,:project_id => @project,:typ => 0).where("version_id IS NULL").where(@query).sum(:amount)
    @rse = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(:plan => 1,:project_id => @project,:typ => 1).where("version_id IS NULL").where(@query).sum(:amount)
    @real_sum = (@rsi - @rse)
    @plan = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where("version_id IS NULL").where(:project_id => @project,:plan => 0).where(@query).order(params[:order2])
    @psi = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where("version_id IS NULL").where(:plan => 0,:project_id => @project,:typ => 0).where(@query).sum(:amount)
    @pse = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where("version_id IS NULL").where(:plan => 0,:project_id => @project,:typ => 1).where(@query).sum(:amount)
    @categories = Category.all
    @plan_sum = (@psi - @pse)
    @mem = User.includes(:members).where("members.project_id = " + @project.id.to_s)
    @a = Array.new()
   @activit = Enumeration.where(:type => "TimeEntryActivity")
    @activity = []
    @activity2 = []
    @ar = Array.new()
    @suma3 = 0
    @hours_sum = 0
    @mem.each do |m|
	suma1 = 0
	suma2 = 0
	suma3 = 0
	suma4 = 0
	t =  TimeEntry.where(:user_id => m.id).includes(:issue).where("issues.fixed_version_id IS NULL && issues.project_id = ?",@project.id)
        t.each do |e|
		s = Salary.where(:user_id => m.id).where("valid_from <= ? AND valid_to >= ?",e.spent_on,e.spent_on).first()
		if s.nil?
			s = Salary.where(:user_id => m.id).where("valid_from <= ? AND valid_to IS NULL",e.spent_on).first()
		end
		if s.present?
			suma1 += (s.hours_rate.to_i)*e.hours
			if (e.tyear == Time.now.year && e.tmonth == Time.now.month)
				suma2 += (s.hours_rate.to_i)*e.hours
			end
			if @activity[e.activity_id].nil? 
				@activity[e.activity_id] = 0 
			end
			@activity[e.activity_id] += (s.hours_rate.to_i)*e.hours
			if @activity2[e.activity_id].nil? 
				@activity2[e.activity_id] = 0 
			end
			@activity2[e.activity_id] += e.hours
		end
		suma3 += e.hours
		if (e.tyear == Time.now.year && e.tmonth == Time.now.month)
			suma4 += e.hours
		end
	end
		h = [m.id,m.lastname+' '+m.firstname,suma1,suma2,suma3,suma4]
		@a << h
		h = [m.lastname+' '+m.firstname,suma1,suma2]
		@ar << h
		@hours_sum += suma3
		@suma3 += suma1
    end
@plan_income = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(:project_id => @project.id,:plan => 0,:typ => 0).where("version_id IS NULL").where(@query).order(:issuance_date)
    @plan_expense = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(:project_id => @project.id,:plan => 0,:typ => 1).where("version_id IS NULL").where(@query).order(:issuance_date)
    @real_income = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(:project_id => @project.id,:plan => 1,:typ => 0).where("version_id IS NULL").where(@query).order(:issuance_date)
    @real_expense = Transaction.includes(:contact).includes(:user).includes(:category).includes(:project_from).where(:project_id => @project.id,:plan => 1,:typ => 1).where("version_id IS NULL").where(@query).order(:issuance_date)

    dates = []
    @plan_income.each do |p|
	unless dates.include?(p.issuance_date)
		dates << p.issuance_date
	end
    end
    @plan_expense.each do |p|
	unless dates.include?(p.issuance_date)
		dates << p.issuance_date
	end
    end
    @real_income.each do |p|
	unless dates.include?(p.issuance_date)
		dates << p.issuance_date
	end
    end
    @real_expense.each do |p|
	unless dates.include?(p.issuance_date)
		dates << p.issuance_date
	end
    end
    @dates=dates.sort
    @ri = Array.new 
    @re = Array.new 
    @pi = Array.new 
    @pe = Array.new
    @ria = 0 
    @rea = 0 
    @pia = 0 
    @pea = 0
    unless @dates.first.nil?
    h = [(@dates.first-1),0]
    end
    @pe << h
    @re << h
    @ri << h
    @pi << h
    @dates.each do |d| 
	f = 0
	@plan_expense.each do |a| 
		if a.issuance_date == d
			@pea += a.amount
			if a.issuance_date.to_date == @pe.last[0].to_date
				@pe.last[1] += a.amount
				@pe.last[2] += "-:-"+a.amount.to_s+' - '+a.name.to_s
			else
				h = [a.issuance_date,@pea,a.amount.to_s+' - '+a.name.to_s]
				@pe << h
			end
			f = 1
		end
	end 
	if f == 0 
		h = [d,@pea]
		@pe << h
	end
	f = 0
	@plan_income.each do |a| 
		if a.issuance_date == d
			@pia += a.amount
			if a.issuance_date.to_date == @pi.last[0].to_date
				@pi.last[1] += a.amount
				@pi.last[2] += "-:-"+a.amount.to_s+' - '+a.name.to_s
			else
				h = [a.issuance_date,@pia,a.amount.to_s+' - '+a.name.to_s]
				@pi << h
			end
			f = 1
		end
	end 
	if f == 0 
		h = [d,@pia]
		@pi << h
	end
	f = 0
	@real_expense.each do |a| 
		if a.issuance_date == d
			@rea += a.amount
			if a.issuance_date.to_date == @re.last[0].to_date
				@re.last[1] += a.amount
				@re.last[2] += "-:-"+a.amount.to_s+' - '+a.name.to_s
			else
				h = [a.issuance_date,@rea,a.amount.to_s+' - '+a.name.to_s]
				@re << h
			end
			f = 1
		end
	end 
	if f == 0 
		h = [d,@rea]
		@re << h
	end
	f = 0
	@real_income.each do |a| 
		if a.issuance_date == d
			@ria += a.amount
			if a.issuance_date.to_date == @ri.last[0].to_date
				@ri.last[1] += a.amount
				@ri.last[2] += "-:-"+a.amount.to_s+' - '+a.name.to_s
			else
				h = [a.issuance_date,@ria,a.amount.to_s+' - '+a.name.to_s]
				@ri << h
			end
			f = 1
		end
	end 
	if f == 0 
		h = [d,@ria]
		@ri << h
	end
    end
    ### Data for expense by categories pie chart
    categories = Category.all
    @expense_by_categories = Array.new
@sums_array = Array.new
    sum = Transaction.where("category_id IS NULL").where(:typ => 1,:project_id => @project,:plan => 1).where("version_id IS NULL").sum(:amount)
    unless sum == 0
        @expense_by_categories << [0,"No category",sum]
@sums_array << [0,"No category","No category","No category","No category","No category",sum]
    end
    categories.each do |c|
	sum = Transaction.where(:category_id => c.id,:typ => 1,:project_id => @project,:plan => 1,:version_id => @version).sum(:amount)
        @expense_by_categories << [c.id,c.name,sum]
 @sums_array << [c.id,c.name,c.name,c.name,c.name,c.name,sum]
    end
    ### 
  end

  def time_detail
	@project = Project.find(params[:id])
	@user = User.find(params[:mem])
	@t = Array.new
	if params[:version] == "sub"
	children = @project.self_and_descendants
	t = TimeEntry.where(:user_id => params[:mem],:project_id => children).includes(:user,:issue,:activity).order(params[:order])
	elsif params[:version] == "all"
	t = TimeEntry.where(:user_id => params[:mem],:project_id => @project).includes(:user,:issue,:activity).order(params[:order])
	elsif params[:version] == "nov"
	t = TimeEntry.where(:user_id => params[:mem],:project_id => @project).includes(:user,:issue,:activity).where("issues.fixed_version_id IS NULL")
	else
	t = TimeEntry.where(:user_id => params[:mem],:project_id => @project).includes(:user,:issue,:activity).where("issues.fixed_version_id = ?",params[:version])
	@version = Version.find(params[:version])
	end
	t.each do |e|
		s = Salary.where(:user_id => e.user_id).where("valid_from <= ? AND valid_to >= ?",e.spent_on,e.spent_on).first()
		if s.nil?
			s = Salary.where(:user_id => e.user_id).where("valid_from <= ? AND valid_to IS NULL",e.spent_on).first()
		end
		if s.present?
			suma1 = (s.hours_rate.to_i)*e.hours
			@t << [e.spent_on, e.issue.present? ? e.issue.subject : "-", e.activity, e.hours, s.hours_rate, suma1, e.user.lastname, e.user.firstname]
		else
			@t << [e.spent_on, e.issue.present? ? e.issue.subject : "-", e.activity, e.hours, "e", suma1, e.user.lastname, e.user.firstname]
		end
	end
  end

  def salaries
	@project = Project.find(params[:id])
	t = TimeEntry.where(:project_id => @project,:post => false)
	@months = Array.new
	@array = Array.new
	if t.any?
		t.each do |r|
			unless @months.include?(r.spent_on.beginning_of_month)
				@months << r.spent_on.beginning_of_month
			end
		end
		@months.each do |m|
			sum_h = 0
			sum_m = 0
			e = ""
			t = TimeEntry.where(:project_id => @project,:post => false,:tyear => m.year,:tmonth => m.month).order(:spent_on)
			t.each do |r|
				sum_h += r.hours
				s = Salary.where(:user_id => r.user_id).where("valid_from <= ? AND valid_to >= ?",r.spent_on,r.spent_on).first()
				if s.nil?
					s = Salary.where(:user_id => r.user_id).where("valid_from <= ? AND valid_to IS NULL",r.spent_on).first()
				end
				if s.present?
					sum_m += ((s.hours_rate.to_i)*r.hours).to_i
				else
					e = "Missing salary"
				end
			end
			@array << [m,sum_h,sum_m,e]
		end
	end
  end

  def salaries_new
	@trans = Transaction.new
	@project = Project.find(params[:id])
	@versions = Version.where(:project_id => @project)
	@categories = Category.all()
	date = params[:date]    
  end

  def salaries_create
	date = params[:date].to_date
	u = Array.new
	t = TimeEntry.where(:project_id => @project,:post => false,:tyear => date.year,:tmonth => date.month)
	t.each do |w|
		unless u.include?(w.user_id)
			u << w.user_id
		end
	end
	u.each do |w|
		sum_m = 0
		t = TimeEntry.where(:project_id => @project,:post => false,:tyear => date.year,:tmonth => date.month,:user_id => w)
		t.each do |r|
			s = Salary.where(:user_id => r.user_id).where("valid_from <= ? AND valid_to >= ?",r.spent_on,r.spent_on).first()
			if s.nil?
				s = Salary.where(:user_id => r.user_id).where("valid_from <= ? AND valid_to IS NULL",r.spent_on).first()
			end
			if s.present?
				sum_m += ((s.hours_rate.to_i)*r.hours).to_i
			end
		end
		@trans = Transaction.new(params[:transaction])
		@trans[:name] = "Salary "+date.month.to_s+"/"+date.year.to_s
		@trans[:amount] = sum_m
		@trans[:plan] = 1
		@trans[:typ] = 	1
		@trans[:from_type] = 2
		@trans[:from_id] = w
		@trans[:project_id] = @project.id
		@trans.save
		t.each do |r|
			r.update_attribute(:post, true)
		end
	end
	redirect_to budget_salaries_path(), notice: 'transaction was successfully created.' 
	
  end

  def get_query
   unless params[:date_type].nil?
    if (params[:date2].empty? && params[:date].present?)
      if @query.nil?
	@query = "issuance_date " + params[:date_type] + " '" + params[:date] + "'"
      else
	@query += " AND issuance_date " + params[:date_type] + " '" + params[:date] + "'"
      end
    end
    if (params[:date].present? && params[:date2].present?)
      if @query.nil?
	@query = "issuance_date > '" + params[:date] + "' AND issuance_date < '" + params[:date2] + "'"
      else
	@query += " AND issuance_date > '" + params[:date] + "' AND issuance_date < '" + params[:date2] + "'"
      end
    end  
    unless params[:typ].empty?
      if @query.nil?
	@query = "typ = " + params[:typ] + " "
      else
	@query += " AND typ = " + params[:typ] + " "
      end
    end 
    unless params[:cat].empty?
      if @query.nil?
	@query = "category_id = " + params[:cat] + " "
      else
	@query += " AND category_id = " + params[:cat] + " "
      end
    end
    if (params[:amount2].empty? && params[:amount].present?)
      if @query.nil?
	@query = "amount " + params[:amount_type] + " '" + params[:amount] + "'"
      else
	@query += " AND amount " + params[:amount_type] + " '" + params[:amount] + "'"
      end
    end
    if (params[:amount].present? && params[:amount2].present?)
      if @query.nil?
	@query = "amount > '" + params[:amount] + "' AND amount < '" + params[:amount2] + "'"
      else
	@query += " AND amount > '" + params[:amount] + "' AND amount < '" + params[:amount2] + "'"
      end
    end 
   end
  end

  def get_kpi_defaults
	Setting.plugin_budget[:budget_kpi1_0].blank? ? @kpi1_0 = 1.2 : @kpi1_0 = Setting.plugin_budget[:budget_kpi1_0].to_d.round(2)
	Setting.plugin_budget[:budget_kpi1_1].blank? ? @kpi1_1 = 1 : @kpi1_1 = Setting.plugin_budget[:budget_kpi1_1].to_d.round(2)
	Setting.plugin_budget[:budget_kpi2_0].blank? ? @kpi2_0 = 0 : @kpi2_0 = Setting.plugin_budget[:budget_kpi2_0].to_d.round(2)
	Setting.plugin_budget[:budget_kpi2_1].blank? ? @kpi2_1 = 10 : @kpi2_1 = Setting.plugin_budget[:budget_kpi2_1].to_d.round(2)
	Setting.plugin_budget[:budget_kpi3_0].blank? ? @kpi3_0 = 1 : @kpi3_0 = Setting.plugin_budget[:budget_kpi3_0].to_d.round(2)
	Setting.plugin_budget[:budget_kpi3_1].blank? ? @kpi3_1 = 1.2 : @kpi3_1 = Setting.plugin_budget[:budget_kpi3_1].to_d.round(2)
  end

  def get_this_project_sums
	@projects << @project.id
	#define array for sums
	@sums_array = Array.new
	plan_income = Transaction.where(:project_id => @hierarchy,:typ => 0,:plan => 0).where(@query).sum(:amount)
	plan_expense = Transaction.where(:project_id => @hierarchy,:typ => 1,:plan => 0).where(@query).sum(:amount)
	real_income = Transaction.where(:project_id => @hierarchy,:typ => 0,:plan => 1).where(@query).sum(:amount)
	real_expense = Transaction.where(:project_id => @hierarchy,:typ => 1,:plan => 1).where(@query).sum(:amount)
	@real_sum = (real_income - real_expense)
	@plan_sum = (plan_income - plan_expense)
	@sums_array << ["pr",@project.id,@project.name,plan_income,plan_expense,real_income,real_expense]
  end

  def get_this_project_versions_sums
	#sums with no version
	plan_income = Transaction.where(:project_id => @project,:typ => 0,:plan => 0).where(@query).where("version_id IS NULL").sum(:amount)
	plan_expense = Transaction.where(:project_id => @project,:typ => 1,:plan => 0).where(@query).where("version_id IS NULL").sum(:amount)
	real_income = Transaction.where(:project_id => @project,:typ => 0,:plan => 1).where(@query).where("version_id IS NULL").sum(:amount)
	real_expense = Transaction.where(:project_id => @project,:typ => 1,:plan => 1).where(@query).where("version_id IS NULL").sum(:amount)
	#show only if any
	unless plan_income == 0 && plan_expense == 0 && real_income == 0 && real_expense == 0
		@sums_array << ["v",0,"No version",plan_income,plan_expense,real_income,real_expense]
        end
	#go throught projects versions if any
	unless @versions.nil?
        	@versions.each do |v|
			#get version sums
			plan_income = Transaction.where(:version_id => v,:typ => 0,:plan => 0).where(@query).sum(:amount)
			plan_expense = Transaction.where(:version_id => v,:typ => 1,:plan => 0).where(@query).sum(:amount)
			real_income = Transaction.where(:version_id => v,:typ => 0,:plan => 1).where(@query).sum(:amount)
			real_expense = Transaction.where(:version_id => v,:typ => 1,:plan => 1).where(@query).sum(:amount)
			first_issue = Issue.where(:fixed_version_id => v).order(:start_date).first
			@sums_array << ["v", v.id, v.name, plan_income, plan_expense, real_income, real_expense, first_issue.present? ? first_issue.start_date : nil, v.effective_date, v.completed_percent]
		end
	end
  end


end
