class InitialQuestion < ApplicationRecord
  validates :body, presence: true
  scope :active, -> { where(active: true) }
end
