# CLAUDE.md

Single-owner vinyl collection app. Public can browse, only the owner can add records.

## Commands

```bash
bin/setup          # Install deps, create and migrate the database
bin/dev            # Start dev server (Puma + dartsass watcher)
bin/ci             # Lint + security audit (no test suite yet)

bin/rubocop -a                    # Lint + auto-correct (rails-omakase style)
bin/brakeman --quiet --no-pager   # Static security analysis
bin/bundler-audit                 # CVE audit

bin/rails dartsass:build          # One-off SCSS compile → app/assets/builds/application.css
bin/rails db:migrate
bin/rails console
```

No test suite (`rails/test_unit/railtie` is commented out in `config/application.rb`).

## Stack

**Backend:** Rails 8.1 · Ruby 3.3.5 · PostgreSQL  
**Frontend:** Importmap (no build step) · Hotwire (Turbo + Stimulus) · Propshaft · SCSS via `dartsass-rails`  
**Deployment:** Kamal — amd64 Docker image, local registry at `localhost:5555`, server at `192.168.0.1`. `RAILS_MASTER_KEY` is the only runtime secret.

**Database-backed adapters** (no Redis):
- `solid_cache` — Rails.cache
- `solid_queue` — Active Job (runs inside Puma via `SOLID_QUEUE_IN_PUMA=true`)
- `solid_cable` — Action Cable

All three share the primary database; tables are in standard migrations / `db/schema.rb`.

## Environment variables

| Variable | Required | Purpose |
|----------|----------|---------|
| `DISCOGS_TOKEN` | Yes (owner features) | Discogs API auth for lookup + tracklist |
| `RAILS_MASTER_KEY` | Yes (production) | Credentials decryption |

## Routing

`GET /` is the only collection URL (`records#index`). `/records` does **not** exist.  
Always use `root_path`, never `records_path`, for collection links and pagination.

```ruby
root "records#index"
resources :records, only: [:show, :create] do
  collection do
    get :new                 # confirm form pre-filled from Discogs
    get :discogs_lookup      # → /records/discogs_lookup?barcode= or ?catno=
    get :discogs_tracklist   # → /records/discogs_tracklist?discogs_id=
  end
end
# Auth: GET/POST /login, DELETE /logout (custom devise_for paths)
```

## Data model

```
labels        — name (unique)
records       — artist, title, label_id, year, format, genre, country,
                catalog_number, barcode, cover_image_url,
                tracklist (jsonb), discogs_id
user_records  — user_id, record_id, condition, added_at   ← the collection join table
users         — Devise (database_authenticatable, rememberable, validatable)
```

`User.first` is always the owner. `user_records` links users to records with condition/date.

## Key conventions

**Tracklist format** — stored as a JSONB hash keyed by lowercase side letter: `{ "a" => ["Track 1", …], "b" => […], "c" => […] }`. Any number of sides is supported. The panel partial iterates `tl.sort.flat_map(&:last)`.

**Panel / Turbo Frame** — the detail panel and the add-record form both render inside `<turbo-frame id="panel_content">`. The `panel` Stimulus controller lives on `<body>` (must be ancestor of both the grid and the panel aside). It pushes URL via `history.pushState` and restores the genre filter on close.

**Auth** — login form uses `data-turbo="false"` to bypass Turbo fetch (avoids CSRF/header mismatch with Devise). No registration or password reset.

## Key files

| Path | Purpose |
|------|---------|
| `app/controllers/records_controller.rb` | index, show, new (Discogs pre-fill), create, discogs_lookup, discogs_tracklist |
| `app/views/records/_sleeve.html.erb` | Album cover image wrapper |
| `app/views/records/_record.html.erb` | Grid cell |
| `app/views/records/_masthead.html.erb` | Hero header with animated disc + stats |
| `app/views/records/_topbar.html.erb` | Genre filter chips + action buttons |
| `app/views/records/_panel_cover.html.erb` | Vinyl disc + sleeve in the detail panel |
| `app/views/records/_panel_meta.html.erb` | Label / Cat # / Format / Condition grid |
| `app/views/records/_panel_tracklist.html.erb` | Multi-side tracklist (A, B, C, D…) |
| `app/views/records/show.html.erb` | Record detail inside `<turbo-frame id="panel_content">` |
| `app/views/records/new.html.erb` | Add-record form (Discogs pre-filled) inside same turbo-frame |
| `app/views/layouts/application.html.erb` | Root layout — `data-controller="panel"` on `<body>` |
| `app/views/layouts/_panel.html.erb` | Scrim overlay + panel aside |
| `app/views/layouts/_scanner.html.erb` | FAB button + camera overlay (owner only) |
| `app/javascript/helpers/fetch_json.js` | Shared JSON fetch wrapper — sets Accept header, throws on HTTP errors with `.status` attached, supports `AbortController` via `signal` option |
| `app/assets/stylesheets/application.scss` | SCSS entry point (imports only) |
| `app/assets/stylesheets/abstracts/` | `_variables.scss` (SCSS tokens + CSS custom properties) · `_mixins.scss` (flex, truncate, label-uppercase, respond-to, reduced-motion) |
| `app/assets/stylesheets/components/` | One file per UI block |

