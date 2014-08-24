# Plugin's routes
# See: http:guides.rubyonrails.orgrouting.html

#transation routes
get 'projects/:id/transaction/', :to => 'transaction#index', :as => :transaction_index
get 'projects/:id/transaction/new', :to => 'transaction#new', :as => :new_transaction
get 'projects/:id/transaction/:idt', :to => 'transaction#show', :as => :transaction
get 'projects/:id/transaction/:idt/edit', :to => 'transaction#edit', :as => :edit_transaction
get 'projects/:id/transaction/:idt/join', :to => 'transaction#join', :as => :join_transaction
put 'projects/:id/transaction/:idt/join', :to => 'transaction#join_create', :as => :join_create_transaction
put 'projects/:id/transaction/:idt', :to => 'transaction#update', :as => :update_transaction
post 'projects/:id/transaction', :to =>  'transaction#create', :as => :create_transaction
delete 'projects/:id/transaction/:idt', :to =>  'transaction#destroy', :as => :delete_transaction
#salary  routes
resources :salary
get 'salary/:id/edit/:sal', :to => 'salary#edit', :as => :edit_salary
put 'salary/:id/edit/:sal', :to => 'salary#update', :as => :update_salary
delete 'salary/:id/:sal', :to => 'salary#delete', :as => :delete_salary
#contact  routes
resources :contact
match "projects/:id/contact/", :to => 'contact#contact_project', :as => :contact_project
post "projects/:id/contact/:idp", :to => 'contact#contact_project_create', :as => :new_contact_project
delete "projects/:id/contact/:idp", :to => 'contact#contact_project_delete', :as => :delete_contact_project
#budget routes
get 'projects/:id/budget/', :to => 'budget#index', :as => :budget_index
get 'projects/:id/budget/version/:idv', :to => 'budget#show', :as => :budget
get 'projects/:id/budget/all', :to => 'budget#show_all', :as => :budget_all
get 'projects/:id/budget/nov', :to => 'budget#show_no_version', :as => :budget_nov
get 'projects/:id/budget/transactions', :to => 'budget#transactions', :as => :budget_transactions
get 'projects/:id/budget/time/', :to => 'budget#time', :as => :budget_time
get 'projects/:id/budget/time/:mem', :to => 'budget#time_detail', :as => :budget_time_detail
get 'projects/:id/budget/salaries/', :to => 'budget#salaries', :as => :budget_salaries
get 'projects/:id/budget/salaries/new/:date', :to => 'budget#salaries_new', :as => :budget_new_salaries
post 'projects/:id/budget/salaries/create/:date', :to => 'budget#salaries_create', :as => :budget_create_salaries
#category routes
get 'category', :to => 'category#index', :as => :category_index
get 'category/new', :to => 'category#new', :as => :new_category
get 'category/:id', :to => 'category#edit', :as => :edit_category
post 'category', :to => 'category#create'
put 'category/:id/', :to => 'category#update', :as => :update_category
delete 'category/:id', :to => 'category#destroy', :as => :delete_category
