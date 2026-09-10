# Testing Skill

## Purpose
Provides comprehensive testing expertise across the full testing pyramid: unit, integration, end-to-end, API, load, performance, security, and AI/agent evaluation. Covers pytest, vitest, Playwright, k6, OWASP ZAP, and LLM-specific evaluation metrics (recall@k, faithfulness, answer relevancy, tool-call accuracy). Enables building reliable test suites for traditional software and AI systems.

## When to Activate
- Writing or reviewing unit, integration, or end-to-end tests
- Setting up test infrastructure (pytest, vitest, Playwright)
- Performing load testing or performance benchmarking
- Running security scans (OWASP ZAP, SAST)
- Evaluating RAG pipelines or LLM agent quality
- Debugging test failures or improving test coverage
- Setting up CI/CD test pipelines

## Core Knowledge

### Testing Pyramid
```
        ╱╲
       ╱ E2E ╲          Fewer, slower, higher confidence
      ╱────────╲
     ╱Integration╲      Moderate count, moderate speed
    ╱──────────────╲
   ╱   Unit Tests    ╲  Many, fast, low-level confidence
  ╱────────────────────╲
```

### Test Types
| Type | Speed | Scope | Confidence | Tool |
|------|-------|-------|------------|------|
| Unit | < 10ms | Single function/class | Low (isolated) | pytest, vitest |
| Integration | 100ms–1s | Multiple modules, DB, API | Medium | pytest, supertest |
| E2E | 1–30s | Full user flow, browser | High | Playwright, Cypress |
| Load | Variable | System under concurrency | Capacity | k6, Locust |
| Security | Variable | Full stack | Risk reduction | OWASP ZAP, semgrep |
| AI Eval | 1–60s | LLM output quality | Qualitative | ragas, deepeval |

### pytest Fundamentals
```python
import pytest
from unittest.mock import Mock, patch, MagicMock

# ── Fixtures ──────────────────────────────────────────────────
@pytest.fixture
def sample_user():
    """Provide a sample user object."""
    return {"id": 1, "name": "Alice", "email": "alice@example.com"}

@pytest.fixture
def mock_db():
    """Mock database connection."""
    db = Mock()
    db.query.return_value = [{"id": 1, "name": "Test"}]
    db.execute.return_value = True
    yield db
    db.close.assert_called_once()

@pytest.fixture(autouse=True)
def reset_env(monkeypatch):
    """Reset environment variables for every test."""
    monkeypatch.delenv("API_KEY", raising=False)
    monkeypatch.delenv("DATABASE_URL", raising=False)

# ── Parameterized Tests ───────────────────────────────────────
@pytest.mark.parametrize("input_val,expected", [
    ("hello", "HELLO"),
    ("world", "WORLD"),
    ("", ""),
    ("Mix123", "MIX123"),
])
def test_uppercase(input_val, expected):
    assert input_val.upper() == expected

# ── Async Tests ───────────────────────────────────────────────
@pytest.mark.asyncio
async def test_fetch_user(mock_db):
    from myapp.services import get_user
    user = await get_user(mock_db, user_id=1)
    assert user["name"] == "Test"
    mock_db.query.assert_awaited_once()

# ── Exception Testing ─────────────────────────────────────────
def test_division_by_zero():
    with pytest.raises(ZeroDivisionError, match="division by zero"):
        1 / 0

# ── Mocking External Services ─────────────────────────────────
@patch("myapp.services.requests.get")
def test_api_call(mock_get):
    mock_get.return_value = Mock(
        status_code=200,
        json=lambda: {"result": "success"}
    )
    from myapp.services import call_external_api
    result = call_external_api("https://api.example.com/data")
    assert result["result"] == "success"
    mock_get.assert_called_once_with(
        "https://api.example.com/data",
        timeout=10
    )
```

### vitest Fundamentals
```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';

// ── Mocking modules ──────────────────────────────────────────
vi.mock('./database', () => ({
  db: {
    query: vi.fn().mockResolvedValue([{ id: 1, name: 'Test' }]),
    execute: vi.fn().mockResolvedValue(true),
  }
}));

import { getUser } from './services';
import { db } from './database';

// ── Basic Tests ──────────────────────────────────────────────
describe('getUser', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should return user by id', async () => {
    const user = await getUser(1);
    expect(user).toEqual({ id: 1, name: 'Test' });
    expect(db.query).toHaveBeenCalledWith(
      'SELECT * FROM users WHERE id = $1', [1]
    );
  });

  it('should throw on invalid id', async () => {
    db.query.mockResolvedValue([]);
    await expect(getUser(-1)).rejects.toThrow('User not found');
  });
});

// ── Snapshot Testing ─────────────────────────────────────────
it('renders component correctly', () => {
  const output = renderComponent({ title: 'Hello' });
  expect(output).toMatchSnapshot();
});

// ── Timer Mocking ────────────────────────────────────────────
it('debounces function calls', async () => {
  vi.useFakeTimers();
  const fn = vi.fn();
  const debounced = debounce(fn, 300);
  debounced();
  debounced();
  expect(fn).not.toHaveBeenCalled();
  vi.advanceTimersByTime(300);
  expect(fn).toHaveBeenCalledTimes(1);
  vi.useRealTimers();
});
```

