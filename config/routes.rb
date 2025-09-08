Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  #devise認証用ルーティング
  devise_for :users,
    defaults: { format: :json },
    controllers: { sessions: 'users/sessions' }

  # Defines the root path route ("/")
  # root "posts#index"

  #20250814 rails+DBのヘルスチェックルーティング
  get "/health", to: "health#index"

  #20250814 ユーザテーブルのリソースルーティング
  namespace :api do
    resources :users, only: [:index, :show]
    resources :user_agents, only: [:show, :create, :update]
    resources :user_agent_versions, only: [:create]
    resources :generation_settings, only: [:create, :update]
    resources :style_guides, only: [:create, :update]
    resources :few_shots, only: [:index, :create, :destroy]
    get :me, to: "users#me"   # 追加：ログイン中ユーザーの確認
   #20250815 チャットテーブル・OpenAIルーティング
    post "chat",        to: "chats#create"   # 非ストリーム（JSON）
    post "chat/stream", to: "chats#stream"   # ストリーム（SSE）
    post "ping/stream", to: "pings#stream"  # ← Api::PingsController を探しに行く
  end

  #20250826 オンボード用リソースルーティング
  namespace :api do
  resource :onboarding, only: [],controller: "onboarding" do
    get  :status      # 進捗照会（ステージ・回数）
  end
end

end
