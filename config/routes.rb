Rails.application.routes.draw do
  root "records#index"
  resources :records, only: [ :show, :create ]

  devise_for :users,
    path: "",
    path_names: { sign_in: "login", sign_out: "logout" },
    controllers: { sessions: "sessions" },
    skip: [ :registrations, :passwords, :confirmations, :unlocks ]

  get "up" => "rails/health#show", as: :rails_health_check
end
