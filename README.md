# QB Engineer

**Open source manufacturing operations platform — the operational layer that sits alongside your accounting system.**

QB Engineer is a locally hosted web application for small and mid-size manufacturers. Your accounting system (QuickBooks Online by default, with pluggable support for Xero, Sage, and others) handles the finances. QB Engineer handles everything else: job tracking, production workflow, R&D iterations, CAD/STL file management, sprint-based work planning, lead management, production traceability, and an engineer-focused dashboard. Works in standalone mode without any accounting system too.

No SaaS fees. No cloud dependency. Runs entirely in Docker on your own infrastructure.

---

## Why QB Engineer?

Accounting systems think in financial primitives (debits, credits, chart of accounts). Manufacturers think in shop primitives (jobs, materials, machines, deadlines). QB Engineer bridges that gap:

- **Kanban board** with configurable track types (Production, R&D, Maintenance, custom) aligned to your accounting document lifecycle
- **Sprint-based planning** with 2-week cycles, backlog curation, and Planning Day guided flow
- **Part catalog** with recursive BOM, revision control, and inline STL 3D viewing
- **Production traceability** supporting FDA 21 CFR Part 820 / ISO 13485 when needed
- **Lead management** with conversion to accounting system customers
- **Time tracking** that feeds directly into your accounting system's payroll
- **File management** with versioned CAD/STL/CAM attachments stored in MinIO
- **Shop floor display** for real-time production visibility on kiosk screens
- **Self-hosted AI assistant** (optional) for smart search, document Q&A, and QC anomaly detection

All accounting integration goes through a sync queue — the app works normally when your accounting system is unavailable, or with no accounting system at all.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Angular 21 + Angular Material |
| Backend | .NET 9 Web API |
| Database | PostgreSQL + pgvector |
| File Storage | MinIO (S3-compatible) |
| Real-time | SignalR |
| Background Jobs | Hangfire |
| 3D Viewer | Three.js |
| AI (optional) | Ollama + pgvector RAG |
| Containerization | Docker Compose |

See [docs/libraries.md](docs/libraries.md) for the complete library reference.

---

## System Requirements

### Minimum (without AI)

- Docker Engine 24+ and Docker Compose v2
- 4 GB RAM
- 20 GB disk (grows with file storage)
- Any x86_64 Linux, Windows, or macOS host

### Recommended (with AI module)

- 16 GB RAM (CPU-only AI inference)
- 16+ GB VRAM GPU for responsive AI (NVIDIA recommended, with nvidia-container-toolkit)
- 50 GB disk

### Browser Support

- Chrome, Edge, Firefox, Safari (latest 2 versions)
- Responsive down to 768px viewport width

---

