# Rails Data Model — Providers, Clients & Journal Entries

A Rails 8 API app modeling dietitian-style **providers**, their **clients**, and client
**journal entries**, with the four required ActiveRecord queries.

## Requirements

- Ruby 3.4.2 (via rbenv/asdf — macOS system Ruby will not work)
- PostgreSQL running locally
- Bundler 2.6.3

## Setup

**1. Install Ruby 3.4.2** (skip if already on 3.4.2)

```bash
# macOS via Homebrew
brew install rbenv ruby-build
echo 'eval "$(rbenv init -)"' >> ~/.zshrc && source ~/.zshrc
rbenv install 3.4.2
# .ruby-version in this repo pins the project to 3.4.2 automatically
```

**2. Install dependencies and set up the database**

```bash
gem install bundler:2.6.3
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
     .order(recorded_at: :desc)
   ```

## API endpoints (try them in Postman / curl)

Start the server, then hit the endpoints below. The same four queries are also exposed over HTTP
as JSON.

```bash
bin/rails server     # http://localhost:3000
```

| Query | Method & path | Returns |
| --- | --- | --- |
| Discover IDs | `GET /providers`, `GET /clients` | list of providers / clients |
| 1. Clients for a provider | `GET /providers/:id/clients` | the provider's clients, each with their `plan` |
| 2. Providers for a client | `GET /clients/:id/providers` | the client's providers, each with their `plan` |
| 3. A client's journal entries | `GET /clients/:id/journal_entries` | the client's entries, newest first |
| 4. A provider's clients' entries | `GET /providers/:id/journal_entries` | entries across all the provider's clients, newest first, tagged with the client |
| Post a journal entry | `POST /clients/:id/journal_entries` | creates an entry for the client; `201` on success, `422` with errors if `body` is blank |

Notes:
- All responses are JSON; an unknown `:id` returns a JSON `404`.
- `plan` (basic/premium) is included where relevant because it lives on the provider↔client join.
- IDs are UUIDs (e.g. `"a1b2c3d4-..."`); use the `GET /providers` and `GET /clients` index
  routes to discover real IDs.

Example:

```bash
curl http://localhost:3000/providers
curl http://localhost:3000/providers/{uuid}/journal_entries

# Post a new journal entry for a client:
curl -X POST http://localhost:3000/clients/{uuid}/journal_entries \
  -H 'Content-Type: application/json' \
  -d '{"journal_entry": {"body": "Felt great today."}}'
```

## Tests

```bash
bundle exec rspec        # model specs + request specs for all four endpoints
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
- **`recorded_at`** on `journal_entries` — the user-controlled event timestamp (supports
  backdating). `created_at` remains the system insert time. All journal feeds sort by `recorded_at`.
- **Indexes**: unique `[provider_id, client_id]` on enrollments; `[client_id, recorded_at]` on
  journal entries (serves both the per-client feed and the cross-provider feed without a separate
  sort). Primary keys use UUID (`gen_random_uuid()`).
- **UUID primary keys** on all tables — opaque, no sequential information leaked in IDs.

## Intentionally out of scope

- **AuthN/AuthZ** — in production I'd scope every query through `enrollments` (row-level
  multi-tenancy, so a provider only sees their own clients' data) with Pundit policies and
  deny-by-default. Especially important here since journal entries are PHI.
- **Pagination** — index and list routes accept a `limit` param (1–100, default
  varies by endpoint), but use limit/offset rather than a cursor. Offset pagination degrades at
  scale on time-series feeds.
- **Cache strategies** - for example Redis.
- **Encrypted fields** — PHI columns (`name`, `email`, `body`) are stored as plaintext. Production would use Rails 7+ `encrypts` (non-deterministic for free text, deterministic for indexed/unique fields like `email`).
- **Other HIPAA Compliant Features** - for example audit logs.
