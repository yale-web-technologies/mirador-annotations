TenThousandRooms::Application.routes.draw do

  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks"}

  #get "welcome/index"
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  root 'annotation_layer#index'
  resources :annotation_layers, path: 'layers',defaults: {format: :json}
  resources :annotation_lists, path: 'lists',defaults: {format: :json}
  resources :annotations, path: 'annotations',defaults: {format: :json}
  #put '/annotations', to: 'annotations#update'

  #get '/getAll', to: 'services#getAllCanvasesLayersLists'
  get '/getCanvasData', to: 'services#getLayersListsForCanvas'
  get '/getAnnotations', to: 'annotations#getAnnotationsForCanvas'

  get 'getAccessToken', to: "application#get_access_token", defaults: {format: :json}
  get 'loginToServer', to: "application#login"
  #get 'users/CASSender', to: "annotation#/devise/sessions/sign_in.html.erb"

  match '/' => 'annotation_lists#CORS_preflight', via: [:options], defaults: {format: :json}
  match 'lists' => 'annotation_lists#CORS_preflight', via: [:options], defaults: {format: :json}
  match 'getAnnotations' => 'annotations#CORS_preflight', via: [:options], defaults: {format: :json}
  match 'annotations' => 'annotations#CORS_preflight', via: [:options], defaults: {format: :json}
  match 'annotations' => 'annotations#CORS_preflight', via: [:options], defaults: {format: :json}
  match 'annotations/*all' => 'annotations#CORS_preflight', via: [:options], defaults: {format: :json}
  match 'getAccessToken' => 'annotations#CORS_preflight', via: [:options], defaults: {format: :json}

end
