TenThousandRooms::Application.routes.draw do

  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks"}

  #get "welcome/index"
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  root 'annotation_layer#index'

  resources :annotation_layer, path: 'layers',defaults: {format: :json}
  resources :annotation_layer, path: 'layer', defaults: {format: :json}

  resources :annotation_list, path: 'lists',defaults: {format: :json}
  resources :annotation_list, path: 'list',defaults: {format: :json}

  resources :annotation, path: 'annotations',defaults: {format: :json}
  resources :annotation, path: 'annotation',defaults: {format: :json}

  put '/annotation', to: 'annotation#update'
  delete '/annotation', to: 'annotation#destroy'
  put '/lists', to: 'annotation_list#update'
  put '/layers', to: 'annotation_layer#update'
  #get '/getAll', to: 'services#getAllCanvasesLayersLists'
  get '/getCanvasData', to: 'services#getLayersListsForCanvas'
  #get '/getAnnotations', to: 'annotation_list#index'
  get '/getAnnotations', to: 'annotation#getAnnotationsForCanvas'

  get 'getAccessToken', to: "application#get_access_token", defaults: {format: :json}
  get 'loginToServer', to: "annotation#login"
  #get 'users/CASSender', to: "annotation#/devise/sessions/sign_in.html.erb"

  match 'lists' => 'annotation_list#CORS_preflight', via: [:options], defaults: {format: :json}
  match 'getAnnotations' => 'annotation#CORS_preflight', via: [:options], defaults: {format: :json}
  match 'annotation' => 'annotation#CORS_preflight', via: [:options], defaults: {format: :json}
  match 'annotations' => 'annotation#CORS_preflight', via: [:options], defaults: {format: :json}
  match 'annotations/*all' => 'annotation#CORS_preflight', via: [:options], defaults: {format: :json}
  match 'getAccessToken' => 'annotation#CORS_preflight', via: [:options], defaults: {format: :json}

end
