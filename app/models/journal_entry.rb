# frozen_string_literal: true

class JournalEntry < ApplicationRecord
  belongs_to :client

  validates :body, presence: true

  # Newest first, by the health-event date (not DB insertion time).
  scope :by_recent, -> { order(recorded_at: :desc) }
end
