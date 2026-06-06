class JournalEntry < ApplicationRecord
  belongs_to :client

  validates :body, presence: true

  # Newest first. A named scope keeps ordering intent in one place and reads
  # well at call sites: `client.journal_entries.by_recent`.
  scope :by_recent, -> { order(created_at: :desc) }
end
