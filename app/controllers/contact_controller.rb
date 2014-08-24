class ContactController < ApplicationController
  unloadable

 before_filter :global_authorize, :only => [:index, :show, :new, :create, :edit, :update,:destroy]
 before_filter :find_project,:authorize, :only => [:contact_project,:contact_project_create,:contact_project_delete]

 def global_authorize
   if User.current.allowed_to?({:controller => :contact, :action => self.action_name}, nil, {:global => true})
	true
	@right_to_edit_transaction = User.current.allowed_to?({:controller => :transaction, :action => :edit}, nil, {:global => true})
   else
 	render_403
   end
 end



  def index
    get_query()
    if params[:company].nil?
	@con = Contact.where(:contact_type => 0).includes(:contact).order(params[:order])
    else
	a = Contact.where(@query)
	b = Contact.new
	@c = []
	a.each do |d|
	  if d.contact_type == 0
		@c << d.id
	  else
  	  	b = Contact.find(d.parent_id) if d.parent_id.present?
	  	@c << b.id if d.parent_id.present?
  	  end
	end
	@con = Contact.includes(:contact).where("contacts.id IN (?)",@c).order(params[:order])
    end
  end

  def show
    get_query_trans
    @contact = Contact.find(params[:id])
    @real = Transaction.where(:from_type => 0,:plan => 1,:from_id => @contact).where(@query)
    @plan = Transaction.where(:from_type => 0,:plan => 0,:from_id => @contact).where(@query)
    rsi = Transaction.where(:from_type => 0,:plan => 1,:typ => 0,:from_id => @contact).where(@query).sum(:amount)
    rse = Transaction.where(:from_type => 0,:plan => 1,:typ => 1,:from_id => @contact).where(@query).sum(:amount)
    @real_sum = (rsi - rse)
    psi = Transaction.where(:from_type => 0,:plan => 0,:typ => 0,:from_id => @contact).where(@query).sum(:amount)
    pse = Transaction.where(:from_type => 0,:plan => 0,:typ => 1,:from_id => @contact).where(@query).sum(:amount)
    @plan_sum = (psi - pse)
    @pe = Contact.where(:parent_id => @contact).where(:contact_type => 1)
    @p = Contact.where(:parent_id => @contact).where(:contact_type => 0)
    @pa = Contact.where(:id => @contact.parent_id).where(:contact_type => 0).first()
    @categories = Category.all
    @versions = Version.all
  end

  def edit
    @contact = Contact.find(params[:id])
    @contacts = Contact.where(:contact_type => 0)
  end

  def update
    @contacts = Contact.where(:contact_type => 0)
    @contact = Contact.find(params[:id])
    if params[:contact][:def] == "1"
      @c = Contact.where(:parent_id => @contact.parent_id)
      @c.each do |w|
	w.update_attribute(:def, 0)
      end
    end

    respond_to do |format|
      if @contact.update_attributes(params[:contact])
        if @contact.contact_type == 0
        format.html { redirect_to contact_index_path(), notice: 'contact was successfully deleted.' }
        else
        format.html { redirect_to contact_path(@contact.parent_id), notice: 'contact was successfully updated.' }
        end
        format.json { render json: @contact, status: :created, location: @contact }
      else
        format.html { render action: 'new'}
        format.json { render json: @contact.errors, status: :unprocessable_entity }
      end
    end
  end

  def new  
    @contact = Contact.new()
    @contacts = Contact.where(:contact_type => 0)
  end

  def create
       @contacts = Contact.where(:contact_type => 0)
   unless params[:contact][:picture].nil?
    uploaded_io = params[:contact][:picture]
    File.open(Rails.root.join('plugins', 'budget', 'assets', 'images', uploaded_io.original_filename), 'wb') do |file|
     file.write(uploaded_io.read)
     params[:contact][:picture] = uploaded_io.original_filename
    end
   end
   if params[:contact][:contact_type] == "0"
     params[:contact][:parent_id] = params[:parent]
   end
    if params[:contact][:contact_type] == "1" && params[:contact][:def] == "1" && params[:contact][:parent_id].present?
      @con = Contact.where(:parent_id => params[:contact][:parent_id])
      @con.each do |w|
	w.update_attribute(:def, 0)
      end
    end
    @contact = Contact.new(params[:contact])
    respond_to do |format|
      if @contact.save
        format.html { redirect_to contact_index_path(), notice: 'contact was successfully created.' }
        format.json { render json: @contact, status: :created, location: @contact }
      else
        format.html { render action: 'new'}
        format.json { render json: @contact.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @contact = Contact.find(params[:id])
    trans = Transaction.where(:from_type => 0,:from_id => @contact.id)
    trans.each do |t|
 	t.destroy
    end
    if @contact.contact_type == 0
      @contact.destroy
      respond_to do |format|
        format.html { redirect_to contact_index_path(), notice: 'contact was successfully deleted.' }
        format.json { head :no_content }
      end
    else
      @parent = @contact.parent_id
      @contact.destroy
      respond_to do |format|
        format.html { redirect_to contact_path(@parent), notice: 'contact was successfully deleted.' }
        format.json { head :no_content }
      end
    end
  end

  def person
    @contact = Contact.new()
  end

  def person_create
    @contact = Contact.new(params[:contact])
    @t = Contact.find(params[:id])
    @contact.save
    redirect_to contact_path(@t), notice: 'contact person was successfully created.'
  end
  def person_delete
    @contact = Contact.find(params[:person])
    @t = Contact.find(params[:id])
    @contact.destroy
    redirect_to contact_path(@t), notice: 'contact person was successfully deleted.'
  end

#showing contacts in project menu
  def contact_project
    #rights
  p = Project.all
  t = false
  p.each do |p|
    allowed = User.current.allowed_to?({:controller => :contact, :action => :index}, p)
    if allowed
      @right_view_contact = true
    end
    allowed2 = User.current.allowed_to?({:controller => :contact, :action => :new}, p)
    if allowed
      @right_edit_contact = true
    end
  end
    @project = Project.find(params[:id])
    get_query()		
    if params[:contacts].nil?
	@con = Contact.includes(:contact).includes(:contact_project).where("contact_projects.project_id = ?",@project.id)
    elsif params[:contacts] == "0"
	a = Contact.where(@query)
	b = Contact.new
	@c = []
	a.each do |d|
	  if d.contact_type == 0
		@c << d.id
	  else
  	  	b = Contact.find(d.parent_id) if d.parent_id.present?
	  	@c << b.id if d.parent_id.present?
  	  end
	end
	@con = Contact.includes(:contact_project).includes(:contact).where("contact_projects.contact_id IN (?)",@c)
    elsif @right_view_contact
	a = Contact.where(@query)
	b = Contact.new
	@c = []
	a.each do |d|
	  if d.contact_type == 0
		@c << d.id
	  else
  	  	b = Contact.find(d.parent_id) if d.parent_id.present?
	  	@c << b.id if d.parent_id.present?
  	  end
	end
	@con = Contact.includes(:contact_project).includes(:contact).where("contacts.id IN (?)",@c)
    end
    if !@right_view_contact && params[:contacts] == "1"
      deny_access
    end
  end

  def contact_project_create
      @project = Project.find(params[:id])
      @cp = ContactProject.new(:project_id => @project.id,:contact_id => params[:idp])
      respond_to do |format|
        if @cp.save
          format.html { redirect_to contact_project_path(@project.id), notice: 'contact was successfully added.' }
          format.json { render json: @contact, status: :created, location: @contact }
        else
          format.html { redirect_to contact_project_path(), alert: 'contact was not successfully added.' }
          format.json { render json: @contact.errors, status: :unprocessable_entity }
        end
      end
  end

  def contact_project_delete
      @project = Project.find(params[:id])
      @cp = ContactProject.where(:project_id => @project.id).where(:contact_id => params[:idp]).first()
      @cp.destroy
      respond_to do |format|
          format.html { redirect_to contact_project_path(@project.id), notice: 'contact was successfully removed.' }
          format.json { render json: @contact, status: :created, location: @contact }
      end
  end

  def get_query
    unless params[:company].nil?
    unless params[:company].empty?
      if @query.nil?
	@query = "contacts.company_name like " + "'%" + params[:company] + "%'"
      else
        @query += " OR contacts.company_name like " + "'%" + params[:company] + "%'"
      end
    end
    unless params[:person].empty?
      if @query.nil?
	@query = "contacts.contact_person like " + "'%" + params[:person] + "%'"
      else
        @query += " OR contacts.contact_person like " + "'%" + params[:person] + "%'"
      end
    end
    unless params[:email].empty?
      if @query.nil?
	@query = "contacts.email like " + "'%" + params[:email] + "%' OR contacts.pemail like " + "'%" + params[:email] + "%'"
      else
	@query = " OR contacts.email like " + "'%" + params[:email] + "%' OR contacts.pemail like " + "'%" + params[:email] + "%'"
      end
    end
    unless params[:department].empty?
      if @query.nil?
	@query = "contacts.department like " + "'%" + params[:department] + "%'"
      else
        @query += " OR contacts.department like " + "'%" + params[:department] + "%'"
      end
    end
    end
  end


 def get_query_trans
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
