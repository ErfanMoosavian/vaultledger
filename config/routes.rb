Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  root "dashboard#index"

  get "/locale/:locale", to: "locales#update", as: :switch_locale, constraints: { locale: /en|fa/ }

  resources :accounts, only: [ :create, :show ] do
    member do
      get :export
    end
  end

  post "/deposits", to: "dashboard#deposit", as: :deposits
  post "/transfers", to: "dashboard#transfer", as: :transfers
  post "/transactions/:id/reverse", to: "dashboard#reverse", as: :reverse_transaction

  namespace :api do
    namespace :v1 do
      resources :accounts, only: [ :index, :show, :create ]
      resources :transactions, only: [ :index, :show, :create ] do
        member do
          post :reverse
        end
      end
      resources :transfers, only: [ :create ]
      get "audit", to: "audit#show"
    end
  end
end