## JavaScript architecture

```
app/javascript/
├── application.js              ← entry point (imports turbo-rails + controllers)
├── controllers/                ← one file per Stimulus controller
│   └── *_controller.js
└── helpers/                    ← pure utility modules, no Stimulus dependency
    └── fetch_json.js           ← fetchJSON(url, { signal }) — used by scanner
```

`config/importmap.rb` pins both folders:
```ruby
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/helpers", under: "helpers"
```

**Conventions:**
- ES2022 private class fields (`#field`, `#method()`) — no `_` underscore prefix
- Event handlers that need stable references (for `removeEventListener`) are declared as **arrow class fields**: `#onX = () => { … }` — same reference, no `.bind()`
- `initialize()` for one-time setup (runs once per controller instance even across Turbo reconnections); `connect()` for setup that must repeat on each reconnect
- All controllers use `AbortController` for in-flight fetch cancellation in `disconnect()`

**ARIA — pending JS controller work** (HTML attributes are set; controllers must now sync them):
- `panel` controller: toggle `aria-hidden` on `<aside#panel>` alongside `panel--open`
- `scanner` controller: toggle `aria-hidden` on `.scanner[role="dialog"]` alongside `scanner--open`; manage `aria-selected` on mode tabs alongside `is-active`; implement focus trap (focus first interactive element on open, return focus to FAB on close)

## SCSS architecture

**Convention:** strict BEM — `__` for elements, `--` for modifiers, `is-` prefix for JS-toggled states, `u-` prefix for utilities.

**Abstracts** (`app/assets/stylesheets/abstracts/`):
- `_variables.scss` — SCSS `$` tokens (spacing, font sizes/weights, border-radius, durations, breakpoints) + CSS custom properties (`:root[data-theme]` blocks for runtime theming).
- `_mixins.scss` — forwards `_variables.scss` (so components only need one `@use "../abstracts/mixins" as *`), then defines: `flex()`, `truncate()`, `label-uppercase()`, `respond-to()`, `reduced-motion`.

**Key token values:**

| Token | Value | Token | Value |
|-------|-------|-------|-------|
| `$spacing-xs` | 8px | `$font-size-md` | 13px |
| `$spacing-md` | 16px | `$font-size-lg` | 14px |
| `$spacing-lg` | 24px | `$font-weight-bold` | 700 |
| `$spacing-xl` | 28px (standard side padding) | `$font-weight-extrabold` | 800 |
| `$spacing-xxl` | 36px | `$border-radius-md` | 8px |
| `$duration-fast` | 0.15s | `$border-radius-pill` | 999px |
| `$bp-mobile` | 720px | `$border-radius-circle` | 50% |

**JS-toggled classes** — controllers must use these exact names:

| Class | Added by |
|-------|---------|
| `.panel--open` | `panel` controller |
| `.scrim--open` | `panel` controller |
| `.panel__disc--out` | `panel-disc` controller (50 ms after connect) |
| `.chip--active` | `filter` controller |
| `.scanner--open` | `scanner` controller |
| `.is-active` | `scanner` controller (mode tabs) |
| `.u-hidden` | `scanner` controller (show/hide elements) |

**Utility classes** — defined in SCSS, not toggled by JS:

| Class | Purpose |
|-------|---------|
| `.u-visually-hidden` | Visually hidden but accessible to screen readers (used for dialog titles) |

## Stimulus controllers

| Controller | Responsibility |
|-----------|---------------|
| `panel` | Slide-in detail panel on `<body>`. Opens on record click, closes on Escape / scrim / close button. Pushes URL, restores genre filter on close. |
| `panel-disc` | Adds `panel__disc--out` class 50 ms after connect to trigger CSS slide animation. Lives inside the panel turbo-frame. |
| `scanner` | Camera overlay with two modes — `barcode` (native `BarcodeDetector` + polyfill, requires 3 consecutive identical reads) and `catno` (manual entry). Calls `discogs_lookup` then `discogs_tracklist`, then loads `new.html.erb` into `panel_content`. Falls back to manual input on camera denial or unsupported browser. |
| `add-prompt` | Shows login-link tooltip for guests; triggers `scanner#open` when logged in. |
| `theme` | Toggles `data-theme` on `<html>`, persists to `localStorage`. |
| `filter` | Syncs `chip--active` class and `aria-current="page"` with current `?genre=` param on connect. |
| `infinite-scroll` | IntersectionObserver sentinel — fetches next page and appends `.cell` elements to `#records-grid`. |
