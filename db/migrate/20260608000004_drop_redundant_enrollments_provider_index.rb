class DropRedundantEnrollmentsProviderIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :enrollments, :provider_id, name: "index_enrollments_on_provider_id"
  end
end