### Playwright E2E Testing
```typescript
import { test, expect, type Page } from '@playwright/test';

test.describe('Login Flow', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login');
  });

  test('successful login redirects to dashboard', async ({ page }) => {
    await page.fill('#email', 'user@example.com');
    await page.fill('#password', 'securePass123');
    await page.click('button[type="submit"]');

    await expect(page).toHaveURL('/dashboard');
    await expect(page.locator('h1')).toContainText('Welcome');
  });

  test('failed login shows error message', async ({ page }) => {
    await page.fill('#email', 'wrong@example.com');
    await page.fill('#password', 'wrongpass');
    await page.click('button[type="submit"]');

    await expect(page.locator('.error-message')).toBeVisible();
    await expect(page.locator('.error-message')).toContainText('Invalid credentials');
  });

  test('network interception', async ({ page }) => {
    // Mock API response
    await page.route('**/api/auth', route => {
      route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ token: 'mock-jwt-token' }),
      });
    });

    await page.fill('#email', 'user@example.com');
    await page.fill('#password', 'test');
    await page.click('button[type="submit"]');

    await expect(page).toHaveURL('/dashboard');
  });

  test('screenshot on failure', async ({ page }) => {
    await page.fill('#email', 'test');
    await page.screenshot({ path: 'test-results/login-page.png' });
  });
});

// playwright.config.ts
// export default defineConfig({
//   testDir: './e2e',
//   retries: 2,
//   use: {
//     baseURL: 'http://localhost:3000',
//     screenshot: 'only-on-failure',
//     trace: 'on-first-retry',
//   },
//   projects: [
//     { name: 'chromium', use: { browserName: 'chromium' } },
//     { name: 'firefox', use: { browserName: 'firefox' } },
//     { name: 'webkit', use: { browserName: 'webkit' } },
//   ],
// });
```

### k6 Load Testing
```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const errorRate = new Rate('errors');
const latency = new Trend('api_latency');

export const options = {
  stages: [
    { duration: '30s', target: 20 },   // ramp up
    { duration: '1m',  target: 20 },   // sustain
    { duration: '30s', target: 50 },   // spike
    { duration: '1m',  target: 50 },   // sustain spike
    { duration: '30s', target: 0 },    // ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],   // 95% under 500ms
    errors: ['rate<0.1'],               // < 10% error rate
  },
};

export default function () {
  const res = http.get('http://localhost:8080/api/users');

  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
    'has correct content-type': (r) =>
      r.headers['Content-Type']?.includes('application/json'),
  });

  errorRate.add(res.status !== 200);
  latency.add(res.timings.duration);

  sleep(1);
}

export function handleSummary(data) {
  return {
    'stdout': JSON.stringify(data.metrics, null, 2),
    'load-test-results.json': JSON.stringify(data),
  };
}
```

### OWASP ZAP Security Testing
```bash
# ── ZAP Quick Scan (baseline) ────────────────────────────────
docker run -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
  -t https://your-app.example.com \
  -r security-report.html \
  -l WARN

# ── ZAP Full Scan ─────────────────────────────────────────────
docker run -t ghcr.io/zaproxy/zaproxy:stable zap-full-scan.py \
  -t https://your-app.example.com \
  -r full-security-report.html \
  -J full-report.json

# ── ZAP API Scan ──────────────────────────────────────────────
docker run -t ghcr.io/zaproxy/zaproxy:stable zap-api-scan.py \
  -t https://your-app.example.com/openapi.json \
  -f openapi \
  -r api-report.html

# ── ZAP as a library (Python) ────────────────────────────────
from zapv2 import ZAPv2

zap = ZAPv2(apikey='your-api-key',
            proxies={'http': 'http://127.0.0.1:8080',
                     'https': 'http://127.0.0.1:8080'})

# Spider the target
scan_id = zap.spider.scan('https://your-app.example.com')
print(f"Spider progress: {zap.spider.status(scan_id)}")

# Active scan
scan_id = zap.ascan.scan('https://your-app.example.com')
alerts = zap.core.alerts(baseurl='https://your-app.example.com')
print(f"Found {len(alerts)} alerts")

for alert in alerts:
    print(f"  [{alert['risk']}] {alert['alert']}: {alert['description'][:100]}")
```

