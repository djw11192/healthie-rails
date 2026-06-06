require "rails_helper"

RSpec.describe JournalEntry, type: :model do
  it "requires a body" do
    expect(build(:journal_entry, body: nil)).not_to be_valid
  end

  describe ".by_recent" do
    it "orders entries newest first" do
      client = create(:client)
      old = create(:journal_entry, client: client, created_at: 3.days.ago)
      recent = create(:journal_entry, client: client, created_at: 1.hour.ago)

      expect(client.journal_entries.by_recent.to_a).to eq([recent, old])
    end
  end
end
