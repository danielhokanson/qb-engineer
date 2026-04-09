# QB Engineer

**Open source manufacturing operations platform — the operational layer that sits alongside your accounting system.**

QB Engineer is a locally hosted web application for small and mid-size manufacturers. Your accounting system (QuickBooks Online by default, with pluggable support for Xero, Sage, and others) handles the finances. QB Engineer handles everything else: job tracking, production workflow, purchasing, order management, inventory, employee compliance, training, and an engineer-focused dashboard. Works in standalone mode without any accounting system too.

No SaaS fees. No cloud dependency. Runs entirely in Docker on your own infrastructure.

---

## What's Included

### Production & Shop Floor
- **Kanban board** with configurable track types (Production, R&D, Maintenance, custom), WIP limits, swimlane view, and multi-select bulk actions
- **Job cards** with subtasks, file attachments, status timeline, activity log, and BOM/part links
- **Shop floor kiosk** — touch-optimized display with RFID/NFC/barcode + PIN authentication for shop floor workers
- **Sprint planning cycles** with 2-week cycles, backlog curation, drag-to-commit, and Planning Day guided flow
- **Production lots and traceability** supporting FDA 21 CFR Part 820 / ISO 13485 when needed

### Parts, Inventory & Quality
- **Part catalog** with recursive BOM, revision control, Make/Buy/Stock classification, process steps, and inline STL 3D viewing
- **Inventory** with multi-location bin tracking, bin movements, receiving, and quantity-on-hand rollups
- **Quality control** with QC templates, inspection records, and production run integration

### Order Management (Quote-to-Cash)
- **Quotes** → **Sales Orders** → **Shipments** → **Invoices** → **Payments** (full lifecycle)
- **Purchase Orders** with line-level receiving
- **Price lists** with quantity break pricing
- **Recurring order templates** via Hangfire scheduling
- **Customer address management** (multi-address per customer)
- **Vendor management** with full CRUD
- **Sales tax** per state/jurisdiction with invoice calculation
- **Customer returns** with resolve/close lifecycle

### People & HR
- **Time tracking** with job timers and attendance clock-in/clock-out; feeds into QB Payroll
- **Expense capture** with receipt photos, job linking, and manager approval queue
- **Employee compliance forms** — W-4, I-9, state withholding (PDF extraction pipeline, DocuSeal e-signature)
- **Payroll** — pay stubs and tax documents; employee self-service + admin upload
- **Employee training LMS** — 46 seeded modules, 8 learning paths, quiz pools, walkthrough video generation with voiced narration

### Reporting & Intelligence
- **Dynamic report builder** — 28 entity sources, 350+ queryable fields, 27 pre-seeded templates, charts, CSV/PDF export
- **AI assistant** (optional, self-hosted Ollama) — smart search, document Q&A, RAG pipeline over your own data
- **Configurable AI assistants** — HR, Procurement, Sales domain assistants with admin panel

### Collaboration
- **Chat** — 1:1 DMs and group rooms with real-time SignalR messaging and entity/file sharing
- **Notifications** — real-time push with severity levels, pinning, dismissal, and SMTP email digests

### Admin & Configuration
- **User management** with six additive roles (Engineer, PM, Production Worker, Manager, Office Manager, Admin)
- **Tiered authentication** — credentials, SSO (Google/Microsoft/OIDC), and kiosk auth (RFID/NFC/barcode + PIN)
- **Admin panel** — track types, reference data, terminology overrides, integrations, compliance templates
- **Company profile and locations** — multiple locations with per-employee location assignment for state withholding
- **Integration settings** — QB, SMTP, MinIO, AI, TTS configurable from the UI

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Angular 21 + Angular Material 21 (zoneless, signals) |
| Backend | .NET 9 Web API (MediatR CQRS, FluentValidation) |
| Database | PostgreSQL 16 + pgvector (RAG embeddings) |
| File Storage | MinIO (S3-compatible, self-hosted) |
| Real-time | SignalR (board, notifications, timers, chat) |
| Background Jobs | Hangfire (default + video queue) |
| ORM | Entity Framework Core + Npgsql |
| PDF | QuestPDF (server-side), pdf.js via PuppeteerSharp (extraction) |
| 3D Viewer | Three.js (STL files) |
| AI (optional) | Ollama (llama3.2:3b) + pgvector RAG |
| TTS (optional) | Coqui TTS — self-hosted voiced narration for training videos |
| Document Signing | DocuSeal (self-hosted e-signature) |
| Barcode/QR | bwip-js + angularx-qrcode |
| Charts | ng2-charts (Chart.js) |
| Logging | Serilog |
| Containerization | Docker Compose (5 core services + 3 optional profiles: ai, tts, signing) |

