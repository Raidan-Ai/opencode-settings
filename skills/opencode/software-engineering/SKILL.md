---
name: software-engineering
description: Codebase analysis, repository architecture, issue resolution, autonomous coding, refactoring, debugging, code review, git workflow, and software maintenance. Use for any software engineering task — from understanding a new codebase to debugging production issues to systematic refactoring.
---

# Software Engineering Skill

## Purpose
Provides comprehensive software engineering capabilities: codebase analysis, repository architecture understanding, issue resolution, autonomous coding workflows, systematic debugging, refactoring patterns, code review methodology, git workflows, and software maintenance practices. Enables working effectively with any codebase at any scale.

## When to Activate
- Understanding a new or unfamiliar codebase
- Debugging bugs, test failures, or unexpected behavior
- Refactoring code for maintainability or performance
- Reviewing code for quality, security, and correctness
- Resolving issues (bugs, feature requests, technical debt)
- Working with git (branching, merging, rebasing, bisecting)
- Maintaining software (dependency updates, deprecation handling)

## Core Knowledge

### Codebase Analysis Framework

```
┌─────────────────────────────────────────────────────────────┐
│              CODEBASE ANALYSIS PIPELINE                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Orientation                                             │
│     README → package.json/pyproject.toml → entry points    │
│                                                             │
│  2. Architecture                                            │
│     src/ structure → module boundaries → dependency flow    │
│                                                             │
│  3. Patterns                                                │
│     Naming conventions → error handling → testing patterns  │
│                                                             │
│  4. Hotspots                                                │
│     git log --stat → frequent changes → complexity热点     │
│                                                             │
│  5. Debt                                                    │
│     TODOs → FIXMEs → outdated deps → missing tests         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

```bash
# Quick codebase orientation
git log --oneline -20                    # Recent activity
git log --oneline --all | wc -l         # Total commits
git shortlog -sn                         # Top contributors
find . -name "*.py" -o -name "*.ts" -o -name "*.go" | head -30  # File landscape

# Complexity hotspots
git log --format='%H' --since="6 months ago" | \
  xargs git diff --stat | sort -t'|' -k2 -rn | head -20

# Dependency analysis
# Python
pip list --outdated 2>/dev/null
# Node
npm outdated 2>/dev/null
# Go
go list -m -u all 2>/dev/null
```

### Git Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                   GIT WORKFLOW                               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  main ─────────●──────────●──────────●──── (production)    │
│                 \          ↑          ↑                     │
│                  \    ┌────┘     ┌────┘                     │
│                   \──►│ feature  │ merge                    │
│                       └──────────┘                          │
│                                                             │
│  Feature Branch Workflow:                                   │
│  1. git checkout -b feature/TICKET-description             │
│  2. Make changes, commit with conventional commits         │
│  3. git rebase main (keep history linear)                  │
│  4. git push origin feature/TICKET-description             │
│  5. Open PR, get review, merge                             │
│                                                             │
│  Conventional Commits:                                     │
│  feat: add user authentication                             │
│  fix: resolve null pointer in parser                       │
│  refactor: extract database connection pool                │
│  docs: update API reference                                │
│  test: add integration tests for payment flow              │
│  chore: update dependencies                                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

```bash
# Common git commands
git checkout -b feature/my-feature          # Create feature branch
git add -p                                   # Stage changes interactively
git commit -m "feat: add user search"        # Conventional commit
git rebase -i HEAD~3                         # Interactive rebase (last 3)
git log --oneline --graph --all              # Visual branch history
git bisect start                             # Binary search for bugs
git bisect bad                               # Current commit is broken
git bisect good v1.0.0                       # Known working commit
git bisect run pytest                        # Auto-test each bisection

