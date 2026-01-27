ENV_FILE:=.env
compose = docker compose --env-file $(ENV_FILE)

.PHONY: up down build run shell pre-QA-tests
up:    ; $(compose) up -d
down:  ; $(compose) down
build: ; $(compose) build
run:   ; $(compose) run $(ARGS)   # usage: make run ARGS="--rm backend sh -lc 'env | head'"
shell: ; $(compose) run --rm backend sh

# Pre-QA Infrastructure Validation (runs before manual QA)
pre-QA-tests:
	@echo "🔍 Running pre-QA smoke tests..."
	@bash scripts/pre_qa_smoke_test.sh

# Test helpers (always use test env file)
.PHONY: test test-health test-file test-fast test-unit test-integration test-e2e test-ui test-ui-headed test-ui-debug test-ui-screenshot test-mvp test-pdf test-api test-pre-commit test-smoke test-regression test-critical test-workflows test-db test-frontend test-frontend-integration test-user-workflows test-performance test-bundle install-hooks
TEST_ENV_FILE:=.env.test
compose_test = docker compose -f docker-compose.test.yml --env-file $(TEST_ENV_FILE)

test: ; $(compose_test) run --rm test
test-health: ; $(compose_test) run --rm test sh -lc "pytest -q src/backend/tests/api/test_health.py"
test-file: ; $(compose_test) run --rm test sh -lc "pytest -q $(FILE)"   # usage: make test-file FILE=src/backend/tests/api/test_health.py
test-fast: ; $(compose_test) run --rm test sh -lc "pytest src/backend/tests -q -k 'not integration and not e2e'"
test-unit: ; $(compose_test) run --rm test sh -lc "pytest -q src/backend/tests src/frontend --maxfail=1"
test-integration: ; $(compose_test) run --rm test sh -lc "pytest -q -m integration"
test-e2e: ; $(compose_test) run --rm test sh -lc "pytest -q -m e2e tests/e2e || true"

# UI/Playwright testing with full containerized stack
test-ui: ; $(compose_test) run --rm playwright
test-ui-headed: ; $(compose_test) run --rm playwright sh -lc "pytest -m playwright --headed -v"
test-ui-debug: ; $(compose_test) run --rm playwright sh -lc "pytest -m playwright --headed --pdb -s -v"
test-ui-screenshot: ; $(compose_test) run --rm playwright sh -lc "pytest -m playwright --screenshot=on -v"
test-ui-record: ; $(compose_test) run --rm playwright sh -lc "pytest -m playwright --video=on -v"

# MVP-focused smoke tests (fast, essential checks only)
test-mvp: ; $(compose_test) run --rm test sh -lc "python -m py_compile src/backend/main.py && pytest -q src/backend/tests/api/test_health.py"

# PDF Processing Test Suite
test-pdf: ; python scripts/run_pdf_tests.py
test-api: ; python -m pytest src/backend/tests/integration/test_api_endpoints.py -v
test-pre-commit: ; python scripts/pre-commit-tests.py

# Style Guide Test Suite (Database Persistence Tests)
.PHONY: test-style-guides test-style-persistence test-style-api test-style-schema test-style-e2e test-style-all
test-style-guides: test-style-all
test-style-persistence:
	@echo "🎨 Running style guide persistence tests..."
	$(compose_test) run --rm test sh -lc "pytest tests/integration/test_style_guide_persistence.py -v --tb=short"

test-style-api:
	@echo "🎨 Running style guide API integration tests..."
	$(compose_test) run --rm test sh -lc "pytest tests/integration/test_style_guide_api_integration.py -v --tb=short"

test-style-schema:
	@echo "🎨 Running style guide schema validation tests..."
	$(compose_test) run --rm test sh -lc "pytest tests/integration/test_style_guide_schema_migrations.py -v --tb=short"

test-style-e2e:
	@echo "🎨 Running style guide E2E tests..."
	pytest tests/e2e/test_style_guide_workflow.py -v --tb=short

