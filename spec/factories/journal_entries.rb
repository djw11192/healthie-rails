FactoryBot.define do
  factory :journal_entry do
    association :client
    body { "A freeform journal entry." }
  end
end
