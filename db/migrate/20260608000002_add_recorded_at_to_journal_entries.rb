# frozen_string_literal: true

class AddRecordedAtToJournalEntries < ActiveRecord::Migration[8.1]
  def up
    # recorded_at = when the health event occurred.
    # created_at  = when the DB row was written.
    # Clients post entries retroactively ("I forgot to log Tuesday"), so the
    # two timestamps serve different purposes and must be stored separately.
    add_column :journal_entries, :recorded_at, :datetime

    execute "UPDATE journal_entries SET recorded_at = created_at"

    # Default going forward: if the caller omits recorded_at, assume "right now".
    change_column :journal_entries, :recorded_at, :datetime,
                  null: false, default: -> { "now()" }

    # Feed sort is now on recorded_at, so the index follows.
    remove_index :journal_entries, name: "index_journal_entries_on_client_id_and_created_at"
    add_index :journal_entries, %i[client_id recorded_at]
  end

  def down
    remove_index :journal_entries, name: "index_journal_entries_on_client_id_and_recorded_at"
    add_index :journal_entries, %i[client_id created_at]
    remove_column :journal_entries, :recorded_at
  end
end
