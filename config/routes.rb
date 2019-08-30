
require 'sass'
require 'bootstrap-sass'

Rails.application.routes.draw do

  resources :printers
  resources :user_sessions do
    collection do
      post 'create'
      post 'destroy'
    end
  end
  resources :users

  resources :step_types
  resources :steps
  resources :changes

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
      post 'print'
      post 'print_search'
    end
  end

  resources :activity_types
  resources :kit_types
  resources :kits
  resources :instruments do
    member do
      get 'use', to: 'instruments#use'
    end
  end

  root 'instruments#index'
  #root 'activity_types#index'

  resources :samples_started
  resources :samples_not_started
  resources :history
  resources :reracking
  resources :uploaded_files, only: [:create, :show]


  # Trying to make fonts work out in poltergeist
  get '/fonts/bootstrap/:name', to: redirect('/assets/bootstrap/%{name}')


  namespace :api do
    namespace :v1 do
      jsonapi_resources :assets
    end
  end

  #namespace :aker do
  #  resources :work_orders, only: [:create, :index]
  #end

end