# Merge vs Rebase decision:
# Rebase: Linear history, clean history, local branches
# Merge:  Shared branches, preserving context, public branches
```

### Systematic Debugging Methodology

```
┌─────────────────────────────────────────────────────────────┐
│              SYSTEMATIC DEBUGGING PROCESS                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. REPRODUCE                                                │
│     Find exact steps to trigger the bug                     │
│     Get a minimal reproduction case                         │
│                                                             │
│  2. DIAGNOSE                                                 │
│     Read error messages carefully                           │
│     Add strategic logging/print statements                 │
│     Check recent changes (git log, git diff)               │
│     Binary search (git bisect) for regression              │
│                                                             │
│  3. HYPOTHESIZE                                              │
│     Form 1-3 theories about root cause                     │
│     Order by likelihood                                     │
│                                                             │
│  4. TEST                                                     │
│     Write a failing test that captures the bug             │
│     Fix the code until the test passes                      │
│     Verify no regressions                                   │
│                                                             │
│  5. PREVENT                                                  │
│     Add test to prevent regression                          │
│     Update docs if it was a docs issue                     │
│     Consider if the pattern exists elsewhere               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

```bash
# Debugging tools and commands

# Find where a variable/function is used
grep -rn "function_name" src/
rg "function_name" --type py  # ripgrep (faster)

# Check recent changes
git log --oneline -10                  # What changed recently
git diff HEAD~3 -- path/to/file       # Diff of recent changes
git blame path/to/file                # Who changed what line

# Binary search for regression
git bisect start
git bisect bad                         # Current (broken)
git bisect good v1.2.0                 # Known working
git bisect run python -m pytest tests/test_foo.py
# → Automatically finds the exact commit that broke it

# Runtime debugging
python -m pdb script.py               # Python debugger
node --inspect-brk script.js           # Node.js debugger
go run -gcflags='all=-N -l' main.go   # Go debugger (dlv)

# Common bug patterns to check first:
# 1. Off-by-one errors (loop bounds, indexing)
# 2. Null/None/undefined references
# 3. Race conditions (async, threads)
# 4. Stale state (closures, cache)
# 5. Encoding issues (UTF-8, line endings)
# 6. Timezone/date handling
# 7. Resource leaks (connections, file handles)
```

### Refactoring Patterns

```python
# Pattern 1: Extract Function
# Before:
def process_order(order):
    # 50 lines of validation
    # 30 lines of calculation
    # 20 lines of persistence
    pass

# After:
def process_order(order):
    validated = validate_order(order)
    total = calculate_total(validated)
    return persist_order(validated, total)

def validate_order(order): ...
def calculate_total(order): ...
def persist_order(order, total): ...

# Pattern 2: Replace Conditional with Polymorphism
# Before:
def calculate_price(item_type, quantity):
    if item_type == "book":
        return quantity * 9.99
    elif item_type == "electronics":
        return quantity * 99.99
    elif item_type == "food":
        return quantity * 4.99

# After:
class ItemPricing:
    def price(self, quantity): raise NotImplementedError

class BookPricing(ItemPricing):
    def price(self, quantity): return quantity * 9.99

class ElectronicsPricing(ItemPricing):
    def price(self, quantity): return quantity * 99.99

PRICING = {"book": BookPricing(), "electronics": ElectronicsPricing()}

def calculate_price(item_type, quantity):
    return PRICING[item_type].price(quantity)

# Pattern 3: Introduce Parameter Object
# Before:
def create_user(name, email, phone, address, city, state, zip_code):
    pass

# After:
@dataclass
class Address:
    street: str
    city: str
    state: str
    zip_code: str

def create_user(name: str, email: str, phone: str, address: Address):
    pass

# Pattern 4: Replace Magic Numbers with Constants
# Before:
if len(items) > 100:
    process_in_batches(items, 25)

# After:
MAX_ITEMS = 100
BATCH_SIZE = 25

if len(items) > MAX_ITEMS:
    process_in_batches(items, BATCH_SIZE)
```

### Code Review Checklist

