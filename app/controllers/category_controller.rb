class CategoryController < ApplicationController
  unloadable

 before_filter :global_authorize

 layout 'admin'
 def global_authorize
   if User.current.allowed_to?({:controller => :category, :action => :action_name}, nil, {:global => true})
	true
   else
 	render_403
   end
 end

 def index
	@cat = Category.all
 end

 def new
	@cat = Category.new
 end

 def create
	@cat = Category.new(params[:category])
	if @cat[:payments] == 1
		c = Category.where(:payments => 1)
		c.each do |w|
			w.update_attribute(:payments, 0)
		end
	end
	respond_to do |format|
      if @cat.save
	if @cat[:payments] == 1
		trans = Transaction.where(:from_type => 3)
		trans.each do |w|
			w.update_attribute(:category_id, @cat.id)
		end
	end
        format.html { redirect_to plugin_settings_path("budget"), notice: 'category was successfully created.' }
        format.json { render json: @cat, status: :created, location: @cat }
      else
        format.html { render action: 'new'}
        format.json { render json: @cat.errors, status: :unprocessable_entity }
      end
	end
 end

 def edit
	@cat = Category.find(params[:id])
 end

 def update
	@cat = Category.find(params[:id])	
	if params[:category][:payments] == "1"
		c = Category.where(:payments => 1).where("id != ?",@cat.id)
		c.each do |w|
			w.update_attribute(:payments, 0)
		end
	end
    respond_to do |format|
      if @cat.update_attributes(params[:category])
	if @cat[:payments] == 1
		trans = Transaction.where(:from_type => 3)
		trans.each do |w|
			w.update_attribute(:category_id, @cat.id)
		end
	end
        format.html { redirect_to plugin_settings_path("budget"), notice: 'category was successfully updated.' }
        format.json { render json: @cat, status: :created, location: @cat }
      else
        format.html { render action: 'new'}
        format.json { render json: @cat.errors, status: :unprocessable_entity }
      end
    end
 end

 def destroy
 	@cat = Category.find(params[:id])
	@cat.destroy
	respond_to do |format|
        format.html { redirect_to plugin_settings_path("budget"), notice: 'category was successfully deleted.' }
        format.json { head :no_content }
        end
 end
end