test-style-all:
	@echo "🎨 Running complete style guide test suite..."
	@echo "   1/4: Persistence tests"
	@$(compose_test) run --rm test sh -lc "pytest tests/integration/test_style_guide_persistence.py -v --tb=short" || TEST_FAILED=1
	@echo ""
	@echo "   2/4: API integration tests"
	@$(compose_test) run --rm test sh -lc "pytest tests/integration/test_style_guide_api_integration.py -v --tb=short" || TEST_FAILED=1
	@echo ""
	@echo "   3/4: Schema validation tests"
	@$(compose_test) run --rm test sh -lc "pytest tests/integration/test_style_guide_schema_migrations.py -v --tb=short" || TEST_FAILED=1
	@echo ""
	@echo "   4/4: E2E workflow tests"
	@pytest tests/e2e/test_style_guide_workflow.py -v --tb=short || TEST_FAILED=1
	@echo ""
	@if [ "$$TEST_FAILED" = "1" ]; then \
		echo "❌ Some style guide tests failed"; \
		exit 1; \
	else \
		echo "✅ All style guide tests passed!"; \
	fi

# Regression Testing Targets
# Run smoke tests (pre-push validation)
test-smoke:
	@echo "🧪 Running smoke tests..."
	$(compose_test) run --rm test \
		pytest tests/smoke/ -v --tb=short --timeout=300

# Run full regression test suite
test-regression:
	@echo "🔍 Running comprehensive regression tests..."
	$(compose_test) run --rm test \
		pytest tests/regression/ -v --tb=short --timeout=600

# Run critical workflow tests only
test-critical:
	@echo "⚡ Running critical workflow tests..."
	$(compose_test) run --rm test \
		pytest tests/smoke/test_critical_apis.py -v --tb=short --timeout=90

# Run workflow tests
test-workflows:
	@echo "🔄 Running workflow tests..."
	$(compose_test) run --rm test \
		pytest tests/smoke/test_lightweight_workflows.py -v --tb=short --timeout=120

# Run database state tests
test-db:
	@echo "🗄️ Running database state tests..."
	$(compose_test) run --rm test \
		pytest tests/smoke/test_database_state.py -v --tb=short --timeout=60

# Combined fast validation (for CI)
test-fast-regression: test-smoke
	@echo "✅ Fast regression validation complete"

# Full regression validation (for nightly builds)
test-full-regression: test-smoke test-regression
	@echo "✅ Full regression validation complete"

# Frontend Performance Testing
test-performance:
	@echo "⚡ Running frontend performance tests..."
	python -m pytest tests/performance/test_frontend_bundle_performance.py -v --tb=short

test-bundle:
	@echo "📦 Running bundle optimization validation..."
	python -m pytest tests/performance/test_frontend_bundle_performance.py -v -k "lazy_loading or manual_chunks or favicon or css_code_splitting"

# Comprehensive Testing Targets (Full-Stack)
# Run frontend unit tests (Vitest)
test-frontend:
	@echo "⚛️ Running frontend unit tests..."
	cd src/frontend && npm run test

# Run frontend-backend integration tests
test-frontend-integration:
	@echo "🔗 Running frontend-backend integration tests..."
	$(compose_test) run --rm test \
		pytest tests/integration/test_frontend_backend_api_integration.py -v --tb=short --timeout=120

# Run critical user workflow tests (E2E with Playwright)
test-user-workflows:
	@echo "👤 Running critical user workflow tests..."
	$(compose_test) run --rm playwright \
		pytest tests/e2e/test_critical_user_workflows.py -v --tb=short

# Run complete comprehensive testing (All 5 Tiers)
test-comprehensive:
	@echo "🎯 Running comprehensive full-stack testing..."
	@echo "Tier 1: API Contract Tests..."
	$(compose_test) run --rm test pytest tests/smoke/test_critical_apis.py -v --tb=short -x
	@echo "Tier 2: Backend Workflows..."
	$(compose_test) run --rm test pytest tests/smoke/test_lightweight_workflows.py -v --tb=short -x
	@echo "Tier 3: Frontend Unit Tests..."
	cd src/frontend && npm run test --run
	@echo "Tier 4: Frontend-Backend Integration..."
	$(compose_test) run --rm test pytest tests/integration/test_frontend_backend_api_integration.py -v --tb=short
	@echo "Tier 5: User Workflows..."
	$(compose_test) run --rm playwright pytest tests/e2e/test_critical_user_workflows.py -v --tb=short
	@echo "✅ All 5 tiers completed!"

