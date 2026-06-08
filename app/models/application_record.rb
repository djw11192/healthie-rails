# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # UUID PKs have no natural sort order, so Rails' implicit ORDER BY id (used
  # by .last, .first, etc.) would be non-deterministic. created_at is the
  # correct default sort for all models in this app.
  self.implicit_order_column = "created_at"
end
