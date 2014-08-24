require_dependency 'time_entry_patch'
require_dependency 'user_patch'
require_dependency 'issue_patch'

Redmine::Plugin.register :budget do
  name 'Budget plugin'
  author 'Michal Mayer'
  description 'Finance plugin'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  project_module :budget do
	permission :view_contacts, :contact => [:index,:show]
	permission :edit_contacts, :contact => [:new,:edit,:create,:update,:destroy]	
	permission :view_budget, :budget => [:index,:show,:show_all,:show_no_version,:time,:time_detail,:salaries,:salaries_new,:salaries_create]
	permission :view_all_salaries, { :salary=> [:index] }
	permission :edit_salaries, { :salary=> [:new,:create,:delete] }
	permission :view_contact_project, { :contact => [:contact_project] }
	permission :edit_contact_project, { :contact => [:contact_project_create,:contact_project_delete] }
	permission :view_transaction, { :transaction => [:index,:show] }
	permission :edit_transaction, { :transaction => [:new,:edit,:create,:update,:destroy,:join,:join_create] }
	permission :category, { :transaction => [:index,:new,:edit,:create,:update,:destroy] }
  end

  menu :top_menu, :salary, { :controller => 'salary', :action => 'index' }, :caption => :salary,:if => Proc.new { (User.current.logged?) }
  menu :top_menu, :contact, { :controller => 'contact', :action => 'index' }, :caption => :contact,:if => Proc.new { (User.current.allowed_to?({:controller => :contact, :action => :index},nil,{:global => true })) }
  menu :project_menu, :budget, { :controller => 'budget', :action => 'index' }, :caption => :budget, :after => :activity, :if => Proc.new { (User.current.logged?) }
  menu :project_menu, :contact_project, { :controller => 'contact', :action => 'contact_project' }, :caption => :contact, :after => :activity, :if => Proc.new { (User.current.logged?) }


  settings :default => {'empty' => true}, :partial => 'settings/budget_settings'

end
