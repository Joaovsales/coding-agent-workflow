---
name: tests
description: Invoke the testing subagent to review completed features, analyze coverage, write missing tests, and update documentation
---

Use the `testing` subagent to perform comprehensive testing workflow for recently completed features.

## Usage

This command delegates to the specialized testing subagent that will:

1. **Review completed work** - Check git history and TASKS.md for context
2. **Analyze current tests** - Identify coverage gaps and testing needs
3. **Write missing tests** - Create contract-based tests following best practices
4. **Run test suite** - Verify all tests pass in Docker environment
5. **Update TESTING.md** - Maintain concise test documentation
6. **Report findings** - Provide summary of test coverage and recommendations

## When to Use

- ✅ After completing a task from `docs/TASKS.md`
- ✅ Before marking a feature as "done"
- ✅ When test coverage needs improvement
- ✅ After refactoring to ensure contracts still hold
- ✅ When debugging test failures

## Example Invocations

**After completing a feature:**
```
/tests Review the completed FRONTEND-07 task and ensure test coverage
```

**General test review:**
```
/tests Check test coverage and write missing tests
```

**After bug fix:**
```
/tests Add regression tests for the payment validation bug fix
```

## What the Subagent Does

The testing subagent specializes in:

- **Contract-based testing** - Tests what code promises, not how it's implemented
- **Integration testing** - Validates real data flows without excessive mocking
- **Test organization** - Keeps tests structured and maintainable
- **Documentation** - Maintains TESTING.md with coverage information
- **Best practices** - Follows Clean Code principles for tests

## Testing Principles

The subagent follows these core principles:

1. **Test the contract, not implementation** - Focus on behavior and interfaces
2. **Organized test files** - Clear structure in `tests/` directory
3. **Cover the flow** - Integration tests for key user journeys
4. **No internal mocking** - Integration tests use real async/database methods
5. **Meaningful names** - Test descriptions clearly state what they verify
6. **Docker execution** - All tests run in proper containerized environment

## Output

The subagent will provide:

- ✅ Test coverage report (with percentages)
- ✅ List of new tests added
- ✅ Status of all test suites
- ✅ Recommendations for additional testing
- ✅ Updated TESTING.md file

---

**Note**: This command requires the `testing` subagent to be configured at `.cursor/agents/testing.md`. The subagent has context of your PRD, testing strategy, and best practices.