### RAG Evaluation Metrics
```python
from ragas import evaluate
from ragas.metrics import (
    faithfulness,
    answer_relevancy,
    context_precision,
    context_recall,
)
from datasets import Dataset

# ── Prepare evaluation dataset ────────────────────────────────
eval_data = {
    "question": [
        "What is the return policy?",
        "How do I reset my password?",
    ],
    "answer": [
        "You can return items within 30 days.",
        "Go to Settings > Security > Reset Password.",
    ],
    "contexts": [
        ["Our return policy allows returns within 30 days of purchase."],
        ["Navigate to Settings, then Security tab, and click Reset Password."],
    ],
    "ground_truth": [
        "Items can be returned within 30 days.",
        "Go to Settings > Security > Reset Password.",
    ],
}

dataset = Dataset.from_dict(eval_data)

# ── Run evaluation ────────────────────────────────────────────
result = evaluate(
    dataset,
    metrics=[
        faithfulness,        # Is the answer grounded in the context?
        answer_relevancy,    # Does the answer address the question?
        context_precision,   # Are the retrieved contexts relevant?
        context_recall,      # Do contexts contain the ground truth?
    ],
)

print(result)
# faithfulness:       0.95  (answer is supported by context)
# answer_relevancy:   0.88  (answer addresses the question)
# context_precision:  0.92  (retrieved contexts are relevant)
# context_recall:     0.90  (contexts cover the ground truth)

# ── Recall@K (custom metric) ──────────────────────────────────
def recall_at_k(retrieved_docs, relevant_docs, k=5):
    """Proportion of relevant docs found in top-k retrieved."""
    retrieved_k = retrieved_docs[:k]
    hits = len(set(retrieved_k) & set(relevant_docs))
    return hits / len(relevant_docs) if relevant_docs else 0.0

# Example
retrieved = ["doc1", "doc3", "doc5", "doc7", "doc9"]
relevant = ["doc1", "doc3", "doc10"]
print(f"Recall@5: {recall_at_k(retrieved, relevant, k=5):.2f}")
# Output: Recall@5: 0.67 (found 2 of 3 relevant docs in top 5)
```

### Agent / Tool-Call Evaluation
```python
import json
from dataclasses import dataclass, field
from typing import List, Dict, Any

@dataclass
class ToolCall:
    name: str
    arguments: Dict[str, Any]

@dataclass
class AgentTestCase:
    query: str
    expected_tool: str
    expected_args_keys: List[str]
    actual_tool: str = ""
    actual_args: Dict[str, Any] = field(default_factory=dict)

def evaluate_tool_calls(test_cases: List[AgentTestCase]) -> Dict[str, float]:
    """Evaluate agent tool-call accuracy."""
    tool_accuracy = 0
    arg_key_accuracy = 0
    total = len(test_cases)

    for tc in test_cases:
        if tc.actual_tool == tc.expected_tool:
            tool_accuracy += 1
        arg_hits = sum(1 for k in tc.expected_args_keys if k in tc.actual_args)
        arg_key_accuracy += arg_hits / len(tc.expected_args_keys)

    return {
        "tool_name_accuracy": tool_accuracy / total,
        "arg_key_accuracy": arg_key_accuracy / total,
        "total_cases": total,
    }

# Example usage
tests = [
    AgentTestCase(
        query="Search for recent articles about climate change",
        expected_tool="web_search",
        expected_args_keys=["query", "num_results"],
        actual_tool="web_search",
        actual_args={"query": "climate change articles", "num_results": 10},
    ),
    AgentTestCase(
        query="What's the weather in London?",
        expected_tool="get_weather",
        expected_args_keys=["city"],
        actual_tool="get_weather",
        actual_args={"city": "London", "units": "celsius"},
    ),
]

metrics = evaluate_tool_calls(tests)
print(f"Tool name accuracy: {metrics['tool_name_accuracy']:.0%}")
print(f"Arg key accuracy:   {metrics['arg_key_accuracy']:.0%}")
# Tool name accuracy: 100%
# Arg key accuracy:   100%
```

## Workflow

### Test-Driven Development (TDD)
```
1. Write failing test    → Red
2. Write minimal code    → Green
3. Refactor              → Improve structure
4. Repeat
```

