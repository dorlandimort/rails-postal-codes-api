Rails.application.routes.draw do
  get 'postal_code/:postal_code', to: 'postal_codes#show'
  get 'postal_codes/:postal_code', to: 'postal_codes#index'

  match '/404', to: 'errors#not_found', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all
end
