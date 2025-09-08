class OnboardingExchange < ApplicationRecord
  belongs_to :onboarding_session, inverse_of: :onboarding_exchanges
  #belongs_to :initial_question, optional: true
  validates :initial_question_id, presence: true
end
