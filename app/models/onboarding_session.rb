class OnboardingSession < ApplicationRecord
  belongs_to :user, inverse_of: :onboarding_sessions
  has_many :onboarding_exchanges, dependent: :destroy

 # 初期化や最初の質問提示時に設定
  def start_with!(question_id)
    update!(current_initial_question_id: question_id)
  end
end
