require "rails_helper"

RSpec.describe Client, type: :model do
  it "requires name and a well-formed, unique email" do
    create(:client, email: "taken@example.com")

    expect(build(:client, name: nil)).not_to be_valid
    expect(build(:client, email: "nope")).not_to be_valid
    expect(build(:client, email: "TAKEN@example.com")).not_to be_valid
  end

  describe "#providers (query 2: all providers for a client)" do
    it "returns every provider the client is enrolled with" do
      client = create(:client)
      p1 = create(:provider)
      p2 = create(:provider)
      create(:enrollment, provider: p1, client: client)
      create(:enrollment, provider: p2, client: client)

      expect(client.providers).to contain_exactly(p1, p2)
    end
  end

  describe "#journal_entries (query 3: a client's entries by date)" do
    it "returns the client's entries, newest first" do
      client = create(:client)
      older = create(:journal_entry, client: client, recorded_at: 2.days.ago)
      newer = create(:journal_entry, client: client, recorded_at: 1.hour.ago)

      expect(client.journal_entries.by_recent.to_a).to eq([newer, older])
    end
  end

  describe "PHI retention" do
    it "cannot be destroyed while journal entries exist" do
      client = create(:client)
      create(:journal_entry, client: client)

      expect { client.destroy }.not_to change { Client.count }
      expect(client.errors[:base]).to be_present
    end

    it "can be destroyed once all journal entries are removed" do
      client = create(:client)
      create(:journal_entry, client: client).destroy

      expect { client.destroy }.to change { Client.count }.by(-1)
    end
  end
end