### Test Setup Checklist
1. Identify test type (unit / integration / e2e)
2. Mock external dependencies (DB, API, filesystem)
3. Write test cases for happy path + edge cases
4. Run tests and verify coverage
5. Add to CI pipeline

### CI/CD Test Integration
```yaml
# GitHub Actions example
# test:
#   runs-on: ubuntu-latest
#   steps:
#     - uses: actions/checkout@v4
#     - uses: actions/setup-node@v4
#       with: { node-version: '20' }
#     - run: npm ci
#     - run: npm run test:unit
#     - run: npm run test:integration
#     - run: npx playwright install --with-deps chromium
#     - run: npx playwright test
```

## Tools

### Package Installation
```bash
# Python testing
pip install pytest pytest-asyncio pytest-cov pytest-mock

# JavaScript/TypeScript testing
npm install -D vitest @vitest/coverage-v8

# Playwright (E2E)
npm install -D @playwright/test
npx playwright install

# Load testing
# k6: https://k6.io/docs/get-started/installation/
# On Ubuntu: sudo gpg -k && sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D68 && echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list && sudo apt-get update && sudo apt-get install k6

# Security scanning
pip install bandit safety
npm install -D snyk

# RAG evaluation
pip install ragas datasets
```

### Command-Line Utilities
```bash
# pytest
pytest -v                          # Verbose output
pytest -x                          # Stop on first failure
pytest --cov=myapp --cov-report=html  # Coverage report
pytest -k "test_login"             # Run matching tests

# vitest
npx vitest run                     # Run all tests
npx vitest --coverage              # With coverage
npx vitest --reporter verbose      # Verbose output

# Playwright
npx playwright test                # Run all e2e tests
npx playwright test --ui           # Interactive UI mode
npx playwright show-report         # View HTML report

# k6
k6 run load-test.js                # Run load test
k6 run --out json=results.json load-test.js

# Security
bandit -r myapp/                   # Python SAST
safety check                       # Dependency vulnerability check
npx snyk test                      # JS vulnerability scan
```

### MCP Integration
```json
{
  "mcpServers": {
    "testing": {
      "command": "npx",
      "args": ["-y", "testing-mcp"],
      "description": "Test runner and reporter MCP server",
      "tools": ["run_tests", "coverage_report", "lint_check"]
    }
  }
}
```

## Best Practices

1. **Test one thing per test**: Each test should assert a single behavior. Multiple assertions are fine if they validate one concept.

2. **Arrange-Act-Assert pattern**:
   ```python
   def test_addition():
       # Arrange
       calculator = Calculator()
       # Act
       result = calculator.add(2, 3)
       # Assert
       assert result == 5
   ```

3. **Isolate tests**: Never depend on test execution order. Each test must be self-contained.

4. **Mock at boundaries**: Mock external services, databases, and time — not internal business logic.

5. **Test behavior, not implementation**: Assert on outputs and side effects, not internal method calls.

6. **Use descriptive test names**: `test_login_with_invalid_password_returns_401` not `test_login_2`.

7. **Keep E2E tests minimal**: Test critical user flows only. Push edge cases to unit/integration.

8. **Measure code coverage but don't chase 100%**: Focus on covering critical paths and edge cases.

9. **Run fast tests in pre-commit**: Unit tests in hooks, integration in CI, E2E nightly.

10. **Version control test data**: Keep fixtures and test data in repo, not generated at runtime.

## Anti-patterns

- ❌ Testing implementation details (testing private methods, internal state)
- ❌ Sharing mutable state between tests (test pollution)
- ❌ Using real APIs/services in unit tests (flaky, slow)
- ❌ Writing tests after code is shipped without tests (testing vacuum)
- ❌ Testing framework code instead of application code
- ❌ Ignoring test flakiness (flaky tests erode trust)
- ❌ Skipping cleanup/teardown (resource leaks)
- ❌ Hardcoded timeouts in E2E tests (use explicit waits)
- ❌ Copy-pasting tests without understanding what they verify
- ❌ Treating coverage as a score to maximize rather than a tool to find gaps

## Verification

### Unit Tests
```bash
# Python
pytest --version && pytest -v

# JavaScript
npx vitest --version && npx vitest run

# Verify Playwright installation
npx playwright --version
npx playwright test --list
```

### Integration Tests
```bash
# Run with database (Docker)
docker run -d --name test-db -p 5432:5432 -e POSTGRES_PASSWORD=test postgres:16
pytest -v --tb=short
docker stop test-db && docker rm test-db
```

