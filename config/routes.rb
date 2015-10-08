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

  #get 'show', to: 'annotation#show'
  put '/annotations', to: 'annotation#update'
  put '/lists', to: 'annotation_list#update'
  put '/layers', to: 'annotation_layer#update'
  get '/getAll', to: 'services#getAllCanvasesLayersLists'
  get '/getCanvasData', to: 'services#getLayersListsForCanvas'

end
