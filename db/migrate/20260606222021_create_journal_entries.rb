class CreateJournalEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :journal_entries do |t|
      t.references :client, null: false, foreign_key: true
      t.text :body, null: false

      t.timestamps
    end

    # Composite index supports both "a client's entries by date" and the join in
    # "all entries across a provider's clients by date" (filter by client_id,
    # then order by created_at) without a separate sort step.
    add_index :journal_entries, [:client_id, :created_at]
  end
end
