class CreateEnrollments < ActiveRecord::Migration[8.1]
  def change
    create_table :enrollments do |t|
      t.references :provider, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.string :plan, null: false, default: "basic"

      t.timestamps
    end

    # A client has exactly one plan per provider they're signed up with.
    # Enforced at the DB level, not just in the model, so concurrent inserts
    # can't create duplicate (provider, client) pairs.
    add_index :enrollments, [:provider_id, :client_id], unique: true
  end
end
