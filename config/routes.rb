Rails.application.routes.draw do
  resources :clearance_batches, only: [:index, :create, :show, :update]
  root to: "clearance_batches#index"
end
