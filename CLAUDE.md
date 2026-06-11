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
bin/rails db:seed             # Create owner user + 18 seed records
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

---

## Domain

**Single-owner vinyl collection app.** One user (seeded, no registration). Public can browse; only the owner can add records.

### Data model

```
labels          — name (unique)
records         — artist, title, label_id, year, format, genre, country,
                  catalog_number, barcode, cover_image_url,
                  cover_bg, cover_fg, cover_motif, tracklist (jsonb),
                  discogs_id
user_records    — user_id, record_id, condition, added_at  ← the collection
users           — Devise (email + bcrypt password, no registration/recovery)
```

`user_records` is the collection join table. `User.first` is always the owner.

### Procedural covers

When `cover_image_url` is blank, records display a CSS-only procedural sleeve. Cover data is stored in three columns: `cover_bg` (background hex), `cover_fg` (foreground hex), `cover_motif` (one of `rings`, `circle`, `split`, `band`, `dots`, `diag`, `lines`, `grid`, `type`). Rendered server-side in `app/views/records/_sleeve.html.erb` via `SleevesHelper#sleeve_motif_tag`.

### Key files

| Path | Purpose |
|------|---------|
| `app/controllers/records_controller.rb` | index (paginated, genre filter), show (panel content) |
| `app/helpers/sleeves_helper.rb` | `sleeve_motif_tag`, `barcode_html` |
| `app/views/records/_sleeve.html.erb` | Procedural cover partial |
| `app/views/records/_record.html.erb` | Grid cell |
| `app/views/records/show.html.erb` | Panel content (inside `<turbo-frame id="panel_content">`) |
| `app/views/layouts/application.html.erb` | Panel + scrim live here; `data-controller="panel"` is on `<body>` |
| `app/assets/stylesheets/application.css` | All styles (no framework) |
| `db/seeds.rb` | Owner user + 18 records |

### Stimulus controllers

| Controller | Responsibility |
|-----------|---------------|
| `panel` | Slide-in detail panel — on `<body>` (must be ancestor of both grid and panel aside). Opens on record link click, closes on Escape/scrim/close button. Pushes URL via `history.pushState`. |
| `panel-disc` | Adds `panel-disc-out` class 50 ms after connecting (triggers CSS slide animation). Lives inside the panel turbo-frame. |
| `theme` | Toggles `data-theme` on `<html>`, persists to `localStorage`. |
| `filter` | Syncs `chip-active` class with the current `?genre=` param on connect. |
| `infinite-scroll` | IntersectionObserver sentinel — fetches next page and appends `.cell` elements to `#records-grid`. |
| `add-prompt` | Shows a login-link tooltip when guest clicks "Add new"; no-op when logged in (sprint 2 will open camera). |

### Auth notes

- Devise with only `:database_authenticatable, :rememberable, :validatable`. No registration, no password reset.
- Routes: `GET/POST /login`, `DELETE /logout` (custom path names via `devise_for`).
- Login form uses `data-turbo="false"` — bypasses Turbo fetch to avoid CSRF/header mismatch with Devise.
- Owner seed password: `SEED_PASSWORD` env var, default `changeme123` (change in production).

### Sprint 2 (not yet built)

US-07–09: barcode scan via device camera (`@zxing/library`), Discogs API lookup (`GET /database/search?barcode=…&token=DISCOGS_TOKEN`), confirm + create record. `DISCOGS_TOKEN` must be in env.
