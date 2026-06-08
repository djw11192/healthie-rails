# frozen_string_literal: true

class Provider < ApplicationRecord
  has_many :enrollments, dependent: :destroy
  has_many :clients, through: :enrollments
  # Convenience for "all journal entries across all of a provider's clients".
  # Rails composes the join through enrollments -> clients -> journal_entries.
  has_many :journal_entries, through: :clients

  validates :name, presence: true
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
end
