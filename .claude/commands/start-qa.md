# /start-qa — Start QA Session

Restart the application, validate infrastructure health, launch a browser with log monitoring, and hand off to the user for manual QA.

---

## Step 1 — Restart the Application

Bring the app down and back up cleanly:

```bash
make down
make build
make up
```

Wait 5 seconds for services to initialize, then verify containers are running:

```bash
docker compose ps
```

**If containers are not running or exited with errors**: inspect logs with `docker compose logs --tail=50`, diagnose the issue, fix it, and re-run `make down && make up`. Loop until all containers are healthy.

---

## Step 2 — Health Check Loop

Run the pre-QA smoke tests to validate infrastructure:

```bash
make pre-QA-tests
```

If `pre-QA-tests` is not available or the smoke test script does not exist, fall back to a manual health check:

1. Identify the backend health endpoint (commonly `GET /health` or `GET /api/health`)
2. Run: `curl -sf http://localhost:8000/health` (adjust port from docker-compose config)
3. Verify HTTP 200 response

**If health check fails**:
1. Read the error output and container logs (`docker compose logs --tail=100`)
2. Identify the root cause (missing env vars, DB connection issues, port conflicts, dependency errors)
3. Fix the issue directly — edit config files, restart specific services, run migrations, etc.
4. Re-run the health check
5. **Loop until the health check passes** — do not proceed to Step 3 until the app is confirmed healthy

Report each fix applied so the user has visibility into what was wrong.

---

## Step 3 — Launch Browser with Log Monitoring

Start a Chrome browser session using Playwright's CDP (Chrome DevTools Protocol) to capture both **console logs** and **network requests** in real time.

Use the MCP browser tool or Playwright to:

1. Launch a Chromium browser instance pointing to the app (e.g., `http://localhost:5173` for Vite frontend, or the appropriate URL from docker-compose)
2. Enable **Console log capture** — listen for all console messages (log, warn, error, info)
3. Enable **Network log capture** — listen for all HTTP requests and responses (URL, method, status code, timing)
4. Store logs in memory so they can be referenced during QA

If Playwright/browser MCP is not available, fall back to:
```bash
google-chrome --auto-open-devtools-for-tabs http://localhost:5173 &
```
And instruct the user to keep the DevTools Console and Network tabs open.

---

## Step 4 — Report QA Ready

Once all steps succeed, report to the user:

```
QA Session Ready
─────────────────────────────────────
App Status:    Running (all containers healthy)
Health Check:  PASS
Browser:       Launched at [URL]
Log Monitoring:
  - Console logs: Active (capturing log/warn/error/info)
  - Network logs: Active (capturing all HTTP requests/responses)

Issues Fixed During Startup: [list any fixes applied, or "None"]

You can now begin manual QA. I'm monitoring console and network
logs — if you hit an issue, I can inspect the captured logs to
help debug.
─────────────────────────────────────
```

---

## During QA (Ongoing)

While the user performs manual QA:
- Keep the browser session and log monitoring active
- When the user reports an issue, immediately check captured console errors and failed network requests
- Correlate frontend errors with backend logs (`docker compose logs --tail=50 backend`)
- Suggest fixes or file bugs in `tasks/bugs.md` as issues are discovered
