Rails.application.routes.draw do
  resources :tasks, :id => /\d+/, :only=>[]  do
    member do
      match :subscribe
      match :unsubscribe
    end
  end
end
