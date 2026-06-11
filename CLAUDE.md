# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
bin/setup          # Install deps, create and migrate the database
bin/dev            # Start development server (Puma + asset watcher)
bin/ci             # Run the full CI suite (linting, security audits — no tests yet)

bin/rubocop        # Lint Ruby (rails-omakase style)
bin/brakeman --quiet --no-pager  # Static security analysis
bin/bundler-audit  # Audit gems for known CVEs

bin/rails db:migrate          # Run pending migrations
bin/rails db:migrate RAILS_ENV=test
bin/rails console             # Rails REPL
```

No test suite is wired up yet (`rails/test_unit/railtie` is commented out in `config/application.rb`).

## Architecture

**Stack:** Rails 8.1 · Ruby 3.3.5 · PostgreSQL · Propshaft · Importmap · Hotwire (Turbo + Stimulus)

**Database-backed adapters** — no Redis or external queue broker needed:
- `solid_cache` — Rails.cache
- `solid_queue` — Active Job (runs inside Puma via `SOLID_QUEUE_IN_PUMA=true`; split to `bin/jobs` process for multi-server setups)
- `solid_cable` — Action Cable

**Single database setup:** all three Solid adapters share the primary database. Their tables are managed via standard migrations in `db/migrate/` and reflected in `db/schema.rb`.

**Frontend:** JavaScript is managed via importmap (no build step). Stimulus controllers live in `app/javascript/controllers/`. Assets served by Propshaft.

**Deployment:** Kamal (`config/deploy.yml`) — builds an amd64 Docker image, pushes to a local registry at `localhost:5555`, and deploys to the server at `192.168.0.1`. `RAILS_MASTER_KEY` is the only secret injected at runtime.

**Style:** Rubocop enforces [rails-omakase](https://github.com/rails/rubocop-rails-omakase) rules (see `.rubocop.yml`). Run `bin/rubocop -a` to auto-correct.
