require "rails_helper"

RSpec.describe Provider, type: :model do
  it "requires name and a well-formed, unique email" do
    create(:provider, email: "taken@healthie.example")

    expect(build(:provider, name: nil)).not_to be_valid
    expect(build(:provider, email: "not-an-email")).not_to be_valid
    expect(build(:provider, email: "TAKEN@healthie.example")).not_to be_valid
  end

  describe "#clients (query 1: all clients for a provider)" do
    it "returns enrolled clients only" do
      provider = create(:provider)
      enrolled = create(:client)
      other = create(:client)
      create(:enrollment, provider: provider, client: enrolled)

      expect(provider.clients).to include(enrolled)
      expect(provider.clients).not_to include(other)
    end
  end

  describe "#journal_entries (query 4: across all of a provider's clients)" do
    it "spans every enrolled client and excludes other providers' clients" do
      provider = create(:provider)
      mine = create(:client)
      theirs = create(:client)
      create(:enrollment, provider: provider, client: mine)
      create(:enrollment, provider: create(:provider), client: theirs)

      ours = create(:journal_entry, client: mine, created_at: 1.day.ago)
      newer = create(:journal_entry, client: mine, created_at: 1.hour.ago)
      create(:journal_entry, client: theirs)

      result = provider.journal_entries.by_recent
      expect(result.to_a).to eq([newer, ours])
    end
  end
end
