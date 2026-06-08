# frozen_string_literal: true

class Client < ApplicationRecord
  has_many :enrollments, dependent: :destroy
  has_many :providers, through: :enrollments
  # PHI must not be casually deleted. Restrict prevents cascade-delete; a proper
  # retention / archival workflow is required to remove journal records.
  has_many :journal_entries, dependent: :restrict_with_error

  validates :name, presence: true
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
end
