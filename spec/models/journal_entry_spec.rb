require "rails_helper"

RSpec.describe JournalEntry, type: :model do
  it "requires a body" do
    expect(build(:journal_entry, body: nil)).not_to be_valid
  end

  describe ".by_recent" do
    it "orders entries newest first by recorded_at" do
      client = create(:client)
      old    = create(:journal_entry, client: client, recorded_at: 3.days.ago)
      recent = create(:journal_entry, client: client, recorded_at: 1.hour.ago)

      expect(client.journal_entries.by_recent.to_a).to eq([recent, old])
    end

    it "uses recorded_at, not created_at, so backfilled entries sort correctly" do
      client = create(:client)
      # Entered today but describes an event from last week
      backdated = create(:journal_entry, client: client, recorded_at: 1.week.ago)
      recent    = create(:journal_entry, client: client, recorded_at: 1.hour.ago)

      expect(client.journal_entries.by_recent.first).to eq(recent)
      expect(client.journal_entries.by_recent.last).to  eq(backdated)
    end
  end
end