# Development helpers
install-hooks:
	@echo "🔧 Installing regression testing git hooks..."
	@if [ -f "scripts/install-regression-hooks.sh" ]; then \
		bash scripts/install-regression-hooks.sh; \
	elif command -v powershell >/dev/null 2>&1 && [ -f "scripts/install-regression-hooks.ps1" ]; then \
		powershell -ExecutionPolicy Bypass -File scripts/install-regression-hooks.ps1; \
	else \
		echo "❌ Hook installation script not found"; \
		exit 1; \
	fi# Test Database Management Commands
# Add these to your main Makefile

# Test Database Management
.PHONY: test-db-start test-db-stop test-db-status test-db-reset test-db-logs test-integration-full test-pdf-deletion
test-db-start:
	@echo "🚀 Starting test database environment..."
	$(compose_test) up -d supabase-db redis
	@echo "⏳ Waiting for services to be ready..."
	$(compose_test) up supabase-migrate
	@echo "✅ Test database ready for integration tests"

test-db-stop:
	@echo "🛑 Stopping test database environment..."
	$(compose_test) down -v --remove-orphans
	@echo "✅ Test database stopped and cleaned"

test-db-status:
	@echo "📊 Test database status:"
	$(compose_test) ps

test-db-reset:
	@echo "🔄 Resetting test database..."
	$(compose_test) down -v --remove-orphans
	$(compose_test) up -d supabase-db redis
	$(compose_test) up supabase-migrate
	@echo "✅ Test database reset complete"

test-db-logs:
	@echo "📋 Test database logs:"
	$(compose_test) logs supabase-db

# Run database consistency tests only
test-database-consistency:
	@echo "🎯 Running database consistency tests (12 tests)..."
	@$(MAKE) test-db-start
	$(compose_test) run --rm test pytest tests/integration/test_database_consistency.py -v --tb=short
	@$(MAKE) test-db-stop
	@echo "✅ Database consistency tests complete"

# Run async correctness tests (NO MOCKING - catches missing await bugs)
test-async-correctness:
	@echo "⚡ Running async correctness tests (11 tests)..."
	@$(MAKE) test-db-start
	$(compose_test) run --rm test pytest tests/integration/test_pdf_crud_async_correctness.py -v --tb=short
	@$(MAKE) test-db-stop
	@echo "✅ Async correctness tests complete"

# Run integration tests with auto-managed database
test-integration-full:
	@echo "🧪 Running integration tests with auto-managed database..."
	@$(MAKE) test-db-start
	@echo "🔍 Running database consistency tests..."
	$(compose_test) run --rm test pytest tests/integration/test_database_consistency.py -v --tb=short || TEST_FAILED=1
	@echo "🔍 Running content persistence tests..."
	$(compose_test) run --rm test pytest tests/integration/test_content_persistence.py -v --tb=short || TEST_FAILED=1
	@echo "🔍 Running data migration tests..."
	$(compose_test) run --rm test pytest tests/integration/test_data_migrations.py -v --tb=short || TEST_FAILED=1
	@$(MAKE) test-db-stop
	@if [ "$$TEST_FAILED" = "1" ]; then \
		echo "❌ Some integration tests failed"; \
		exit 1; \
	else \
		echo "✅ All integration tests passed"; \
	fi

# Run comprehensive PDF deletion tests (E2E + Integration + Database)
test-pdf-deletion:
	@echo "🗑️ Running comprehensive PDF deletion tests..."
	@$(MAKE) test-db-start
	@echo "📋 1/2: Running E2E upload/delete workflow tests..."
	$(compose_test) run --rm test pytest tests/e2e/test_pdf_upload_delete_workflow.py -v --tb=short || TEST_FAILED=1
	@echo "📋 2/2: Running database deletion cascade tests..."
	$(compose_test) run --rm test pytest tests/integration/test_database_consistency.py::TestDatabaseConsistency::test_pdf_deletion_cascade_consistency_failure -v --tb=short || TEST_FAILED=1
	@$(MAKE) test-db-stop
	@if [ "$$TEST_FAILED" = "1" ]; then \
		echo "❌ Some PDF deletion tests failed"; \
		exit 1; \
	else \
		echo "✅ All PDF deletion tests passed"; \
	fi