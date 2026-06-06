# Rails Data Model — Providers, Clients & Journal Entries

A Rails 8 API app modeling dietitian-style **providers**, their **clients**, and client
**journal entries**, with the four required ActiveRecord queries.

## Requirements

- Ruby 3.x (built against 3.4)
- PostgreSQL running locally
- Bundler

## Setup

```bash
bundle install
bin/rails db:create db:migrate db:seed
```

If your local Postgres uses a non-default user/password, set them in `config/database.yml`
(this app connects as the current OS user with no password by default).

## Run the four queries

```bash
bin/rails queries:demo
```

This prints, against seeded data:

1. **All clients for a given provider** — `provider.clients`
2. **All providers for a given client** — `client.providers`
3. **All journal entries for a client, by date** — `client.journal_entries.by_recent`
4. **All journal entries across all of a provider's clients, by date** —
   `provider.journal_entries.by_recent`, which Rails compiles to:
   ```ruby
   JournalEntry
     .joins(client: :enrollments)
     .where(enrollments: { provider_id: provider.id })
     .order(created_at: :desc)
   ```

## Tests

```bash
bundle exec rspec
```

## Schema & key decisions

```
Provider ──< Enrollment >── Client ──< JournalEntry
                │
            plan: basic | premium
```

- **`Enrollment` is a join model**, giving the many-to-many between providers and clients
  (a client can have multiple providers).
- **The plan lives on `Enrollment`, not `Client`** — it's a property of the *relationship*
  ("for each provider a client is signed up with, they have one plan"). Modeled as a string-backed
  Rails enum.
- **Uniqueness** of `(provider_id, client_id)` is enforced both by a DB unique index and a model
  validation (DB index = correctness under concurrency; model validation = friendly errors).
- **Indexes**: unique `[provider_id, client_id]` on enrollments; `[client_id, created_at]` on
  journal entries (serves both the per-client feed and the cross-provider feed without a separate
  sort).

## Intentionally out of scope (let's pair on these)

- **AuthN/AuthZ** — in production I'd scope every query through `enrollments` (row-level
  multi-tenancy, so a provider only sees their own clients' data) with Pundit policies and
  deny-by-default. Especially important here since journal entries are PHI.
- Pagination of journal feeds (keyset/cursor) for large datasets.
- Exposing this via controllers / GraphQL.
