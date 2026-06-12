Rails.application.routes.draw do
  root "records#index"
  get "records/discogs_lookup", to: "records#discogs_lookup", as: :records_discogs_lookup
  resources :records, only: [ :new, :show, :create ]

  devise_for :users,
    path: "",
    path_names: { sign_in: "login", sign_out: "logout" },
    controllers: { sessions: "sessions" },
    skip: [ :registrations, :passwords, :confirmations, :unlocks ]

  get "up" => "rails/health#show", as: :rails_health_check
end
