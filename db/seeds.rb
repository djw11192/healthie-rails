# Idempotent seed data: two providers, three clients with overlapping
# enrollments (a client can have more than one provider, each with its own plan),
# and journal entries spread across several dates.
#
# Load with: bin/rails db:seed   (reset with: bin/rails db:reset)

puts "Clearing existing data..."
JournalEntry.delete_all
Enrollment.delete_all
Client.delete_all
Provider.delete_all

puts "Creating providers..."
beth = Provider.create!(name: "Beth Smith, RD", email: "beth@healthie.example")
wong = Provider.create!(name: "Dr. Wong", email: "wong@healthie.example")

puts "Creating clients..."
jerry = Client.create!(name: "Jerry Smith", email: "jerry@example.com")
morty = Client.create!(name: "Morty Smith", email: "morty@example.com")
summer = Client.create!(name: "Summer Smith", email: "summer@example.com")

puts "Enrolling clients with providers (note overlapping + differing plans)..."
Enrollment.create!(provider: beth, client: jerry, plan: :premium)
Enrollment.create!(provider: beth, client: morty, plan: :basic)
Enrollment.create!(provider: wong, client: morty, plan: :premium) # Morty sees both providers
Enrollment.create!(provider: wong, client: summer, plan: :basic)

puts "Creating journal entries across several dates..."
entries = [
  [jerry, 6, "Felt low energy today, skipped the afternoon walk."],
  [jerry, 4, "Hit my protein goal! Big improvement."],
  [jerry, 1, "Slept 8 hours, mood much better."],
  [morty, 5, "Anxious about school, ate poorly."],
  [morty, 3, "Tried the new meal plan - the smoothies are great."],
  [morty, 0, "Good day overall, steady energy."],
  [summer, 2, "Started journaling. Drank more water than usual."],
]

entries.each do |client, days_ago, body|
  client.journal_entries.create!(body: body, created_at: days_ago.days.ago)
end

puts "Done. #{Provider.count} providers, #{Client.count} clients, " \
     "#{Enrollment.count} enrollments, #{JournalEntry.count} journal entries."
