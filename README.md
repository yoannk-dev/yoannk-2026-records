# Vinyl Collection

A personal vinyl record collection tracker built with Rails 8.1. The public can browse the collection; only the owner can add records via Discogs lookup or barcode scan.

This project is a personal demonstration project for my portfolio, and addresses a personal need to easily digitize and manage my record collection.

**Live demo:** https://vinyles.yoann-k.com

---

## Features

- **Browsable collection** — filterable by genre, searchable by artist/title, sortable (alphabetical or by date added), paginated with infinite scroll
- **Record detail panel** — slide-in panel with tracklist, metadata, and sleeve art, driven by Turbo Frames
- **Discogs integration** — look up records by barcode or catalog number to pre-fill the add form (artist, title, label, tracklist, cover art)
- **Barcode scanner** — native `BarcodeDetector` API with a polyfill fallback; requires 3 consecutive identical reads before triggering a lookup
- **Dark / light theme** — persisted to `localStorage`, toggled without a page reload
- **No Redis** — cache, job queue, and WebSocket adapter all use PostgreSQL via Rails 8 solid adapters

---

## Stack

| Layer | Choice |
|-------|--------|
| Backend | Rails 8.1 · Ruby 3.3.5 · PostgreSQL |
| Frontend | Hotwire (Turbo + Stimulus) · Importmap · Propshaft |
| Styles | SCSS via `dartsass-rails` — strict BEM, CSS custom properties for theming |
| Auth | Devise (single owner — `User.first`) |
| Background jobs | `solid_queue` (runs inside Puma) |
| Cache | `solid_cache` |
| WebSockets | `solid_cable` |
| Deployment | Kamal 2 — Docker image, self-hosted server |

---

## Architecture highlights

**Hotwire-first, no client-side framework.** The detail panel, add-record form, and infinite scroll all run through Turbo Frames and Stimulus controllers — no React, no bundler.

**Single Turbo Frame for the panel.** Both `records#show` and `records#new` render inside `<turbo-frame id="panel_content">`. The `panel` Stimulus controller manages the slide animation, URL state via `history.pushState`, and genre filter restoration on close.

**Stimulus conventions.** ES2022 private class fields (`#field`), arrow class fields for stable event handler references, `AbortController` for in-flight fetch cancellation on `disconnect()`.

**SCSS token system.** Design tokens live in `_variables.scss` as both SCSS `$` variables and CSS custom properties (`:root[data-theme]`), giving compile-time access alongside runtime theming.

**Zero-Redis infrastructure.** `solid_cache`, `solid_queue`, and `solid_cable` share the primary PostgreSQL database — no additional services to run or deploy.

---

## Local setup

**Requirements:** Ruby 3.3.5, PostgreSQL, Node (for `dartsass` binary)

```bash
bin/setup        # install gems, create and migrate the database
bin/dev          # start Puma + dartsass watcher
```

**Environment variables:**

| Variable | Required for |
|----------|-------------|
| `DISCOGS_TOKEN` | Discogs lookup and tracklist (owner features) |
| `RAILS_MASTER_KEY` | Credentials decryption (production only) |

Create a `.env` file or export variables before running `bin/dev`.

---

## Deployment

Deployed with [Kamal 2](https://kamal-deploy.org/) to a self-hosted server.

```bash
kamal deploy
```

The only runtime secret is `RAILS_MASTER_KEY`. No Redis, no separate cache or queue services.

---

## Project structure

```
app/
├── controllers/records_controller.rb   # index, show, new, create, discogs_lookup, discogs_tracklist
├── views/
│   ├── layouts/
│   │   ├── application.html.erb        # root layout
│   │   ├── _panel.html.erb             # slide-in panel aside
│   │   └── _scanner.html.erb           # camera overlay (owner only)
│   └── records/
│       ├── index.html.erb
│       ├── show.html.erb               # rendered inside panel turbo-frame
│       ├── new.html.erb                # add-record form, same turbo-frame
│       └── _panel_*.html.erb           # panel partials (cover, meta, tracklist)
├── javascript/
│   ├── controllers/                    # one Stimulus controller per file
│   └── helpers/fetch_json.js           # shared fetch wrapper (AbortController support)
└── assets/stylesheets/
    ├── abstracts/                      # _variables.scss · _mixins.scss
    └── components/                     # one file per UI block
```

---

## Author

Yoann K — [yoannk.dev@gmail.com](mailto:yoannk.dev@gmail.com)
