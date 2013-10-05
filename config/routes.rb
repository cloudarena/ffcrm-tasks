Rails.application.routes.draw do
  resources :tasks, :id => /\d+/, :only=>[]  do
    member do
      post :subscribe
      post :unsubscribe
      post :versions
    end
  end
end
