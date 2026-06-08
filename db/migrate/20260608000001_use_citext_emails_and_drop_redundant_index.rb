# frozen_string_literal: true

class UseCitextEmailsAndDropRedundantIndex < ActiveRecord::Migration[8.1]
  def up
    # citext is a Postgres built-in extension that makes the column's comparisons and
    # indexes case-insensitive without altering the stored value. This closes the gap
    # where the model validates uniqueness case-insensitively but the DB index is a
    # standard case-sensitive B-tree — two concurrent inserts of user@x.com and
    # USER@x.com could both slip past Rails validation and violate intended uniqueness.
    enable_extension "citext"

    change_column :clients,   :email, :citext
    change_column :providers, :email, :citext

    # The composite index [client_id, created_at] already covers any query that
    # would use the single-column client_id index (Postgres uses a leading-prefix
    # scan), so the single-column index is redundant write overhead.
    remove_index :journal_entries, name: :index_journal_entries_on_client_id
  end

  def down
    add_index :journal_entries, :client_id

    change_column :clients,   :email, :string
    change_column :providers, :email, :string

    # Intentionally not disabling citext here — other tables or extensions may
    # depend on it by the time this is rolled back.
  end
end
