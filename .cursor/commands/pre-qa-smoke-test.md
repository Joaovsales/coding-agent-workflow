# Rule: Pre-QA Smoke Test

## Goal
Run infrastructure validation smoke tests before manual QA to catch deployment and connectivity issues early.

## Process
Before starting manual QA testing, run:

```bash
# Windows (PowerShell)
bash scripts/pre_qa_smoke_test.sh

# Linux/Mac
make pre-QA-tests
```

## What It Validates
1. **Docker Containers:** All required services running (backend, frontend, redis, arq_worker)
2. **Backend Health:** Health endpoint accessible and services healthy
3. **Redis Connectivity:** Both backend and ARQ worker can connect to Redis
4. **Docker Network:** Services are on correct Docker network (catches network misconfiguration)
5. **Frontend:** Web app accessible at http://localhost:5173
6. **Database:** Supabase connectivity validated
7. **Infrastructure Tests:** Automated integration tests pass

## Why This Matters
This smoke test **would have caught the Redis networking bug** where ARQ worker couldn't connect to Redis due to being on the wrong Docker network. It prevents infrastructure issues from reaching manual QA.

## When Tests Fail
If smoke tests fail:
1. Check Docker status: `docker compose --env-file .env ps`
2. View logs: `docker compose --env-file .env logs`
3. Restart services: `docker compose --env-file .env down && docker compose --env-file .env up -d`
4. Re-run smoke tests

## Integration with Testing
- Run **before** manual QA sessions
- Run **after** `docker compose up` or restarts
- Include in **CI/CD pipeline** before deployments
- Part of **regression testing** suite

