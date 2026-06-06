require "rails_helper"

RSpec.describe Enrollment, type: :model do
  it "defaults to the basic plan" do
    expect(build(:enrollment).plan).to eq("basic")
  end

  it "supports basic and premium plans" do
    expect(Enrollment.plans.keys).to contain_exactly("basic", "premium")
  end

  it "is unique per (provider, client) pair" do
    provider = create(:provider)
    client = create(:client)
    create(:enrollment, provider: provider, client: client)

    dup = build(:enrollment, provider: provider, client: client)
    expect(dup).not_to be_valid
    expect(dup.errors[:provider_id]).to be_present
  end

  it "allows the same client to enroll with different providers" do
    client = create(:client)
    create(:enrollment, provider: create(:provider), client: client, plan: :basic)
    second = build(:enrollment, provider: create(:provider), client: client, plan: :premium)

    expect(second).to be_valid
  end
end
