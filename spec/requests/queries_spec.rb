require "rails_helper"

# Exercises the four required queries through their REST endpoints.
RSpec.describe "Query endpoints", type: :request do
  let(:provider) { create(:provider) }
  let(:other_provider) { create(:provider) }
  let(:alice) { create(:client) }
  let(:bob) { create(:client) }

  before do
    create(:enrollment, provider: provider, client: alice, plan: :premium)
    create(:enrollment, provider: provider, client: bob, plan: :basic)
    create(:enrollment, provider: other_provider, client: bob, plan: :basic)
  end

  def json
    JSON.parse(response.body)
  end

  describe "GET /providers/:id/clients (query 1)" do
    it "returns the provider's clients with their plan" do
      get "/providers/#{provider.id}/clients"

      expect(response).to have_http_status(:ok)
      expect(json.map { |c| c["name"] }).to contain_exactly(alice.name, bob.name)
      expect(json.find { |c| c["id"] == alice.id }["plan"]).to eq("premium")
    end
  end

  describe "GET /clients/:id/providers (query 2)" do
    it "returns every provider the client is enrolled with" do
      get "/clients/#{bob.id}/providers"

      expect(response).to have_http_status(:ok)
      expect(json.map { |p| p["id"] }).to contain_exactly(provider.id, other_provider.id)
    end
  end

  describe "GET /clients/:id/journal_entries (query 3)" do
    it "returns the client's entries, newest first by recorded_at" do
      old    = create(:journal_entry, client: alice, body: "older", recorded_at: 2.days.ago)
      recent = create(:journal_entry, client: alice, body: "newer", recorded_at: 1.hour.ago)

      get "/clients/#{alice.id}/journal_entries"

      expect(response).to have_http_status(:ok)
      expect(json.map { |e| e["id"] }).to eq([recent.id, old.id])
    end

    it "respects a limit param" do
      create_list(:journal_entry, 5, client: alice)

      get "/clients/#{alice.id}/journal_entries", params: { limit: 3 }

      expect(json.size).to eq(3)
    end
  end

  describe "POST /clients/:id/journal_entries" do
    it "creates a journal entry for the client" do
      expect {
        post "/clients/#{alice.id}/journal_entries",
             params: { journal_entry: { body: "Felt great today." } }
      }.to change { alice.journal_entries.count }.by(1)

      expect(response).to have_http_status(:created)
      expect(json["body"]).to eq("Felt great today.")
      expect(json["client_id"]).to eq(alice.id)
    end

    it "accepts a backdated recorded_at" do
      past = 3.days.ago.iso8601
      post "/clients/#{alice.id}/journal_entries",
           params: { journal_entry: { body: "Forgot to log this.", recorded_at: past } }

      expect(response).to have_http_status(:created)
      expect(Time.parse(json["recorded_at"])).to be_within(1.second).of(Time.parse(past))
    end

    it "rejects a blank body with a 422 and error messages" do
      post "/clients/#{alice.id}/journal_entries",
           params: { journal_entry: { body: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to be_present
    end
  end

  describe "GET /providers/:id/journal_entries (query 4)" do
    it "spans all the provider's clients, newest first, tagged with the client" do
      a = create(:journal_entry, client: alice, recorded_at: 1.day.ago)
      b = create(:journal_entry, client: bob,   recorded_at: 1.hour.ago)
      create(:journal_entry, client: create(:client), recorded_at: 1.minute.ago) # other provider

      get "/providers/#{provider.id}/journal_entries"

      expect(response).to have_http_status(:ok)
      expect(json.map { |e| e["id"] }).to eq([b.id, a.id])
      expect(json.first["client"]["name"]).to eq(bob.name)
    end
  end

  describe "unknown id" do
    it "returns a JSON 404" do
      get "/providers/#{SecureRandom.uuid}/clients"

      expect(response).to have_http_status(:not_found)
      expect(json).to have_key("error")
    end
  end
end
