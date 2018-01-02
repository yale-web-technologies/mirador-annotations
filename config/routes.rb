# TenThousandRooms::Application.routes.draw do
MiradorAnnotationsServer::Application.routes.draw do
# Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks"}

  #get "welcome/index"
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".


  root to: 'annotation_layers#index', defaults: {format: :json}

  resources :annotation_layers, path: 'layers',defaults: {format: :json}
  resources :annotation_lists, path: 'lists',defaults: {format: :json}
  get '/lists/*url' => 'annotation_lists#show', :format => false
  resources :annotation_lists, path: 'lists', :format => false
  resources :annotations, path: 'annotations',defaults: {format: :json}, :except => [:update]
  put '/annotations', to: 'annotations#update'

  get '/getAnnotations', to: 'annotations#get_annotations_for_canvas'
  get '/getAnnotationsViaList', to: 'annotations#getAnnotationsForCanvasViaLists'
  put '/resequenceList', to: 'annotation_lists#resequence_list'
  get '/getSvg', to: 'annotations#getSvg', defaults: {format: :json}
  put '/updateSvg', to: 'annotations#updateSvg', defaults: {format: :json}
  get '/getCanvasForAnno', to: 'annotations#getTargetingAnnosCanvasFromID', defaults: {format: :json}
  get '/getLayersForAnnotation', to: 'annotations#getLayersForAnnotation', defaults: {format: :json}

  post '/setCurrentLayers', to: 'annotation_layers#setCurrentLayers',  defaults: {format: :json}
  post '/createLayerWithGroup', to: 'annotation_layers#createWithGroup', defaults: {format: :json}
  delete 'removeLayerFromGroup', to: 'annotation_layers#remove_layer_from_group', defaults: {format: :json}

  get 'setRedisKeys', to: "annotations#setRedisKeys"

  get 'export', to: 'export#export'
  get 'export/check_status', to: 'export#check_status', defaults: {format: :json}
  #get 'export/download', to: 'export#download', defaults: {format: :xlsx}

  match '/' => 'application#CORS_preflight', via: [:options], defaults: {format: :json}
  match 'getAnnotations' => 'application#CORS_preflight', via: [:options], defaults: {format: :json}
  match 'getAnnotations' => 'application#CORS_preflight', via: [:options], defaults: {format: :json}
  match 'annotations' => 'application#CORS_preflight', via: [:options], defaults: {format: :json}
  match 'annotations/*all' => 'application#CORS_preflight', via: [:options], defaults: {format: :json}
  match 'lists' => 'application#CORS_preflight', via: [:options], defaults: {format: :json}
  match 'layers' => 'application#CORS_preflight', via: [:options], defaults: {format: :json}
  match 'getAnnotationsViaList' => 'application#CORS_preflight', via: [:options], defaults: {format: :json}
  match 'resequenceList' => 'application#CORS_preflight', via: [:options], defaults: {format: :json}
end