```
┌─────────────────────────────────────────────────────────────┐
│                 CODE REVIEW CHECKLIST                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  CORRECTNESS                                                │
│  □ Does the code do what the PR description says?          │
│  □ Are edge cases handled (empty, null, overflow)?         │
│  □ Are errors handled (try/catch, error returns)?          │
│  □ Are there off-by-one errors?                            │
│                                                             │
│  SECURITY                                                   │
│  □ Input validation present?                               │
│  □ No secrets/credentials in code?                         │
│  □ SQL injection / XSS prevention?                         │
│  □ Auth checks in place?                                   │
│                                                             │
│  PERFORMANCE                                                │
│  □ No N+1 queries?                                         │
│  □ No unnecessary loops or computations?                   │
│  □ Caching appropriate?                                    │
│  □ Memory usage bounded?                                   │
│                                                             │
│  MAINTAINABILITY                                            │
│  □ Code is readable (clear naming, small functions)?       │
│  □ No code duplication (DRY)?                              │
│  □ Tests cover the change?                                 │
│  □ Documentation updated if needed?                        │
│                                                             │
│  STYLE                                                      │
│  □ Follows project conventions?                            │
│  □ Consistent naming?                                      │
│  □ No dead code or commented-out code?                     │
│  □ Commit messages are clear?                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Software Maintenance Patterns

```bash
# Dependency management
# Python
pip install --upgrade pip
pip freeze > requirements.txt
pip install -r requirements.txt

# Node
npm outdated
npm update
npm audit fix

# Go
go get -u ./...
go mod tidy

# Version bumping (conventional commits)
# feat: → minor bump (0.1.0 → 0.2.0)
# fix:  → patch bump (0.1.0 → 0.1.1)
# feat!: → major bump (0.1.0 → 1.0.0)

# Deprecation handling
# 1. Mark as deprecated with message
# 2. Add warnings.warn("Use new_func instead", DeprecationWarning)
# 3. Keep for N releases
# 4. Remove with changelog entry
```

## Workflow

### 1. Understand the Codebase
```bash
# Before making ANY changes:
# Read README, architecture docs, and contribution guide
# Identify the tech stack and key dependencies
# Find the entry points and module structure
# Note coding conventions (naming, error handling, testing)
```

### 2. Reproduce the Issue
```bash
# For bugs: get exact steps to reproduce
# For features: understand the expected behavior
# Write a failing test that captures the requirement
```

### 3. Implement the Fix/Feature
```bash
# Create feature branch
git checkout -b fix/issue-description

# Make minimal, focused changes
# Follow existing code patterns
# Add tests for new behavior

# Commit with conventional format
git commit -m "fix: resolve null pointer in user search"

# Rebase on main before pushing
git rebase main
git push origin fix/issue-description
```

### 4. Review & Verify
```bash
# Run full test suite
# Check for linting/style issues
# Verify no regressions
# Self-review using the checklist
```

### 5. Merge & Clean Up
```bash
# Merge PR (squash or rebase per team convention)
# Delete feature branch
# Close associated issue
# Update changelog if needed
```

## Tools
```bash
# Version control
git

# Code search
ripgrep (rg)                    # Fast regex search
fd                              # Fast find alternative

# Static analysis
pylint flake8 ruff              # Python
eslint                          # JavaScript/TypeScript
golangci-lint                   # Go

# Formatting
black isort                     # Python
prettier                        # JS/TS
gofmt goimports                 # Go

# Testing
pytest                          # Python
vitest jest                     # JavaScript
go test                         # Go

