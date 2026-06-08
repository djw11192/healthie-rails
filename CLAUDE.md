# CLAUDE.md — Rails Data Model (Healthie Interview Pre-work)

## What this project is

Pre-work for a Healthie engineering pairing session. The domain models dietitian-style **providers**, their **clients**, and client **journal entries** — a PHI-bearing healthcare dataset.

### Session 1 brief (verbatim)
> Both providers and clients have a name and email address. Providers have many clients; clients can have more than one provider. For each provider a client is signed up with, they have one plan — either "basic" or "premium". Clients can post journal entries consisting of freeform text.
>
> Include working ActiveRecord queries for:
> - All clients for a given provider
> - All providers for a given client
> - All journal entries for a given client, sorted by date
> - All journal entries across all clients of a given provider, sorted by date
>
> We'll talk through your schema design and tradeoffs. Then we'll pair on adding something new — likely a query, a validation, or a small model extension. We may ask: "How would you approach this differently if the dataset were very large?"

---

## Schema

```
Provider ──< Enrollment >── Client ──< JournalEntry
                │
            plan: basic | premium
```

- **`Enrollment`** is the join model. `plan` lives here because it is a property of the *relationship*, not of the client.
- Uniqueness on `(provider_id, client_id)` enforced at both DB (unique index) and model layer.
- Email columns use the `citext` Postgres extension — case-insensitive comparisons are enforced at the DB level, not just in Rails validations.
- Composite index `[client_id, created_at]` on `journal_entries` covers the per-client feed and the cross-provider feed without a redundant single-column index.

---

## HIPAA / PHI priorities

Journal entries, client names, and client emails are **Protected Health Information (PHI)**. Every change to this codebase should be evaluated against these concerns:

### Already in place
- PHI parameters (`:name`, `:body`, `:email`) are filtered from Rails logs via `config/initializers/filter_parameter_logging.rb`.
- `ActionController::API` (no cookie session, no HTML rendering surface).

### Intentionally deferred — bring up in the pairing session
- **Encryption at rest**: `journal_entry.body`, `client.name`, `client.email` are stored as plaintext. The right fix is Rails 7+ built-in encryption:
  ```ruby
  # JournalEntry
  encrypts :body                          # non-deterministic (random IV)

  # Client
  encrypts :name
  encrypts :email, deterministic: true    # deterministic so the unique index works
  ```
  Requires `bin/rails db:encryption:init` and committing the output to credentials.
- **Audit logging**: HIPAA §164.312(b) requires a record of who accessed PHI and when. Candidates: `paper_trail` gem for writes + a custom access log for reads.
- **Authorization**: any authenticated provider can currently read any client's data. Production requires Pundit policies scoping every query through `enrollments` (row-level multi-tenancy). See README "Intentionally out of scope" section.
- **Authentication**: no AuthN at all. In production, devise-jwt or a token-based scheme.

---

## The four required queries (where they live)

| # | Query | Model method | Controller |
|---|-------|-------------|------------|
| 1 | All clients for a provider | `provider.clients` | `ProvidersController#clients` |
| 2 | All providers for a client | `client.providers` | `ClientsController#providers` |
| 3 | A client's journal entries by date | `client.journal_entries.by_recent` | `JournalEntriesController#index` |
| 4 | All journal entries across a provider's clients by date | `provider.journal_entries.by_recent` | `ProvidersController#journal_entries` |

Query 4 uses `has_many :journal_entries, through: :clients` and Rails compiles it to a two-JOIN query through `enrollments → clients → journal_entries`.

---

## Scale discussion (likely pairing question)

Key talking points if asked "how would you approach this differently at very large scale?":

- **Keyset/cursor pagination** on journal feeds instead of offset — offset scans all skipped rows.
- **Partial index** on `journal_entries (client_id, created_at)` filtered to recent entries if the feed only ever shows the last N.
- **Read replica** for the four read queries; writes go to primary.
- **Denormalized counter caches** on `enrollments` if entry counts are displayed on dashboards.
- **Encryption key rotation** strategy matters more at scale — envelope encryption (per-record DEK wrapped by a KMS-managed KEK) rather than a single app-wide key.

---

## Development commands

```bash
bin/rails db:create db:migrate db:seed   # first-time setup
bin/rails queries:demo                   # run the four queries against seed data
bin/rails server                         # http://localhost:3000
bundle exec rspec                        # full test suite
```
