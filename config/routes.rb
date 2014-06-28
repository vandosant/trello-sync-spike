Rails.application.routes.draw do

  root "oauth#index"
  get '/oauth2authorize' => "oauth#authorize"
  get '/oauth2callback' => "oauth#callback", as: :oauth_callback
  get '/create' => "oauth#create"
  get '/trello' => "oauth#trello"

end