# Debugging
pdb / ipdb                      # Python
node --inspect                  # JavaScript
dlv (delve)                     # Go
```

## MCP Requirements
- **Git MCP**: Repository operations, diff analysis, blame
- **Code Search MCP**: Fast code search across repositories
- **CI/CD MCP**: Build status, test results, deployment pipeline

## Best Practices

1. **Read before writing**: Understand existing patterns before adding new code
2. **Small PRs**: Keep changes focused and reviewable (< 400 lines ideal)
3. **Tests first**: Write failing tests before fixing bugs
4. **Commit often**: Small, focused commits with clear messages
5. **Rebase before push**: Keep history linear and clean
6. **Code review everything**: No one-person merges for non-trivial changes
7. **Document decisions**: Why > what (code shows what, docs explain why)
8. **Automate everything**: If you do it twice, script it
9. **Fail fast**: Validate inputs early, fail with clear messages
10. **Leave code better**: Every touch improves it slightly

## Anti-patterns

- ❌ Pushing directly to main (no review, no history)
- ❌ Mega PRs (thousands of lines, impossible to review)
- ❌ "Works on my machine" (no environment documentation)
- ❌ Ignoring failing tests (flaky test suppression)
- ❌ Copy-paste coding (duplicated logic diverges)
- ❌ Skipping commit messages (bare "fix" or "update")
- ❌ Debugging by randomly changing code (no systematic approach)
- ❌ Refactoring while fixing bugs (mixing concerns)
- ❌ Not reading error messages (the answer is usually there)

## Verification

### Code Quality Checks
```bash
# Python
python -m pylint src/
python -m ruff check src/
python -m black --check src/

# JavaScript/TypeScript
npx eslint src/
npx prettier --check src/

# Go
golangci-lint run
gofmt -l .

# All languages
git diff --check  # Check for whitespace errors
```

### Test Verification
```bash
# Python
python -m pytest tests/ -v --tb=short

# JavaScript
npx vitest run --reporter=verbose

# Go
go test ./... -v -count=1
```

## Examples

### Systematic Bug Investigation
```bash
# Step 1: Reproduce
python -m pytest tests/test_payment.py::test_refund -v
# → FAILS: AssertionError in refund calculation

# Step 2: Bisect to find when it broke
git bisect start
git bisect bad HEAD
git bisect good v2.1.0
git bisect run python -m pytest tests/test_payment.py::test_refund -x
# → Finds: commit abc123 "refactor: update payment processor"

# Step 3: Examine the breaking commit
git show abc123 --stat
git diff abc123^..abc123 -- src/payment.py
# → Found: removed tax calculation in refactor

# Step 4: Fix
# Add test that catches the regression
# Fix the code
# Verify test passes
```

### Large-Scale Refactoring
```bash
# Step 1: Identify all usages
rg "old_function_name" --type py -l
# → 12 files use old_function_name

# Step 2: Create new function
# Add new_function with same interface but improved implementation

# Step 3: Migrate incrementally
# Change one file at a time, run tests after each
for file in $(rg "old_function_name" --type py -l); do
    sed -i 's/old_function_name/new_function/g' "$file"
    python -m pytest tests/ -x  # Verify after each file
done

# Step 4: Remove old function
git diff  # Review all changes
git commit -m "refactor: replace old_function_name with new_function"

# Step 5: Verify no regressions
python -m pytest tests/ -v
```

### Git Bisect for Regression
```bash
# Find which commit broke a test
git bisect start
git bisect bad                    # Current HEAD is broken
git bisect good v1.5.0            # v1.5.0 was working

# Let git find the exact commit
git bisect run python -m pytest tests/test_api.py::test_auth -x

# Output:
# abc1234 is the first bad commit
# Author: <name>
# Date: <date>
# refactor: simplify auth middleware

# Now you know exactly what broke it
git show abc1234
```

### Code Review Flow
```bash
# Check out PR branch
git fetch origin
git checkout origin/feature/user-search

# Self-review the diff
git diff main...HEAD --stat          # What files changed?
git diff main...HEAD -- src/auth.py  # Review specific changes

# Run tests
python -m pytest tests/ -v

# Check for common issues
git diff main...HEAD | grep -n "password\|secret\|key"  # Secrets?
git diff main...HEAD | grep -n "TODO\|FIXME\|HACK"     # Debt?

# Leave structured feedback
# 1. Correctness: "This doesn't handle empty input"
# 2. Security: "This SQL query needs parameterization"
# 3. Performance: "This N+1 query could be batched"
# 4. Style: "Consider extracting this into a function"
```
