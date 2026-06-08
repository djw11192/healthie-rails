Rails.application.routes.draw do
  # The four required queries, exposed as REST endpoints (hit these in Postman):
  #   GET  /providers/:id/clients          -> all clients for a provider          (query 1)
  #   GET  /clients/:id/providers          -> all providers for a client          (query 2)
  #   GET  /clients/:id/journal_entries    -> a client's entries, newest first    (query 3)
  #   GET  /providers/:id/journal_entries  -> entries across a provider's clients  (query 4)
  #   POST /clients/:id/journal_entries    -> a client posts a new journal entry
  #
  # index/show are included so you can discover IDs to plug into the routes above.
  resources :providers, only: %i[index show] do
    member do
      get :clients
      get :journal_entries
    end
  end

  resources :clients, only: %i[index show] do
    member do
      get :providers
    end
    # GET  -> a client's entries, newest first (query 3)
    # POST -> a client posts a new journal entry (freeform text)
    resources :journal_entries, only: %i[index create]
  end

  # Health check (used by load balancers / uptime monitors).
  get "up" => "rails/health#show", as: :rails_health_check
end
