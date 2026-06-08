# frozen_string_literal: true

class ConvertPrimaryKeysToUuid < ActiveRecord::Migration[8.1]
  def up
    enable_extension "pgcrypto"

    # Phase 1 — Add UUID shadow columns everywhere before touching any PK.
    # FK columns need UUID siblings so we can populate them while the integer
    # IDs still exist for joining.
    add_column :providers,      :uuid_pk,      :uuid, default: -> { "gen_random_uuid()" }, null: false
    add_column :clients,        :uuid_pk,      :uuid, default: -> { "gen_random_uuid()" }, null: false
    add_column :enrollments,    :uuid_pk,      :uuid, default: -> { "gen_random_uuid()" }, null: false
    add_column :enrollments,    :provider_uuid, :uuid
    add_column :enrollments,    :client_uuid,   :uuid
    add_column :journal_entries,:uuid_pk,      :uuid, default: -> { "gen_random_uuid()" }, null: false
    add_column :journal_entries,:client_uuid,  :uuid

    # Phase 2 — Resolve FK mappings while integer join columns are still in place.
    execute <<~SQL
      UPDATE enrollments e
         SET provider_uuid = p.uuid_pk,
             client_uuid   = c.uuid_pk
        FROM providers p, clients c
       WHERE p.id = e.provider_id
         AND c.id = e.client_id
    SQL

    execute <<~SQL
      UPDATE journal_entries je
         SET client_uuid = c.uuid_pk
        FROM clients c
       WHERE c.id = je.client_id
    SQL

    # Phase 3 — Drop FK constraints and indexes before altering PK columns.
    remove_foreign_key :enrollments,    :clients
    remove_foreign_key :enrollments,    :providers
    remove_foreign_key :journal_entries,:clients

    remove_index :enrollments, name: "index_enrollments_on_client_id"
    remove_index :enrollments, name: "index_enrollments_on_provider_id"
    remove_index :enrollments, name: "index_enrollments_on_provider_id_and_client_id"
    remove_index :journal_entries, name: "index_journal_entries_on_client_id_and_recorded_at"
    remove_index :providers, name: "index_providers_on_email"
    remove_index :clients,   name: "index_clients_on_email"

    # Phase 4 — Swap each table's integer PK for its UUID shadow column.
    %i[providers clients enrollments journal_entries].each do |table|
      execute "ALTER TABLE #{table} DROP CONSTRAINT #{table}_pkey"
      remove_column table, :id
      rename_column table, :uuid_pk, :id
      execute "ALTER TABLE #{table} ADD PRIMARY KEY (id)"
    end

    # Phase 5 — Swap FK columns.
    remove_column :enrollments, :provider_id
    remove_column :enrollments, :client_id
    rename_column :enrollments, :provider_uuid, :provider_id
    rename_column :enrollments, :client_uuid,   :client_id
    change_column_null :enrollments, :provider_id, false
    change_column_null :enrollments, :client_id,   false

    remove_column :journal_entries, :client_id
    rename_column :journal_entries, :client_uuid, :client_id
    change_column_null :journal_entries, :client_id, false

    # Phase 6 — Recreate indexes and FK constraints.
    add_index :providers, :email, unique: true
    add_index :clients,   :email, unique: true
    add_index :enrollments, :provider_id
    add_index :enrollments, :client_id
    add_index :enrollments, %i[provider_id client_id], unique: true
    add_index :journal_entries, %i[client_id recorded_at]

    add_foreign_key :enrollments,    :providers
    add_foreign_key :enrollments,    :clients
    add_foreign_key :journal_entries,:clients
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "Converting UUIDs back to integer PKs requires manual data mapping"
  end
end
