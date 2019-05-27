
require 'sass'
require 'bootstrap-sass'

Rails.application.routes.draw do

  resources :printers
  resources :user_sessions
  resources :users

  resources :step_types
  resources :steps
  
  resources :asset_groups do
    member do
      get 'print'
      post 'upload', to: 'asset_groups#upload'
    end

  end

  resources :activities do
    resources :asset_groups
    resources :step_types
    resources :steps
  end

  resources :reracking do
    resources :asset_groups
  end

  resources :assets, :path => 'labware' do
    collection do
      get 'search'
    end
  end

  resources :activity_types
  resources :kit_types
  resources :kits
  resources :instruments
  
  root 'instruments#index'

  resources :samples_started
  resources :samples_not_started
  resources :history
  resources :reracking
  resources :uploaded_files, only: [:create, :show]


  # Trying to make fonts work out in poltergeist
  get '/fonts/bootstrap/:name', to: redirect('/assets/bootstrap/%{name}')

  namespace :aker do
    resources :work_orders, only: [:create, :index]
  end

end
