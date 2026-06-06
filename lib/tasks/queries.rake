# Demonstrates the four required ActiveRecord queries against seeded data.
# Run with: bin/rails queries:demo  (after db:seed)
namespace :queries do
  desc "Print the four required queries against seeded data"
  task demo: :environment do
    provider = Provider.first
    client = Client.first

    abort "No data found - run `bin/rails db:seed` first." unless provider && client

    line = "-" * 72

    puts line
    puts "1. All clients for provider ##{provider.id} (#{provider.name})"
    puts line
    # provider.clients composes a JOIN through enrollments.
    provider.clients.each { |c| puts "  - #{c.name} <#{c.email}>" }

    puts
    puts line
    puts "2. All providers for client ##{client.id} (#{client.name})"
    puts line
    client.providers.each do |p|
      plan = Enrollment.find_by(provider: p, client: client).plan
      puts "  - #{p.name} <#{p.email}>  [plan: #{plan}]"
    end

    puts
    puts line
    puts "3. All journal entries for client ##{client.id} (#{client.name}), newest first"
    puts line
    client.journal_entries.by_recent.each do |e|
      puts "  - #{e.created_at.to_date}  #{e.body.truncate(60)}"
    end

    puts
    puts line
    puts "4. All journal entries across all of provider ##{provider.id}'s clients, newest first"
    puts line
    # Clean version via the through-association:
    #   provider.journal_entries.by_recent
    # which Rails compiles to the explicit join below:
    entries = JournalEntry
                .joins(client: :enrollments)
                .where(enrollments: { provider_id: provider.id })
                .order(created_at: :desc)
    entries.each do |e|
      puts "  - #{e.created_at.to_date}  [#{e.client.name}]  #{e.body.truncate(50)}"
    end

    puts
    puts "Tip: same result as `provider.journal_entries.by_recent` " \
         "(#{provider.journal_entries.count} entries)."
  end
end