See [docs/libraries.md](docs/libraries.md) for the complete library reference.

---

## System Requirements

### Minimum (core stack, no optional profiles)

- Docker Engine 24+ and Docker Compose v2
- 4 GB RAM
- 20 GB disk (grows with file storage)
- Any x86_64 Linux, Windows, or macOS host

### With AI profile (Ollama)

- 16 GB RAM for CPU-only inference
- NVIDIA GPU with 8+ GB VRAM for responsive AI (requires `nvidia-container-toolkit`)
- 50 GB disk (model weights ~4 GB)

### With TTS profile (Coqui)

- +2 GB RAM (CPU inference, ~500 MB model download on first start)

### Browser Support

- Chrome, Edge, Firefox, Safari (latest 2 versions)
- Responsive down to 768px viewport width
- Shop floor kiosk: 1280×800 minimum (full-screen recommended)

---

## Quick Start

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) or Docker Engine + Compose
- [Git](https://git-scm.com/)

> **Linux users:** Your user must be in the `docker` group to run Docker commands without `sudo`. Run `sudo usermod -aG docker $USER` and then **log out and back in** for the change to take effect. Without this you will get `permission denied while trying to connect to the Docker daemon`.

### Automated Setup (Recommended)

The setup script checks all prerequisites, creates your `.env`, generates a secure JWT key, builds images, and starts the stack:

```bash
git clone https://github.com/danielhokanson/qb-engineer-wrapper.git
cd qb-engineer-wrapper

# Core stack only (ui, api, db, storage, backup)
.\setup.ps1

# Include optional profiles
.\setup.ps1 -IncludeAi           # Ollama AI assistant
.\setup.ps1 -IncludeTts          # Coqui TTS for training video narration
.\setup.ps1 -IncludeSigning      # DocuSeal e-signature service
.\setup.ps1 -IncludeAll          # All optional profiles
```

If a prerequisite is missing (Git, Docker, Docker Compose), the script will tell you exactly what to install and where to get it.

### Manual Setup

```bash
git clone https://github.com/danielhokanson/qb-engineer-wrapper.git
cd qb-engineer-wrapper

# Copy environment template and configure
cp .env.example .env
# Edit .env — at minimum set JWT_KEY to a random 32+ character string

# Start core stack (5 services: ui, api, db, storage, backup)
docker compose up -d

# Optional: include the self-hosted AI assistant
docker compose --profile ai up -d

# Optional: include Coqui TTS for training video narration
docker compose --profile tts up -d

# Optional: include DocuSeal for employee document e-signatures
docker compose --profile signing up -d

# All optional profiles at once
docker compose --profile ai --profile tts --profile signing up -d
```

The application will be available at `http://localhost:4200`.

### First-Run Setup

A 2-step setup wizard runs automatically on first access:

1. **Step 1 — Admin account** — set your admin email and password
2. **Step 2 — Company details** — enter your company name, EIN, and primary location

After setup:
- Navigate to **Admin > Settings** to configure branding, colors, and integrations
- Navigate to **Admin > QB Setup** to connect QuickBooks Online (or skip for standalone mode)
- Create users, assign roles, and configure track types

The built-in guided tours walk through each major feature on first visit.

---

## Demo / Development Mode

Run with realistic seed data and no external dependencies:

```bash
# In .env (or as environment variable):
MOCK_INTEGRATIONS=false   # already the default; set to true to bypass QB/SMTP
RECREATE_DB=true          # drops and recreates the DB on each API start (dev only)
```

The seed data includes:
- Sample jobs across all track types (Production, R&D, Maintenance)
- Parts with recursive BOMs and process steps
- Customers, vendors, leads, expenses, assets
- 46 training modules across 8 learning paths
- 27 pre-seeded report templates
- Reference data, system settings, and a default admin user (`admin@qbengineer.local` / `Admin123!`)

With `MOCK_INTEGRATIONS=true`:
- QB API calls return canned fixture data
- Email notifications log to console instead of sending
- Address validation uses format-only checks (no USPS API call)
- AI responses are canned strings (no Ollama required)

---

## Development Setup

### Prerequisites

- [.NET 9 SDK](https://dotnet.microsoft.com/download/dotnet/9.0)
- [Node.js 22 LTS](https://nodejs.org/) + npm
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (for Postgres + MinIO)

### Hot-Reload Dev Stack

The `docker-compose.dev.yml` overlay enables hot reload for both UI and API:

```bash
# .env already has:
COMPOSE_FILE=docker-compose.yml;docker-compose.dev.yml

# Starts full stack with hot reload
docker compose up -d

# API: dotnet watch (hot reload)
# UI: ng serve with file polling
```

### Running Tests

```bash
# Angular unit tests (Vitest)
cd qb-engineer-ui && npx vitest

# .NET unit tests (xUnit)
cd qb-engineer-server && dotnet test qb-engineer.tests/

# Playwright E2E (requires full stack running)
cd qb-engineer-ui && npm run e2e

# Playwright headed (for debugging)
cd qb-engineer-ui && npm run e2e:headed
```

---

## Project Structure

```
qb-engineer-wrapper/
├── qb-engineer-server/          .NET 9 solution
│   ├── qb-engineer.api/         Controllers, Features/ (MediatR handlers), Middleware
│   ├── qb-engineer.core/        Entities, Interfaces, Models, Enums
│   ├── qb-engineer.data/        DbContext, Repositories, Migrations, EF Config
│   ├── qb-engineer.integrations/ QB, MinIO, SMTP, Ollama, Coqui TTS, Playwright, DocuSeal
│   └── qb-engineer.tests/       xUnit unit + integration tests (Bogus test data)
├── qb-engineer-ui/              Angular 21 application
│   ├── src/
│   │   ├── app/
│   │   │   ├── shared/          Reusable components, services, directives, pipes
│   │   │   ├── features/        Lazy-loaded feature modules
│   │   │   └── core/            Singleton services (layout, nav, auth)
│   │   └── styles/              Global SCSS (_variables, _mixins, _shared, _reset)
│   └── e2e/                     Playwright E2E specs and helpers
├── docs/                        Architecture, standards, and design documentation
│   └── training-videos/         Video manuscripts and regeneration specs (01–06)
├── docker-compose.yml           Production container orchestration
├── docker-compose.dev.yml       Development hot-reload overlay
└── .env                         Local environment configuration
```

---

## Deployment

### Raspberry Pi

QB Engineer runs on Raspberry Pi 4 or 5 (64-bit OS required, 4+ GB RAM). An automated setup script handles everything:

```bash
# On the Pi — clone and run
git clone https://github.com/danielhokanson/qb-engineer-wrapper.git
cd qb-engineer-wrapper
chmod +x setup-pi.sh
./setup-pi.sh
```

The script will:
- Check prerequisites (Git, Docker, Docker Compose, 64-bit ARM, RAM, disk)
- Give install instructions with copy-paste commands if anything is missing
- Create `.env` with a random JWT key and your Pi's network IP
- Apply Pi-tuned memory limits via `docker-compose.pi.yml`
- Build and start the core stack
- Print instructions for router port forwarding to make it publicly accessible

**To make the site publicly accessible:**
1. Forward port 80 on your router to the Pi's local IP (shown at end of setup)
2. Find your public IP: `curl -4 ifconfig.me`
3. Access from anywhere: `http://<your-public-ip>`
4. Add your public IP to `CORS_ORIGINS` in `.env`, then restart the API

**Hardware tips:**
- Use a USB 3.0 SSD instead of the SD card — dramatically improves Docker build times and database performance
- Skip AI and TTS profiles on 4 GB models
- 8 GB Pi 5 is the sweet spot for the full stack

### On-Premise (recommended)

```bash
# Pull the latest release images
docker compose pull

# Start all services
docker compose up -d

# Verify health
docker compose ps
curl http://localhost:5000/health
```

All configuration is via `.env` and environment variables. No hardcoded hostnames or paths.

### Backup

- **Off-site**: Backblaze B2 via scheduled `pg_dump` + `rclone sync` for MinIO files
- **On-site**: MinIO bucket replication + DB dumps to a secondary machine on LAN
- **Retention**: 7 daily, 4 weekly, 3 monthly snapshots
- Backup status visible in the admin system health panel

### Upgrade

```bash
docker compose pull
docker compose up -d   # migrations run automatically on API start

docker compose ps
curl http://localhost:5000/health
```

Database migrations run automatically on API startup. If a migration requires manual intervention, the release notes will specify the steps.

---

## Environment Variables

Key variables (full list in `.env.example`):

| Variable | Default | Description |
|---|---|---|
| `MOCK_INTEGRATIONS` | `false` | Replace all external APIs with mock implementations |
| `RECREATE_DB` | `false` | Drop and recreate the database on startup (dev only) |
| `JWT_KEY` | — | Secret for JWT signing (min 32 chars, **required**) |
| `JWT_ISSUER` | `qb-engineer` | JWT issuer claim |
| `JWT_AUDIENCE` | `qb-engineer-ui` | JWT audience claim |
| `POSTGRES_DB` | `qb_engineer` | PostgreSQL database name |
| `POSTGRES_USER` | `postgres` | PostgreSQL user |
| `POSTGRES_PASSWORD` | `postgres` | PostgreSQL password |
| `MINIO_ROOT_USER` | `minioadmin` | MinIO access key |
| `MINIO_ROOT_PASSWORD` | `minioadmin` | MinIO secret key |
| `MINIO_PUBLIC_ENDPOINT` | `localhost:9000` | Public MinIO URL for presigned links |
| `STORAGE_PROVIDER` | `minio` | Storage backend: `minio` or `local` |
| `FRONTEND_BASE_URL` | `http://localhost:4200` | Public frontend URL (used in emails, webhooks) |
| `TTS_API_KEY` | — | OpenAI TTS API key (optional; Coqui used if unset) |
| `COQUI_BASE_URL` | — | Coqui TTS server URL, e.g. `http://qb-engineer-tts:5002` |
| `COQUI_SPEAKER_ID` | — | VCTK speaker ID, e.g. `p228` |
| `OLLAMA_BASE_URL` | `http://qb-engineer-ai:11434` | Ollama API endpoint |
| `DOCUSEAL_API_KEY` | — | DocuSeal API key for e-signature workflows |
| `SMTP_HOST` | — | SMTP server for email notifications |
| `SMTP_PORT` | `587` | SMTP port |
| `SMTP_USERNAME` | — | SMTP credentials |
| `SMTP_PASSWORD` | — | SMTP credentials |
| `BACKUP_B2_KEY_ID` | — | Backblaze B2 application key ID |
| `BACKUP_B2_APP_KEY` | — | Backblaze B2 application key |
| `BACKUP_B2_BUCKET` | — | Backblaze B2 bucket name |
| `CORS_ORIGINS` | `http://localhost:4200` | Allowed CORS origins (comma-separated) |
| `USPS_CONSUMER_KEY` | — | USPS OAuth consumer key for address validation (optional) |
| `USPS_CONSUMER_SECRET` | — | USPS OAuth consumer secret for address validation (optional) |

---

## Documentation

| Document | Contents |
|---|---|
| [architecture.md](docs/architecture.md) | Tech stack, Docker topology, auth tiers, search, AI, backup |
| [coding-standards.md](docs/coding-standards.md) | Angular and .NET coding standards, accessibility, loading states, security |
| [functional-decisions.md](docs/functional-decisions.md) | Feature-level design decisions (Kanban, order management, standalone financials) |
| [roles-auth.md](docs/roles-auth.md) | Role definitions, tiered authentication (RFID/kiosk/SSO), permission matrix |
| [ui-components.md](docs/ui-components.md) | Shared component catalog with usage examples |
| [qb-integration.md](docs/qb-integration.md) | Accounting boundary, sync queue, OAuth, caching, orphan detection |
| [ai-system.md](docs/ai-system.md) | Ollama RAG pipeline, pgvector, document indexing, configurable assistants |
| [pdf-extraction-pipeline.md](docs/pdf-extraction-pipeline.md) | PDF form extraction (pdf.js + PuppeteerSharp), form definition builder |
| [libraries.md](docs/libraries.md) | Complete third-party library reference |
| [implementation-status.md](docs/implementation-status.md) | Feature completion tracker (master TODO list) |
| [training-videos/](docs/training-videos/) | Video manuscripts and Playwright regeneration specs for all 6 training videos |

---

## Roadmap

The original phase plan is complete. Remaining known gaps:

| Item | Status | Notes |
|---|---|---|
| Xero / FreshBooks / Sage | Not started | Interface + factory ready; only QB implemented |
| QB Payroll API sync | Stub only | Controller + entities done; QB Payroll write-back not yet implemented |
| UPS / FedEx / USPS / DHL carrier APIs | Mock only | `IShippingService` implemented; direct carrier integrations not built |
| Kubernetes Helm chart | Not started | Docker Compose is the supported deployment target |

Feature requests welcome via GitHub Issues.

---

## Customizing Your Theme

### Option 1: Admin UI (runtime, no rebuild)

1. Navigate to **Admin > Settings > Theming**
2. Pick your Primary, Accent, and Warn colors
3. The UI validates contrast against WCAG 2.2 AA thresholds before saving
4. Upload your logo and set your app name
5. Changes apply immediately to all users

### Option 2: SCSS variables (requires rebuild)

1. Edit `qb-engineer-ui/src/styles/_variables.scss` to change spacing, typography, or design tokens
2. Rebuild: `docker compose build qb-engineer-ui && docker compose up -d qb-engineer-ui`

Users can switch between light and dark themes via the toolbar toggle.

---

## Troubleshooting

**"Permission denied" connecting to Docker daemon (Linux):**
- Your user must be in the `docker` group: `sudo usermod -aG docker $USER`
- **Log out and back in** (or run `newgrp docker`) for the group change to take effect
- Verify with: `docker ps`

**Containers fail to start:**
- Check logs: `docker compose logs <service-name>`
- Ensure ports 4200, 5000, 5432, 9000 are not in use
- On Windows/macOS: ensure Docker Desktop has at least 4 GB RAM allocated

**Database issues:**
- Check health: `docker compose ps`
- View migration output: `docker compose logs qb-engineer-api | grep -i migration`
- Reset (destroys all data): `docker compose down -v && docker compose up -d`

**QB connection issues:**
- Verify OAuth tokens in Admin > Integrations > QuickBooks
- Check token expiry in the system health panel
- With `MOCK_INTEGRATIONS=true` QB issues are bypassed entirely

**File upload failures:**
- Check MinIO: `docker compose ps qb-engineer-storage`
- Verify `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` in `.env` match container config
- Check host disk space

**Training video generation:**
- Requires Coqui TTS profile: `docker compose --profile tts up -d`
- First start downloads the VCTK model (~500 MB); wait for `Serving Flask app` in logs
- Videos are generated one at a time (single-worker Hangfire `video` queue) to avoid OOM
- Check progress: `docker compose logs qb-engineer-api | grep VideoGen`

**AI module not responding:**
- Ollama downloads models on first run (several minutes)
- Check: `docker compose logs qb-engineer-ai`
- Test: `curl http://localhost:11434/api/tags`
- The app works fully without AI — features fall back gracefully

**Slow performance:**
- Check resource usage: `docker stats`
- AI inference is CPU-bound without a GPU
- For large deployments, configure Postgres connection pooling

---

## Security

### Reporting Vulnerabilities

If you discover a security vulnerability, **do not open a public issue.** Email security@qb-engineer.dev with a description, reproduction steps, and potential impact. We will acknowledge within 48 hours.

### Security Practices

- JWT access tokens + refresh token rotation; tokens short-lived (configurable)
- QB OAuth tokens encrypted at rest via ASP.NET Data Protection API (AES-256, keys in Postgres)
- Tiered kiosk authentication: RFID/NFC/barcode + separate PIN (PBKDF2 hashed)
- All API endpoints require authentication; shop floor display endpoint is read-only
- Rate limiting on authentication endpoints
- Input validation via FluentValidation on all requests
- CORS restricted to configured origins
- No secrets in source code — all credentials via environment variables
- Soft delete — records are never permanently removed without admin action
- Audit log captures all create/update/delete operations with user and timestamp
- CSP headers: `default-src 'self'`, no eval, `frame-ancestors 'none'`
- HSTS enforced in production

---

## Standalone Mode (No Accounting System)

QB Engineer is fully functional without a connected accounting system. In standalone mode:

- All operations features work normally (Kanban, parts, inventory, purchasing, planning, QC, time, expenses, HR, training, chat, notifications)
- Financial features (invoices, payments, AR aging, customer statements) are available locally instead of syncing to an external accounting system
- Vendor management operates in full CRUD mode (becomes read-only when an accounting provider is connected)
- Customer records are managed locally
- Skip the QB Setup step during first-run wizard

---

## Contributing

QB Engineer is open source under the GNU General Public License v3. Contributions are welcome.

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Follow the [coding standards](docs/coding-standards.md)
4. Write tests for new functionality
5. Ensure all tests pass (unit, integration, E2E)
6. Submit a pull request against `main`

**Rules:**
- No company-specific code — everything must be configurable
- One logical change per PR
- New features need tests; UI changes need Playwright coverage for the critical path
- No new dependencies without a discussion issue first
- Accessibility is non-negotiable — WCAG 2.2 AA, enforced by ESLint and Playwright axe-core
- Branch naming: `feature/...`, `fix/...`, `chore/...`
- Commit messages: imperative mood, under 72 characters

**Adding a translation:**
Copy `qb-engineer-ui/public/assets/i18n/en.json` to your locale file (e.g., `fr.json`), translate the values (keys unchanged), and submit a PR.

---

## Acknowledgments

QB Engineer is built on these open-source projects (among many others):

- [Angular](https://angular.dev/) and [Angular Material](https://material.angular.io/)
- [.NET](https://dotnet.microsoft.com/) and [Entity Framework Core](https://learn.microsoft.com/ef/core/)
- [PostgreSQL](https://www.postgresql.org/) and [pgvector](https://github.com/pgvector/pgvector)
- [MinIO](https://min.io/)
- [Hangfire](https://www.hangfire.io/)
- [MediatR](https://github.com/jbogard/MediatR)
- [Three.js](https://threejs.org/)
- [Ollama](https://ollama.ai/)
- [Coqui TTS](https://github.com/coqui-ai/TTS)
- [PuppeteerSharp](https://www.puppeteersharp.com/)
- [QuestPDF](https://www.questpdf.com/)
- [DocuSeal](https://www.docuseal.com/)
- [driver.js](https://driverjs.com/)
- [Mapperly](https://mapperly.riok.app/)

Full library list: [docs/libraries.md](docs/libraries.md)

---

## License

GNU General Public License v3.0 — see [LICENSE](LICENSE) for the full text.

Free to use, modify, and distribute. All derivatives must also be open source under GPLv3.
