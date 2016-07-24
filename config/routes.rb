
require 'sass'
require 'bootstrap-sass'

Rails.application.routes.draw do
  resources :step_types
  resources :steps
  resources :activities do
    resources :uploads
    resources :asset_groups
  end

  resources :assets, :path => 'labware'
  resources :steps
  resources :activity_types
  resources :kit_types
  resources :kits
  resources :instruments
  root 'instruments#index'

  resources :samples_started
  resources :samples_not_started
  resources :history
  resources :reracking

  get 'activities/:id/step_types_active' => 'activities#step_types_active'
  get 'activities/:id/steps_finished' => 'activities#steps_finished'
  get 'activities/:id/steps_finished_with_operations/:step_id' => 'activities#steps_finished_with_operations'

  if (ENV["RAILS_ENV"]==:debug)
    mount Peek::Railtie => '/peek'
  end

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
