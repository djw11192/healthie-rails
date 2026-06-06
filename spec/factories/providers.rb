FactoryBot.define do
  factory :provider do
    sequence(:name) { |n| "Provider #{n}" }
    sequence(:email) { |n| "provider#{n}@healthie.example" }
  end
end