### E2E Verification
```bash
# Start dev server, then run Playwright
npm run dev &
npx playwright test --project=chromium
```

## Examples

### Complete pytest Test Suite
```python
import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from dataclasses import dataclass

@dataclass
class User:
    id: int
    name: str
    email: str
    is_active: bool = True

class UserService:
    def __init__(self, db):
        self.db = db

    async def get_user(self, user_id: int) -> User:
        row = await self.db.fetchrow(
            "SELECT * FROM users WHERE id = $1", user_id
        )
        if not row:
            raise ValueError(f"User {user_id} not found")
        return User(**dict(row))

    async def create_user(self, name: str, email: str) -> User:
        row = await self.db.fetchrow(
            "INSERT INTO users (name, email) VALUES ($1, $2) RETURNING *",
            name, email,
        )
        return User(**dict(row))

@pytest.fixture
def mock_db():
    db = AsyncMock()
    yield db
    # Verify cleanup if needed

@pytest.fixture
def service(mock_db):
    return UserService(mock_db)

# ── Tests ─────────────────────────────────────────────────────
@pytest.mark.asyncio
async def test_get_user_found(service, mock_db):
    mock_db.fetchrow.return_value = {
        "id": 1, "name": "Alice", "email": "alice@test.com", "is_active": True
    }
    user = await service.get_user(1)
    assert user.name == "Alice"
    assert user.email == "alice@test.com"
    mock_db.fetchrow.assert_awaited_once_with("SELECT * FROM users WHERE id = $1", 1)

@pytest.mark.asyncio
async def test_get_user_not_found(service, mock_db):
    mock_db.fetchrow.return_value = None
    with pytest.raises(ValueError, match="User 999 not found"):
        await service.get_user(999)

@pytest.mark.asyncio
async def test_create_user(service, mock_db):
    mock_db.fetchrow.return_value = {
        "id": 2, "name": "Bob", "email": "bob@test.com", "is_active": True
    }
    user = await service.create_user("Bob", "bob@test.com")
    assert user.id == 2
    assert user.name == "Bob"
    mock_db.fetchrow.assert_awaited_once()
```

### Playwright Page Object Model
```typescript
import { test, expect, type Page, type Locator } from '@playwright/test';

class LoginPage {
  readonly page: Page;
  readonly emailInput: Locator;
  readonly passwordInput: Locator;
  readonly submitButton: Locator;
  readonly errorMessage: Locator;

  constructor(page: Page) {
    this.page = page;
    this.emailInput = page.locator('#email');
    this.passwordInput = page.locator('#password');
    this.submitButton = page.locator('button[type="submit"]');
    this.errorMessage = page.locator('.error-message');
  }

  async goto() {
    await this.page.goto('/login');
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
  }
}

test.describe('Login Page', () => {
  let loginPage: LoginPage;

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page);
    await loginPage.goto();
  });

  test('valid login', async ({ page }) => {
    await loginPage.login('user@test.com', 'password123');
    await expect(page).toHaveURL('/dashboard');
  });

  test('invalid credentials', async () => {
    await loginPage.login('wrong@test.com', 'wrongpass');
    await expect(loginPage.errorMessage).toBeVisible();
  });
});
```

### k6 Full Load Test Script
```javascript
import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Counter, Rate, Trend } from 'k6/metrics';

const requests = new Counter('total_requests');
const errors = new Rate('error_rate');
const latency = new Trend('response_latency');

export const options = {
  stages: [
    { duration: '1m', target: 10 },   // warm up
    { duration: '3m', target: 50 },   // ramp to normal load
    { duration: '2m', target: 50 },   // sustain
    { duration: '1m', target: 100 },  // spike
    { duration: '2m', target: 100 },  // sustain spike
    { duration: '1m', target: 0 },    // cool down
  ],
  thresholds: {
    http_req_duration: ['p(95)<300', 'p(99)<1000'],
    error_rate: ['rate<0.05'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

export default function () {
  group('Health Check', () => {
    const res = http.get(`${BASE_URL}/health`);
    check(res, { 'status 200': (r) => r.status === 200 });
    requests.add(1);
    errors.add(res.status !== 200);
    latency.add(res.timings.duration);
  });

  group('List Users', () => {
    const res = http.get(`${BASE_URL}/api/users?page=1&limit=20`);
    check(res, {
      'status 200': (r) => r.status === 200,
      'has users array': (r) => JSON.parse(r.body).length !== undefined,
    });
    requests.add(1);
    errors.add(res.status !== 200);
    latency.add(res.timings.duration);
  });

  sleep(Math.random() * 2 + 1); // 1-3s think time
}
```
