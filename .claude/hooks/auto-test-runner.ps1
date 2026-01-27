# Claude Code Auto-Test Runner Hook
# Triggered on Edit/Write operations
# Smart test selection based on file type and complexity

# Color formatting
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

Write-Host ""
Write-ColorOutput "[AUTO-TEST] Hook triggered - detecting modified files..." "Cyan"

# Get modified files from git status
$gitStatus = git status --short 2>$null
if (-not $gitStatus) {
    Write-ColorOutput "[AUTO-TEST] No git changes detected, exiting" "Gray"
    exit 0
}

# Parse modified files (M = modified, A = added, ?? = untracked)
$modifiedFiles = @()
foreach ($line in $gitStatus) {
    if ($line -match '^\s*[MA?]{1,2}\s+(.+)$') {
        $filePath = $matches[1].Trim()
        # Normalize path separators
        $filePath = $filePath -replace '/', '\'
        $modifiedFiles += $filePath
    }
}

if ($modifiedFiles.Count -eq 0) {
    Write-ColorOutput "[AUTO-TEST] No modified files found" "Gray"
    exit 0
}

Write-ColorOutput "[AUTO-TEST] Found $($modifiedFiles.Count) modified file(s)" "Yellow"

# Process each modified file
$processedFiles = @()
foreach ($FilePath in $modifiedFiles) {

Write-Host ""
Write-ColorOutput "[AUTO-TEST] Analyzing file: $FilePath" "Cyan"

# Filter: Only process relevant file types
$relevantExtensions = @('.py', '.ts', '.tsx', '.js', '.jsx')
$fileExtension = [System.IO.Path]::GetExtension($FilePath)

if ($relevantExtensions -notcontains $fileExtension) {
    Write-ColorOutput "[AUTO-TEST] Skipping - not a code file (extension: $fileExtension)" "Gray"
    continue
}

# Exclude config files and documentation
$excludedPatterns = @(
    '\.env',
    'config\.py',
    'settings\.py',
    'conftest\.py',
    'pytest\.ini',
    'package\.json',
    'tsconfig\.json',
    'vite\.config'
)

foreach ($pattern in $excludedPatterns) {
    if ($FilePath -match $pattern) {
        Write-ColorOutput "[AUTO-TEST] Skipping - excluded file pattern: $pattern" "Gray"
        continue
    }
}

# Create test reports folder
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$fileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
$reportsDir = "test-reports/auto-runs"
New-Item -ItemType Directory -Force -Path $reportsDir | Out-Null

$reportFile = "$reportsDir/${timestamp}_${fileName}.txt"

# Smart Test Selection Logic
function Get-TestCommands {
    param([string]$Path)

    $commands = @()
    $testType = "unit"

    # Read file content for complexity analysis
    $content = ""
    if (Test-Path $Path) {
        $content = Get-Content $Path -Raw -ErrorAction SilentlyContinue
    }

    # Backend Python files
    if ($fileExtension -eq '.py') {

        # ARQ tasks - always run integration + critical tests
        if ($Path -match 'arq_tasks[\\/]') {
            $testType = "integration+e2e"
            $commands += "docker compose -f docker-compose.test.yml --env-file .env.test run --rm test sh -lc 'pytest tests/integration/test_complete_pdf_pipeline.py -v'"
            $commands += "docker compose -f docker-compose.test.yml --env-file .env.test run --rm test sh -lc 'pytest tests/integration/test_database_consistency.py -v'"
        }
        # API routes - integration tests for async correctness
        elseif ($Path -match 'api[\\/]v1[\\/].*_routes\.py') {
            $testType = "integration"
            $commands += "./make.bat test-async-correctness"
            $commands += "docker compose -f docker-compose.test.yml --env-file .env.test run --rm test sh -lc 'pytest tests/integration/test_pdf_routes_async_correctness.py -v'"
        }
        # Services - check for async/database complexity
        elseif ($Path -match 'services[\\/]') {
            if ($content -match '(async |await |transaction|database|supabase|pgvector)') {
                $testType = "integration"
                $commands += "./make.bat test-database-consistency"
                $commands += "./make.bat test-async-correctness"
            } else {
                $testType = "unit"
                # Find related unit test
                $serviceName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
                $unitTest = "tests/unit/services/test_${serviceName}.py"
                if (Test-Path $unitTest) {
                    $commands += "docker compose -f docker-compose.test.yml --env-file .env.test run --rm test sh -lc 'pytest $unitTest -v'"
                } else {
                    $commands += "./make.bat test-unit"
                }
            }
        }
        # Test files themselves
        elseif ($Path -match 'tests[\\/]') {
            $testType = "specific"
            $relativePath = $Path -replace '\\', '/'
            $commands += "docker compose -f docker-compose.test.yml --env-file .env.test run --rm test sh -lc 'pytest $relativePath -v'"
        }
        # Default: unit tests
        else {
            $testType = "unit"
            $commands += "./make.bat test-unit"
        }
    }
    # Frontend TypeScript/React files
    elseif ($fileExtension -in @('.ts', '.tsx', '.js', '.jsx')) {

        # Components - run component tests
        if ($Path -match 'components[\\/]') {
            $testType = "frontend-unit"
            $componentName = [System.IO.Path]::GetFileName($Path)
            $testFile = "src/frontend/src/components/__tests__/${componentName.Replace('.tsx', '.test.tsx')}"
            if (Test-Path $testFile) {
                $commands += "cd src/frontend && npm test -- $testFile --run"
            } else {
                $commands += "cd src/frontend && npm test -- --run"
            }
        }
        # Hooks - run hook tests
        elseif ($Path -match 'hooks[\\/]') {
            $testType = "frontend-unit"
            $hookName = [System.IO.Path]::GetFileName($Path)
            $testFile = "src/frontend/src/hooks/__tests__/${hookName.Replace('.tsx', '.test.tsx')}"
            if (Test-Path $testFile) {
                $commands += "cd src/frontend && npm test -- $testFile --run"
            } else {
                $commands += "cd src/frontend && npm test -- --run"
            }
        }
        # Default: all frontend tests
        else {
            $testType = "frontend-unit"
            $commands += "cd src/frontend && npm test -- --run"
        }
    }

    return @{
        Commands = $commands
        TestType = $testType
    }
}

$testSelection = Get-TestCommands -Path $FilePath

Write-ColorOutput "[AUTO-TEST] Test type selected: $($testSelection.TestType)" "Yellow"
Write-ColorOutput "[AUTO-TEST] Commands to run:" "Yellow"
foreach ($cmd in $testSelection.Commands) {
    Write-ColorOutput "  - $cmd" "Gray"
}

# Prepare context for test-automation-engineer agent
$testingMdPath = "TESTING.md"
$testingContext = ""
if (Test-Path $testingMdPath) {
    $testingContext = Get-Content $testingMdPath -Raw
}

# Create agent task description
$commandsList = $testSelection.Commands -join [Environment]::NewLine
$agentTask = @"
Run automated tests for modified file: $FilePath

File Type: $fileExtension
Test Type: $($testSelection.TestType)

Test Commands to Execute:
$commandsList

Context from TESTING.md:
$testingContext

Instructions:
1. Execute the test commands sequentially
2. Capture all output (stdout + stderr)
3. Analyze test results:
   - Count passing/failing tests
   - Identify root causes of failures
   - Check for async/await issues (coroutine objects)
   - Look for database consistency problems
   - Detect race conditions or timing issues
4. Provide actionable recommendations:
   - Specific fixes for failing tests
   - Code locations to inspect
   - Potential regression impacts
5. Save detailed report to: $reportFile

Expected Output Format:
=== TEST EXECUTION SUMMARY ===
File: $FilePath
Test Type: $($testSelection.TestType)
Tests Run: X
Tests Passed: X
Tests Failed: X

=== FAILURES (if any) ===
[List each failure with file:line, error message, root cause]

=== RECOMMENDATIONS ===
[Specific actionable fixes]

=== FULL TEST OUTPUT ===
[Complete test logs]
"@

# Write initial report
$commandsListReport = $testSelection.Commands -join [Environment]::NewLine
$initialReport = @"
[AUTO-TEST REPORT]
Generated: $timestamp
File: $FilePath
Extension: $fileExtension
Test Type: $($testSelection.TestType)

=== TEST COMMANDS ===
$commandsListReport

=== EXECUTION LOG ===
"@

$initialReport | Out-File -FilePath $reportFile -Encoding UTF8

Write-Host ""
Write-ColorOutput "[AUTO-TEST] Invoking test-automation-engineer agent..." "Green"
Write-ColorOutput "[AUTO-TEST] Report will be saved to: $reportFile" "Green"

# Run test-automation-engineer agent in background
# Note: This assumes claude CLI is available - adjust if needed
try {
    # Execute tests directly and capture output
    $allOutput = ""

    foreach ($cmd in $testSelection.Commands) {
        Write-Host ""
        Write-ColorOutput "[AUTO-TEST] Running: $cmd" "Cyan"
        "`r`n=== Running: $cmd ===" | Out-File -FilePath $reportFile -Append -Encoding UTF8

        # Execute command and capture output
        $output = & cmd /c "$cmd 2>&1"
        $exitCode = $LASTEXITCODE

        $output | Out-File -FilePath $reportFile -Append -Encoding UTF8
        $allOutput += [Environment]::NewLine + $output

        if ($exitCode -ne 0) {
            Write-ColorOutput "[AUTO-TEST] Command failed with exit code: $exitCode" "Red"
        }
    }

    # Parse results
    $summary = @"

=== QUICK SUMMARY ===
File: $FilePath
Test Type: $($testSelection.TestType)
Commands Run: $($testSelection.Commands.Count)

Full report saved to: $reportFile

Check the report for:
- Test pass/fail counts
- Error messages and stack traces
- Recommendations for fixes
"@

    $summary | Out-File -FilePath $reportFile -Append -Encoding UTF8
    Write-ColorOutput $summary "Green"

    # Display terminal summary
    Write-Host ""
    Write-ColorOutput "[AUTO-TEST] ✓ Test execution completed" "Green"
    Write-ColorOutput "[AUTO-TEST] 📄 Report: $reportFile" "Cyan"

    # Show last 20 lines of output for quick feedback
    if ($allOutput) {
        $lastLines = ($allOutput -split [Environment]::NewLine) | Select-Object -Last 20
        Write-Host ""
        Write-ColorOutput "[AUTO-TEST] Last 20 lines of output:" "Yellow"
        $lastLines | ForEach-Object { Write-Host $_ }
    }

} catch {
    $errorMsg = "Error running tests: $_"
    Write-ColorOutput "[AUTO-TEST] ❌ $errorMsg" "Red"
    $errorMsg | Out-File -FilePath $reportFile -Append -Encoding UTF8
}

    # Track processed file
    $processedFiles += $FilePath

} # End foreach modified file

# Final summary
if ($processedFiles.Count -gt 0) {
    Write-Host ""
    Write-ColorOutput "[AUTO-TEST] ========================================" "Cyan"
    Write-ColorOutput "[AUTO-TEST] Processed $($processedFiles.Count) file(s):" "Green"
    foreach ($file in $processedFiles) {
        Write-ColorOutput "[AUTO-TEST]   - $file" "Gray"
    }
    Write-ColorOutput "[AUTO-TEST] Reports saved to: test-reports/auto-runs/" "Green"
    Write-ColorOutput "[AUTO-TEST] ========================================" "Cyan"
    Write-Host ""
} else {
    Write-Host ""
    Write-ColorOutput "[AUTO-TEST] No relevant code files to test" "Gray"
    Write-Host ""
}

exit 0
