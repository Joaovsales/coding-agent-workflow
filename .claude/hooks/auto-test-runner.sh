#!/bin/bash
# Claude Code Auto-Test Runner Hook
# Runs tests and creates task files for failures

set +e  # Don't exit on error, we want to capture failures

# Kill switch: skip hook if SKIP_AUTO_TEST=1
[ "${SKIP_AUTO_TEST:-0}" = "1" ] && exit 0

# Get modified files from git status
git_status=$(git status --short 2>/dev/null) || exit 0
[ -z "$git_status" ] && exit 0

# Parse modified files
mapfile -t modified_files < <(echo "$git_status" | awk '{print $2}')
[ ${#modified_files[@]} -eq 0 ] && exit 0

# Create directories
mkdir -p test-reports/auto-runs
mkdir -p tasks/failed-tests

# Timestamp
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

# Parse test output for results
parse_pytest_output() {
    local output="$1"
    local passed=$(echo "$output" | grep -oP '\d+(?= passed)' | head -1)
    local failed=$(echo "$output" | grep -oP '\d+(?= failed)' | head -1)
    local errors=$(echo "$output" | grep -oP '\d+(?= error)' | head -1)

    passed=${passed:-0}
    failed=${failed:-0}
    errors=${errors:-0}

    echo "$passed|$failed|$errors"
}

parse_npm_output() {
    local output="$1"
    local passed=$(echo "$output" | grep -oP 'Tests:\s+\K\d+(?= passed)' | head -1)
    local failed=$(echo "$output" | grep -oP 'Tests:\s+.*\K\d+(?= failed)' | head -1)

    passed=${passed:-0}
    failed=${failed:-0}

    echo "$passed|$failed|0"
}

# Extract failure details
extract_failures() {
    local output="$1"
    local file="$2"

    # Get FAILURES section from pytest
    echo "$output" | sed -n '/^=* FAILURES =*/,/^=* short test summary =*/p' | head -50
}

# Create XML task file
create_failure_task() {
    local file="$1"
    local test_type="$2"
    local failed_count="$3"
    local failure_details="$4"
    local task_file="tasks/failed-tests/${timestamp}_${file##*/}.xml"

    cat > "$task_file" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<task>
  <metadata>
    <created>$(date -Iseconds)</created>
    <triggered_by>auto-test-runner hook</triggered_by>
    <file>$file</file>
    <test_type>$test_type</test_type>
  </metadata>

  <summary>
    Fix $failed_count failing test(s) in $file
  </summary>

  <failure_details>
    <![CDATA[
$failure_details
    ]]>
  </failure_details>

  <investigation_steps>
    1. Review the failure details above
    2. Identify root cause (async/await issues, database state, race conditions)
    3. Check related code in: $file
    4. Run tests locally to reproduce
    5. Implement fix
    6. Verify tests pass
  </investigation_steps>

  <commands_to_run>
    <![CDATA[
# Reproduce the failure:
docker compose -f docker-compose.test.yml --env-file .env.test run --rm test sh -lc "pytest $file -v"

# After fix, verify:
./make.bat test-async-correctness
./make.bat test-database-consistency
    ]]>
  </commands_to_run>
</task>
EOF

    echo "$task_file"
}

# Process each file
for file_path in "${modified_files[@]}"; do
    # Filter: Only code files
    file_ext="${file_path##*.}"
    [[ ! "$file_ext" =~ ^(py|ts|tsx|js|jsx)$ ]] && continue

    # Skip excluded patterns
    [[ "$file_path" =~ (\.env|config\.py|settings\.py|conftest\.py|pytest\.ini|package\.json|tsconfig\.json|vite\.config) ]] && continue

    # Determine test type and commands
    test_type="unit"
    test_cmd=""

    if [ "$file_ext" = "py" ]; then
        if [[ "$file_path" =~ arq_tasks/ ]]; then
            test_type="integration"
            test_cmd="docker compose -f docker-compose.test.yml --env-file .env.test run --rm test sh -lc 'pytest tests/integration/test_complete_pdf_pipeline.py -v --tb=short'"
        elif [[ "$file_path" =~ api/v1/.*_routes\.py ]]; then
            test_type="integration"
            test_cmd="docker compose -f docker-compose.test.yml --env-file .env.test run --rm test sh -lc 'pytest tests/integration/test_pdf_routes_async_correctness.py -v --tb=short'"
        elif [[ "$file_path" =~ services/ ]]; then
            if grep -qE '(async |await |transaction|database|supabase)' "$file_path" 2>/dev/null; then
                test_type="integration"
                test_cmd="docker compose -f docker-compose.test.yml --env-file .env.test run --rm test sh -lc 'pytest tests/integration/test_database_consistency.py -v --tb=short'"
            else
                test_type="unit"
                service_name="${file_path##*/}"
                service_name="${service_name%.py}"
                unit_test="tests/unit/services/test_${service_name}.py"
                if [ -f "$unit_test" ]; then
                    test_cmd="docker compose -f docker-compose.test.yml --env-file .env.test run --rm test sh -lc 'pytest $unit_test -v --tb=short'"
                fi
            fi
        elif [[ "$file_path" =~ ^tests/ ]]; then
            test_type="specific"
            test_cmd="docker compose -f docker-compose.test.yml --env-file .env.test run --rm test sh -lc 'pytest $file_path -v --tb=short'"
        fi
    elif [[ "$file_ext" =~ ^(ts|tsx|js|jsx)$ ]]; then
        test_type="frontend"
        test_cmd="cd src/frontend && npm test -- --run 2>&1"
    fi

    # Skip if no test command
    [ -z "$test_cmd" ] && continue

    # Run tests
    echo "[AUTO-TEST] Running $test_type tests for: $file_path"
    output=$(eval "$test_cmd" 2>&1)
    exit_code=$?

    # Parse results
    if [[ "$test_type" == "frontend" ]]; then
        results=$(parse_npm_output "$output")
    else
        results=$(parse_pytest_output "$output")
    fi

    IFS='|' read -r passed failed errors <<< "$results"
    total=$((passed + failed + errors))

    # Create concise report
    report_file="test-reports/auto-runs/${timestamp}_${file_path##*/}.txt"
    cat > "$report_file" <<EOF
AUTO-TEST REPORT
================
Timestamp: $timestamp
File: $file_path
Test Type: $test_type

RESULTS
-------
Tests Run: $total
Passed: $passed
Failed: $failed
Errors: $errors
Exit Code: $exit_code

$(if [ $failed -gt 0 ] || [ $errors -gt 0 ]; then
    echo "FAILURE INVESTIGATION REQUIRED"
    echo "------------------------------"
    echo "Task file created: tasks/failed-tests/${timestamp}_${file_path##*/}.xml"
    echo ""
    echo "Top failure details:"
    extract_failures "$output" "$file_path" | head -30
fi)
EOF

    # Create task file for failures
    if [ $failed -gt 0 ] || [ $errors -gt 0 ]; then
        failure_details=$(extract_failures "$output" "$file_path")
        task_file=$(create_failure_task "$file_path" "$test_type" "$((failed + errors))" "$failure_details")
        echo "[AUTO-TEST] ❌ FAILURES DETECTED - Task created: $task_file"
    else
        echo "[AUTO-TEST] ✓ All tests passed for: $file_path"
    fi

    echo "[AUTO-TEST] Report: $report_file"
done

echo ""
echo "[AUTO-TEST] Hook completed"
exit 0