## Quick Start

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) or Docker Engine + Compose
- [Git](https://git-scm.com/)

### Run with Docker Compose

```bash
git clone https://github.com/your-org/qb-engineer.git
cd qb-engineer

# Copy environment template and configure
cp .env.example .env
# Edit .env with your settings (SMTP, backup targets, etc.)

# Start all containers (6 core services)
docker compose up -d

# Or include the optional AI module
docker compose --profile ai up -d
```

The application will be available at `http://localhost:4200`.

**Default admin credentials** are printed to the API container logs on first run. You will be prompted to change the password on first login.

### First-Run Setup

1. Log in with the default admin credentials
2. Navigate to Admin > Settings to configure your app name, logo, and brand colors
3. Navigate to Admin > QB Setup to connect your QuickBooks Online account (or skip for standalone mode)
4. Create users and assign roles
5. The built-in guided tour walks through the rest

---

## Demo Mode

Run the full application with mock data and no external dependencies:

```bash
# Start with mock integrations (no QB account needed)
MOCK_INTEGRATIONS=true docker compose up -d
```

Mock mode provides:
- Fake QB customers, vendors, items, and employees from JSON fixtures
- Simulated QB API responses (success, auth failure, rate limit scenarios)
- Email notifications logged to console instead of sent via SMTP
- Canned AI responses (if AI module is enabled)
- Seed data: sample jobs across all track types, parts with BOMs, leads, assets, and expenses

This is the recommended way to evaluate the application before connecting real services.

---

## Development Setup

### Prerequisites

- [.NET 9 SDK](https://dotnet.microsoft.com/download/dotnet/9.0)
- [Node.js 22 LTS](https://nodejs.org/) + npm
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (for Postgres + MinIO)
- A code editor (VS Code or Rider recommended)

### Backend (.NET API)

```bash
cd qb-engineer.api

# Restore dependencies
dotnet restore

# Start infrastructure containers (Postgres + MinIO only)
docker compose -f docker-compose.dev.yml up -d

# Run database migrations
dotnet ef database update --project ../qb-engineer.data

# Start the API (with mock integrations enabled)
MOCK_INTEGRATIONS=true dotnet run
```

API runs at `https://localhost:5001` with Scalar API docs at `https://localhost:5001/scalar`.

### Frontend (Angular)

```bash
cd qb-engineer-ui

# Install dependencies
npm install

# Start dev server
ng serve
```

UI runs at `http://localhost:4200` and proxies API calls to the backend.

### Running Tests

```bash
# Angular unit tests
cd qb-engineer-ui && npx vitest

# .NET unit tests
cd qb-engineer.tests && dotnet test

# .NET integration tests (requires Postgres running)
cd qb-engineer.tests && dotnet test --filter Category=Integration

# Cypress E2E (requires full Docker Compose stack)
cd qb-engineer-ui && npx cypress run
```

### Build Scripts

```bash
# Local build (Linux/macOS/CI)
./scripts/build.sh

# Local build (Windows)
scripts\build.bat

# Print current version
./scripts/version.sh
```

Version is derived automatically from git tags. See [docs/coding-standards.md](docs/coding-standards.md) Standard #24 for details.

---

## Deployment

### On-Premise (recommended for most users)

```bash
# Pull the latest release images
docker compose pull

# Start all services
docker compose up -d

# Verify health
curl http://localhost:5001/health
```

All configuration is via environment variables in `.env` and `appsettings.json`. No hardcoded hostnames or paths.

### Cloud Deployment

The same Docker images run on any container host:

- **Docker Compose** on a VM (simplest)
- **Kubernetes** with Helm chart (coming soon)
- **Azure Container Apps**, **AWS ECS**, **Google Cloud Run**

Swap MinIO for any S3-compatible provider. Swap Postgres for a managed database service (Azure Database for PostgreSQL, AWS RDS, etc.). No code changes required — only configuration.

### Backup

- **Off-site**: Backblaze B2 via scheduled `pg_dump` + `rclone sync` for MinIO files
- **On-site**: MinIO bucket replication + DB dumps to a secondary machine on LAN
- **Retention**: 7 daily, 4 weekly, 3 monthly
- Backup status visible in the admin system health panel

### Upgrade

```bash
# Pull latest images
docker compose pull

# Apply database migrations (automatic on API container start)
docker compose up -d

# Verify
docker compose ps
curl http://localhost:5001/health
```

Database migrations run automatically on API startup. If a migration requires manual intervention, the release notes will specify the steps.

**Version pinning:** To pin a specific version instead of `latest`, set the image tags in `docker-compose.yml` or your `.env` file:

```
QB_ENGINEER_VERSION=1.2.3
```

---

## Environment Variables

Key variables in `.env` (full list in `.env.example`):

| Variable | Default | Description |
|---|---|---|
| `MOCK_INTEGRATIONS` | `false` | Swap all external services for mock implementations |
| `POSTGRES_CONNECTION` | — | PostgreSQL connection string |
| `MINIO_ENDPOINT` | `minio:9000` | MinIO server address |
| `MINIO_ACCESS_KEY` | — | MinIO access key |
| `MINIO_SECRET_KEY` | — | MinIO secret key |
| `JWT_SIGNING_KEY` | — | Secret key for JWT token signing (min 32 chars) |
| `JWT_EXPIRATION_MINUTES` | `60` | Access token lifetime |
| `SMTP_HOST` | — | SMTP server for email notifications |
| `SMTP_PORT` | `587` | SMTP port |
| `SMTP_USERNAME` | — | SMTP credentials |
| `SMTP_PASSWORD` | — | SMTP credentials |
| `BACKUP_B2_KEY_ID` | — | Backblaze B2 application key ID |
| `BACKUP_B2_APP_KEY` | — | Backblaze B2 application key |
| `BACKUP_B2_BUCKET` | — | Backblaze B2 bucket name |
| `OLLAMA_BASE_URL` | `http://qb-engineer-ai:11434` | Ollama API endpoint (AI module) |
| `CORS_ORIGINS` | `http://localhost:4200` | Allowed CORS origins (comma-separated) |
| `DEV_MODE` | `false` | Enable developer tooling (tour sync overlay, verbose logging) |

---

## Customizing Your Theme

### Option 1: Admin UI (runtime, no rebuild)

1. Navigate to **Admin > Settings > Theming**
2. Pick your **Primary**, **Accent**, and **Warn** colors using the color pickers
3. The UI validates contrast against WCAG 3 accessibility thresholds and warns you before saving inaccessible combinations
4. Upload your logo and set your app name on the same screen
5. Changes apply immediately to all users

### Option 2: Code-level (deeper customization, requires rebuild)

1. Edit `qb-engineer-ui/src/styles/_variables.scss` to change the spacing scale, typography, border radius, or other design tokens
2. Rebuild the UI container: `docker compose build qb-engineer-ui`
3. Restart: `docker compose up -d qb-engineer-ui`

Users can switch between light and dark themes via the toggle in the toolbar. Both themes are auto-generated from the admin-set color palette.

---

## Project Structure

```
qb-engineer/
  qb-engineer.sln                    .NET solution file
  qb-engineer.api/                   .NET 9 Web API (controllers, middleware)
  qb-engineer.core/                  Domain models, interfaces, enums
  qb-engineer.data/                  EF Core DbContext, migrations, configurations
  qb-engineer.integrations/          QB, Email, Storage, Backup, AI service layers
  qb-engineer.tests/                 xUnit tests (unit + integration)
  qb-engineer-ui/                    Angular 21 application
    src/app/
      shared/                        Reusable components, services, pipes, models
      features/                      Lazy-loaded domain modules (kanban, dashboard, etc.)
      core/                          Singleton services, layout shell
    src/styles/                      Global SCSS (_variables, _mixins, theme)
    cypress/                         E2E test specs
  scripts/                           Build and versioning scripts
  docs/                              Architecture, standards, and design documentation
  docker-compose.yml                 Production container orchestration
  docker-compose.dev.yml             Development infrastructure only
  .github/workflows/                 CI/CD pipeline definitions
```

---

## Documentation

All design and reference documentation lives in the [docs/](docs/) directory:

| Document | Contents |
|---|---|
| [architecture.md](docs/architecture.md) | Tech stack, Docker topology, auth, search, AI, routing |
| [coding-standards.md](docs/coding-standards.md) | 31 coding standards (Angular, .NET, database, CI/CD, accessibility, print, loading, security) |
| [libraries.md](docs/libraries.md) | Complete third-party library reference with packages and justifications |
| [functional-decisions.md](docs/functional-decisions.md) | Feature-level decisions (Kanban, sprints, leads, notifications, etc.) |
| [proposal.md](docs/proposal.md) | Full project proposal with module descriptions and phased delivery plan |
| [kickoff-prompt.md](docs/kickoff-prompt.md) | Developer onboarding guide with schema, conventions, and Phase 1 scope |

---

## Troubleshooting

**Containers fail to start:**
- Run `docker compose logs <service-name>` to check for errors
- Ensure ports 4200, 5001, 5432, 9000 are not in use by other services
- On Windows/macOS, ensure Docker Desktop has sufficient memory allocated (4 GB minimum)

**Database migration errors:**
- Check that `qb-engineer-db` is healthy: `docker compose ps`
- View migration logs: `docker compose logs qb-engineer-api | grep -i migration`
- To reset the database (destroys all data): `docker compose down -v && docker compose up -d`

**QB connection issues:**
- Verify OAuth tokens in Admin > QB Setup
- Check token expiry in the system health panel
- QB API rate limits: the sync queue handles retries with backoff automatically
- With `MOCK_INTEGRATIONS=true`, QB issues are bypassed entirely

**File upload failures:**
- Check MinIO is running: `docker compose ps qb-engineer-storage`
- Verify MinIO credentials in `.env` match the container configuration
- Check disk space on the Docker host

**AI module not responding:**
- Ollama needs to download models on first run (can take several minutes)
- Check: `docker compose logs qb-engineer-ai`
- Test directly: `curl http://localhost:11434/api/tags`
- The app works fully without AI — features fall back to manual workflows

**Slow performance:**
- Enable Postgres connection pooling if running many concurrent users
- Check `docker stats` for container resource usage
- For large file uploads, ensure MinIO has sufficient disk I/O
- AI inference is CPU-bound without a GPU — consider a GPU for production AI use

---

## Security

### Reporting Vulnerabilities

If you discover a security vulnerability, **do not open a public issue.** Instead, email security@qb-engineer.dev (or the address specified in `SECURITY.md`) with:

- Description of the vulnerability
- Steps to reproduce
- Potential impact

We will acknowledge receipt within 48 hours and provide a timeline for a fix.

### Security Practices

- JWT bearer tokens with refresh token rotation
- QB OAuth tokens encrypted at rest via ASP.NET Data Protection API (AES-256, keys in Postgres)
- All API endpoints require authentication (except `/display/shop-floor` which is read-only on trusted LAN)
- Rate limiting on authentication endpoints
- Input validation via FluentValidation on all API requests
- CORS restricted to configured origins
- No secrets in source code — all credentials via environment variables
- Soft delete ensures data is never permanently lost without admin action
- Content Security Policy (CSP) headers — no inline scripts, `frame-ancestors 'none'`, strict resource origins
- HSTS enforced in production (HTTPS)
- Audit log captures all create/update/delete operations with user and timestamp

---

## Roadmap

Development follows the phased plan in [docs/proposal.md](docs/proposal.md):

| Phase | Status | Scope |
|---|---|---|
| 1 — Foundation | In Progress | Docker, schema, auth, Kanban board, job cards, file attachments, STL viewer |
| 2 — Engineer UX | Planned | Dashboard, sprint planning, daily priorities |
| 3 — QB Bridge | Planned | Full QB read/write, sync queue, OAuth flow |
| 4 — Leads & Contacts | Planned | Lead pipeline, conversion, contacts |
| 5 — Traceability | Planned | Production runs, QC checklists, lot tracking |
| 6 — Time & Workers | Planned | Timer, worker views, shop floor display |
| 7 — Expenses & Invoicing | Planned | Expense capture, invoice workflow |
| 8 — Maintenance | Planned | Asset registry, scheduled maintenance |
| 9 — Reporting | Planned | Operational dashboards, charts, CSV export |
| 10 — Backup & Polish | Planned | B2 backup, email notifications, mobile layouts |
| 11 — AI Assistant | Planned | Ollama, RAG pipeline, smart search, document Q&A |

Feature requests and phase feedback welcome via GitHub Issues.

---

## Contributing

QB Engineer is open source under the GNU General Public License v3. Contributions are welcome.

### Getting Started

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes following the [coding standards](docs/coding-standards.md)
4. Write tests for new functionality
5. Ensure all tests pass: unit, integration, and E2E
6. Submit a pull request against `main`

### Contribution Rules

- **Follow the coding standards.** All 31 standards in [docs/coding-standards.md](docs/coding-standards.md) are enforced. CI will reject non-conforming code.
- **No company-specific code.** Everything must be configurable. No hardcoded company names, logos, branding, or workflow assumptions.
- **One logical change per PR.** Keep PRs focused — one feature, one fix, or one refactor.
- **Tests required.** New features need unit tests. Bug fixes need a regression test. UI changes need Cypress coverage for the critical path.
- **No new dependencies without discussion.** Open an issue first to discuss adding a new library. Prefer libraries that are MIT/Apache licensed, actively maintained, and tree-shakeable.
- **Accessibility is not optional.** All UI changes must meet WCAG 3 targets. The CI pipeline runs axe-core checks.
- **Write plain language.** No accounting jargon in operational views. Comments and commit messages should be clear to a non-expert.
- **Branch naming:** `feature/...`, `fix/...`, `chore/...`
- **Commit messages:** imperative mood, under 72 characters

### Reporting Issues

Open an issue with:
- Steps to reproduce
- Expected vs. actual behavior
- Browser/OS/Docker version
- Screenshots or logs if applicable

### Adding a Language Translation

1. Copy `qb-engineer-ui/src/assets/i18n/en.json` to your locale file (e.g., `fr.json`)
2. Translate all values (keys must remain unchanged)
3. Submit a PR — no code changes needed beyond the JSON file

---

## Standalone Mode (No QuickBooks)

QB Engineer works without a QuickBooks connection. In standalone mode:

- Job tracking, Kanban, sprints, files, parts, leads, assets, and traceability all function normally
- Financial features (estimates, invoices, payments, time activity sync) are simply unavailable
- Customer records are managed locally instead of syncing from QB
- Expense tracking works locally without QB write-back
- Skip the QB Setup wizard during first-run configuration

This makes QB Engineer useful for any small manufacturer, even those not using QuickBooks.

---

## Acknowledgments

QB Engineer is built on these open-source projects (among others):

- [Angular](https://angular.dev/) and [Angular Material](https://material.angular.io/)
- [.NET](https://dotnet.microsoft.com/) and [Entity Framework Core](https://learn.microsoft.com/ef/core/)
- [PostgreSQL](https://www.postgresql.org/) and [pgvector](https://github.com/pgvector/pgvector)
- [MinIO](https://min.io/)
- [Three.js](https://threejs.org/)
- [Ollama](https://ollama.ai/)
- [Hangfire](https://www.hangfire.io/)
- [MediatR](https://github.com/jbogard/MediatR)
- [Mapperly](https://mapperly.riok.app/)
- [driver.js](https://driverjs.com/)

Full library list: [docs/libraries.md](docs/libraries.md)

---

## License

GNU General Public License v3.0 — see [LICENSE](LICENSE) for the full text.

Free to use, modify, and distribute. All derivatives must also be open source under GPLv3.
