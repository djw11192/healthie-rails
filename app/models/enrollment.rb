# frozen_string_literal: true

class Enrollment < ApplicationRecord
  belongs_to :provider
  belongs_to :client

  # The plan is a property of the provider<->client *relationship*, so it lives
  # on the join model rather than on Client. String-backed enum keeps the DB
  # values human-readable (vs. integer-backed, which is more compact but opaque).
  enum :plan, { basic: "basic", premium: "premium" }, default: :basic, validate: true

  # Mirrors the unique DB index; gives a friendly error instead of a raw
  # constraint violation when a duplicate (provider, client) pair is created.
  validates :provider_id,
            uniqueness: { scope: :client_id, message: "is already enrolled with this client" }
end
