class TransactionController < ApplicationController
  unloadable

  before_filter :find_project, :authorize

  def index
    get_query
    @project = Project.find(params[:id])
    @versions = Version.where(:project_id => @project)
    @trans = Transaction.includes(:version).includes(:contact).includes(:user).includes(:category).includes(:project_from).where(:project_id => @project).where(@query).order(params[:order])
    @categories = Category.all
  end

  def show
    @project = Project.find(params[:id])
    @tran = Transaction.includes(:version).includes(:user).includes(:category).includes(:project_from).includes(:contact).find(params[:idt])
    unless @tran[:parent_id].nil?
      @tran_parent = Transaction.includes(:version).includes(:user).includes(:category).includes(:project_from).includes(:contact).find(@tran[:parent_id])
    end
  end

  def new
    @trans = Transaction.new()
    @pro = Project.all
    @project = Project.find(params[:id])
    @versions = Version.where(:project_id => @project)
    @contact_project = Contact.includes(:contact_project).where("contact_projects.project_id = ?",@project.id) 
    @contact_all = Contact.where(:contact_type => 0)
    @users = User.all
    @categories = Category.all
  end

  def edit
    @trans = Transaction.find(params[:idt])
    @pro = Project.all
    @project = Project.find(@trans.project_id)
    @versions = Version.where(:project_id => @project)   
    @contact_project = Contact.includes(:contact_project).where("contact_projects.project_id = ?",@project.id) 
    @contact_all = Contact.where(:contact_type => 0)
    @users = User.all
    @categories = Category.all
  end

  def create
    @trans = Transaction.new(params[:transaction])
    @pro = Project.all
    @project = Project.find(params[:id])
    @trans.project_id = @project.id
    @versions = Version.where(:project_id => @project)
    @contact_project = Contact.includes(:contact_project).where("contact_projects.project_id = ?",@project.id) 
    @contact_all = Contact.where(:contact_type => 0)
    @users = User.all
    @categories = Category.all
    respond_to do |format|
      if @trans.save
	if @trans.from_type == 1
		#if transaction is going between projects
		@new_trans = Transaction.new(params[:transaction])
		@new_trans.project_id = @trans.from_id
		@new_trans.from_id = @trans.project_id
		@new_trans.typ = 1 if @trans.typ == 0
		@new_trans.typ = 0 if @trans.typ == 1
		@new_trans.between_project = @trans.id
		@new_trans.save
		@trans.update_attribute(:between_project,@new_trans.id)
	end
        if params[:period_check] == "1"
	  b = true
	  i = 0
	  while (b) do
	     i = i + 1
  	     @t = Transaction.new(params[:transaction])
	     @t.project_id = @project.id
	     if @trans.period == 0
	     	@t.issuance_date = @trans.issuance_date + i.week if @trans.issuance_date.present?
	     	@t.due_to = @trans.due_to + i.week if @trans.due_to.present?
	     else
	     	@t.issuance_date = @trans.issuance_date + i.month if @trans.issuance_date.present?
	     	@t.due_to = @trans.due_to + i.month if @trans.due_to.present?
	     end
	     if @t.issuance_date <= @trans.period_end
   		@t.save
	     else
		b = false
		break
	     end
    	  end
	end
        format.html { 
    		redirect_to budget_index_path(), notice: 'transaction was successfully created.' 
	}
        format.json { render json: @trans, status: :created, location: @trans }
      else
        format.html { render action: 'new'}
        format.json { render json: @trans.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @trans = Transaction.find(params[:idt])
    @p = @trans.version_id
    if @trans.between_project.present?
	@tran = Transaction.find(@trans.between_project)
	@tran.destroy
    end
    @trans.destroy

    respond_to do |format|
      format.html {     
	if @p.nil?
    		redirect_to budget_nov_path(), notice: 'transaction was successfully updated.' 
    	else
    		redirect_to budget_path(:idv => @p), notice: 'transaction was successfully deleted.' 
    	end }
      format.json { head :no_content }
    end
  end

  def join
    @trans = Transaction.find(params[:idt])
    @pro = Project.all
    @project = Project.find(@trans.project_id)
    @versions = Version.where(:project_id => @project)   
    @contact_project = Contact.includes(:contact_project).where("contact_projects.project_id = ?",@project.id) 
    @contact_all = Contact.where(:contact_type => 0)
    @users = User.all
    @categories = Category.all
  end

  def join_create
    @trans = Transaction.find(params[:idt])
    @pro = Project.all
    @project = Project.find(@trans.project_id)
    @versions = Version.where(:project_id => @project)   
    @contact_project = Contact.includes(:contact_project).where("contact_projects.project_id = ?",@project.id) 
    @contact_all = Contact.where(:contact_type => 0)
    @users = User.all
    @categories = Category.all
    @new_trans = Transaction.new(params[:transaction])
    @new_trans[:parent_id] = params[:idt]
    @new_trans[:plan] = 1
    @new_trans[:project_id] = @trans[:project_id]
    @new_trans.save
    @trans[:parent_id] = @new_trans.id
    @trans.update_attributes(params[:transaction])
    if @trans.version_id.nil?
    	redirect_to budget_path_nov(), notice: 'transaction was successfully updated.' 
    else
    	redirect_to budget_path(:idv => @trans.version_id), notice: 'transaction was successfully updated.' 
    end
  end

  def update
    @trans = Transaction.find(params[:idt])
    @pro = Project.all
    @project = Project.find(@trans.project_id)
    @versions = Version.where(:project_id => @project)   
    @contact_project = Contact.includes(:contact_project).where("contact_projects.project_id = ?",@project.id) 
    @contact_all = Contact.where(:contact_type => 0)
    @users = User.all
    @categories = Category.all
    if @trans.between_project.present?
	@tran = Transaction.find(@trans.between_project)
	if params[:transaction][:from_type] != "1" && params[:transaction][:from_type].present?
		@tran.destroy
	end
	if params[:transaction][:from_id] != @tran.id && params[:transaction][:from_id].present?
		@tran.update_attribute(:from_id, params[:transaction][:from_id])
	end
	if params[:transaction][:typ] != @trans.typ && params[:transaction][:typ].present?
		@tran.update_attribute(:typ, 1) if params[:transaction][:typ] == 0
		@tran.update_attribute(:typ, 0) if params[:transaction][:typ] == 1
	end
    end
    respond_to do |format|
      if @trans.update_attributes(params[:transaction])
        format.html { 
    	if @trans.version_id.nil?
    		redirect_to budget_path_nov(), notice: 'transaction was successfully updated.' 
    	else
    		redirect_to budget_path(:idv => @trans.version_id), notice: 'transaction was successfully updated.' 
    	end }
        format.json { render json: @trans, status: :created, location: @trans }
      else
        format.html { render action: 'new'}
        format.json { render json: @trans.errors, status: :unprocessable_entity }
      end
    end
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
    unless params[:ver].empty?
      if @query.nil?
	@query = "version_id = " + params[:ver] + " "
      else
	@query += " AND version_id = " + params[:ver] + " "
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

end
