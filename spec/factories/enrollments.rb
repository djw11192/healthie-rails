FactoryBot.define do
  factory :enrollment do
    association :provider
    association :client
    plan { "basic" }
  end
end
