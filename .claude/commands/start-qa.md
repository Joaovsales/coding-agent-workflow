# /start-qa — Start QA Session

Restart the application, launch a browser for manual QA as fast as possible, and run health/smoke checks in the background.

---

## Step 1 — Discover the Project

Before doing anything, understand how this specific project works. Read the project's configuration files to determine:

1. **How to start the app** — Look for clues in this order:
   - `Makefile` / `makefile` (e.g., `make up`, `make dev`, `make start`)
   - `docker-compose.yml` / `compose.yml` (e.g., `docker compose up -d`)
   - `package.json` scripts (e.g., `npm run dev`, `npm start`)
   - `Procfile`, `pyproject.toml`, or framework-specific configs
   - `README.md` for documented startup instructions

2. **How to stop/restart the app** — Corresponding stop commands (e.g., `make down`, `docker compose down`, kill existing dev server process)

3. **What URL the app runs on** — Check for port configuration in:
   - Docker compose port mappings
   - Vite/webpack config (`vite.config.ts`, `webpack.config.js`)
   - `.env` files for `PORT` or `HOST` variables
   - Framework defaults (Vite: 5173, Next.js: 3000, FastAPI: 8000, Rails: 3000, etc.)

4. **How to health-check the app** — Look for:
   - Makefile targets like `pre-QA-tests`, `test-smoke`, `test-health`
   - Health endpoints (`/health`, `/api/health`, `/healthz`)
   - Smoke test scripts in `scripts/` or `tests/smoke/`

5. **What pre-QA tests exist** — Look for:
   - Makefile targets: `pre-QA-tests`, `test-smoke`, `test-critical`, `test-mvp`
   - Test directories: `tests/smoke/`, `tests/e2e/`, `tests/integration/`
   - Scripts: `scripts/pre_qa*.sh`, `scripts/smoke*.sh`

Store these findings — you'll use them in the following steps.

---

## Step 2 — Restart the Application

Using what you discovered in Step 1:

1. Stop the currently running app (if applicable)
2. Rebuild if the project uses a build step
3. Start the app in the background

Wait a few seconds for services to initialize, then do a quick liveness check (e.g., `curl -sf <url>` or check process/container status). If the app fails to start, inspect logs, fix the issue, and retry. Loop until the app is reachable.

---

## Step 3 — Launch Browser Immediately

As soon as the app is reachable (basic liveness confirmed), launch the browser **without waiting for full test suites**:

```
/chrome
```

Navigate to the app URL discovered in Step 1. The `/chrome` session captures **console logs** and **network requests** automatically.

**Report QA ready immediately:**

```
QA Session Ready
─────────────────────────────────────
App Status:    Running
Browser:       Launched at [URL]
Log Monitoring:
  - Console logs: Active
  - Network logs: Active

Background: Pre-QA smoke tests are running via /loop.
            You'll be notified of any failures.

You can start manual QA now.
─────────────────────────────────────
```

---

## Step 4 — Background Health & Smoke Tests via /loop

Immediately after launching the browser, start a background loop to run pre-QA validation:

```
/loop 2m Run pre-QA smoke tests for this project. If any test fails or infrastructure issue is detected: diagnose the root cause from logs, fix it, and re-run. Report to the user only when something fails or when all checks pass. Do not interrupt QA for passing tests.
```

The `/loop` handles:
- Running whatever smoke/health tests were discovered in Step 1
- Auto-fixing infrastructure issues (missing services, failed migrations, env misconfigs)
- Notifying the user only on failures or when all checks go green
- Re-running after fixes to confirm resolution

---

## During QA (Ongoing)

While the user performs manual QA:
- Keep the browser session and log monitoring active
- When the user reports an issue, immediately check captured console errors and failed network requests
- Correlate frontend errors with backend logs (use the project's log access method — `docker compose logs`, file logs, or terminal output)
- Suggest fixes or file bugs in `tasks/bugs.md` as issues are discovered
