---
name: security
description: Provides security engineering expertise covering application security (AppSec), OWASP Top 10, secure coding, API security, authentication/authorization hardening, dependency and container security, secret detection (gitleaks), static analysis (semgrep), prompt injection defense, LLM security, and AI agent security. Activate for any security review, secure coding, secret scanning, SAST, or AI/LLM security task.
---

# Security Skill

## Purpose
Provides security engineering expertise covering application security (AppSec), OWASP Top 10, secure coding practices, API security, authentication/authorization hardening, dependency and container security, secret detection (gitleaks), static analysis (semgrep), prompt injection defense, LLM security, and AI agent security. Enables building secure-by-default systems across the full stack.

## When to Activate
- Performing security reviews or audits on code
- Implementing authentication or authorization systems
- Scanning for secrets, vulnerabilities, or insecure patterns
- Defending against prompt injection or LLM-based attacks
- Hardening Docker containers or CI/CD pipelines
- Setting up SAST/DAST or dependency scanning
- Designing RBAC, API key management, or token-based auth
- Reviewing code for OWASP Top 10 vulnerabilities

## Core Knowledge

### OWASP Top 10 (2021) Summary
```
1. A01: Broken Access Control      → Missing function-level auth, IDOR, privilege escalation
2. A02: Cryptographic Failures     → Weak algorithms, plaintext storage, missing TLS
3. A03: Injection                  → SQL/NoSQL/LDAP/OS command injection
4. A04: Insecure Design            → Missing threat modeling, insecure business logic
5. A05: Security Misconfiguration  → Default creds, verbose errors, unnecessary features
6. A06: Vulnerable Components      → Outdated libraries with known CVEs
7. A07: Authentication Failures    → Weak passwords, missing MFA, session fixation
8. A08: Data Integrity Failures    → Insecure deserialization, unsigned updates
9. A09: Logging & Monitoring Failures → No audit trail, undetected breaches
10. A10: SSRF                      → Unvalidated server-side requests
```

### Secure Coding Patterns
```python
# ❌ INSECURE: SQL injection
query = f"SELECT * FROM users WHERE id = {user_input}"
cursor.execute(query)

# ✅ SECURE: Parameterized query
cursor.execute("SELECT * FROM users WHERE id = %s", (user_input,))

# ❌ INSECURE: Command injection
os.system(f"ping {user_input}")

# ✅ SECURE: Use subprocess with list args
subprocess.run(["ping", "-c", "1", user_input], capture_output=True)

# ❌ INSECURE: Path traversal
with open(f"/data/{user_input}", "r") as f:

# ✅ SECURE: Validate and sanitize path
from pathlib import Path
safe_path = Path("/data") / user_input
if not safe_path.resolve().is_relative_to(Path("/data").resolve()):
    raise ValueError("Path traversal detected")
with open(safe_path, "r") as f:

# ❌ INSECURE: XSS in template
element.innerHTML = userInput

# ✅ SECURE: Text content (auto-escapes)
element.textContent = userInput
```

### API Security Checklist
```
Authentication:
  □ API key or token in Authorization header (never query string)
  □ Token expiration and refresh mechanism
  □ Rate limiting per key/IP
  □ Input validation on all endpoints
  □ CORS: whitelist specific origins, never *

Authorization:
  □ RBAC or ABAC enforcement on every endpoint
  □ Resource-level permissions (IDOR prevention)
  □ Principle of least privilege for service accounts

Transport:
  □ TLS 1.3 enforced (HSTS header)
  □ Certificate pinning for mobile clients

Logging:
  □ All auth events logged (success + failure)
  □ No secrets in logs
  □ Audit trail for sensitive operations
```

### Secret Detection with gitleaks
```bash
# Install
go install github.com/gitleaks/gitleaks/v8@latest
# Or: brew install gitleaks

# Scan git history for secrets
gitleaks detect --source . --verbose

# Scan specific commits
gitleaks detect --source . --log-opts="--since=2024-01-01"

# Scan with custom rules
gitleaks detect --source . --config .gitleaks.toml

# Protect mode (pre-commit hook — blocks commits with secrets)
gitleaks protect --source . --staged
```

### gitleaks Configuration
```toml
# .gitleaks.toml
title = "gitleaks config"

[allowlist]
  description = "Global allowlist"
  paths = [
    '''vendor/''',
    '''node_modules/''',
    '''\.test\.js$''',
  ]

[[rules]]
  id = "aws-access-key"
  description = "AWS Access Key"
  regex = '''(A3T[A-Z0-9]|AKIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}'''
  tags = ["key", "AWS"]

[[rules]]
  id = "github-token"
  description = "GitHub Token"
  regex = '''ghp_[A-Za-z0-9]{36}'''
  tags = ["key", "GitHub"]

[[rules]]
  id = "generic-api-key"
  description = "Generic API Key"
  regex = '''(?i)(api[_-]?key|apikey|secret[_-]?key|access[_-]?key)[\s]*[:=][\s]*['"]?([A-Za-z0-9\-_]{20,})['"]?'''
  tags = ["key", "generic"]

[[rules]]
  id = "private-key"
  description = "Private Key"
  regex = '''-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----'''
  tags = ["key", "private"]
```

### Static Analysis with semgrep
```bash
# Install
pip install semgrep
# Or: brew install semgrep

# Scan with default rules
semgrep scan

# Scan with specific rule set
semgrep scan --config p/default          # General best practices
semgrep scan --config p/owasp-top-ten    # OWASP Top 10
semgrep scan --config p/python           # Python-specific
semgrep scan --config p/typescript       # TypeScript-specific
semgrep scan --config p/security-audit   # Security audit

# Scan with custom rules
semgrep scan --config .semgrep/

# Auto-fix findings
semgrep scan --config p/default --autofix

# Output as JSON
semgrep scan --config p/default --json --output results.json

# CI mode (exit code 1 if findings)
semgrep scan --config p/default --error
```

### semgrep Custom Rule Example
```yaml
# .semgrep/security-audit.yml
rules:
  - id: hardcoded-secret
    patterns:
      - pattern-either:
          - pattern: $VAR = "..."
          - pattern: $VAR = '...'
      - metavariable-regex:
          metavariable: $VAR
          regex: (?i)(password|secret|api_key|token|private_key)
    message: "Possible hardcoded secret in variable '$VAR'. Use environment variables or a secrets manager."
    languages: [python, javascript, typescript, go]
    severity: ERROR
    metadata:
      category: security
      cwe: "CWE-798: Use of Hard-coded Credentials"

  - id: sql-injection-fstring
    patterns:
      - pattern-either:
          - pattern: |
              $CONN.execute(f"...{$VAR}...")
          - pattern: |
              $CONN.execute("...".format($VAR))
    message: "Possible SQL injection via string formatting. Use parameterized queries."
    languages: [python]
    severity: ERROR
    metadata:
      category: security
      cwe: "CWE-89: SQL Injection"

  - id: unsafe-deserialization
    pattern: pickle.loads(...)
    message: "Unsafe deserialization with pickle. Use JSON or a safe format."
    languages: [python]
    severity: WARNING
    metadata:
      category: security
      cwe: "CWE-502: Deserialization of Untrusted Data"
```

### Prompt Injection Defense
```
Attack Types:
  Direct:     "Ignore previous instructions and..."
  Indirect:   Malicious content in retrieved documents (RAG poisoning)
  Jailbreak:  DAN, role-play, hypothetical scenarios
  Extraction: "Repeat your system prompt"

Defense Layers (Defense in Depth):

1. INPUT VALIDATION & SANITIZATION
   - Allowlist expected input patterns
   - Reject inputs containing instruction-like tokens
   - Limit input length
   - Strip or escape special characters

2. SYSTEM PROMPT HARDENING
   - Never rely solely on system prompts for security
   - Use "Never" statements (not "Please don't")
   - Isolate instructions from user content with delimiters
   - Add adversarial examples in training/fine-tuning

3. OUTPUT VALIDATION
   - Check output doesn't contain sensitive data
   - Validate against expected format/schema
   - Log outputs for audit
   - Filter responses that mirror attack patterns

4. ARCHITECTURAL CONTROLS
   - Separate system context from user content
   - Use separate LLM calls for different privilege levels
   - Implement rate limiting per user/session
   - Sandbox execution environments
```

### LLM Security Patterns
```python
# Allowlist-based input validation
import re

ALLOWED_TOPICS = {"weather", "news", "math", "translation"}
BLOCKED_PATTERNS = [
    r"ignore\s+(previous|all|above)\s+instructions",
    r"you\s+are\s+now\s+(?:DAN|a\s+different)",
    r"system\s*prompt",
    r"repeat\s+(your|the)\s+(system|initial)\s+(prompt|instruction)",
    r"(?:jailbreak|bypass|override)",
]

def validate_user_input(text: str) -> tuple[bool, str]:
    """Validate user input against prompt injection patterns."""
    text_lower = text.lower()

    for pattern in BLOCKED_PATTERNS:
        if re.search(pattern, text_lower):
            return False, "Input contains potentially manipulative content"

    if len(text) > 10000:
        return False, "Input exceeds maximum length"

    return True, ""

# Output validation
SENSITIVE_PATTERNS = [
    r"(?i)(api[_-]?key|secret|password|token)\s*[:=]\s*\S+",
    r"-----BEGIN.*PRIVATE KEY-----",
    r"(?:SELECT|INSERT|UPDATE|DELETE)\s+.*FROM",
]

def validate_output(text: str) -> tuple[bool, str]:
    """Check output doesn't leak sensitive information."""
    for pattern in SENSITIVE_PATTERNS:
        if re.search(pattern, text):
            return False, "Output may contain sensitive information"
    return True, ""
```

### Agent Security Model
```
Agent Trust Boundaries:

┌─────────────────────────────────────────────┐
│  System Layer (HIGH TRUST)                   │
│  - System prompt                            │
│  - Tool definitions                         │
│  - Configuration                             │
├─────────────────────────────────────────────┤
│  Retrieval Layer (MEDIUM TRUST)              │
│  - RAG documents                            │
│  - Web search results                       │
│  - External APIs                             │
│  ⚠ Treat as potentially adversarial         │
├─────────────────────────────────────────────┤
│  User Layer (LOW TRUST)                     │
│  - User messages                            │
│  - Uploaded files                           │
│  - Form inputs                              │
│  🔴 Always validate and sanitize             │
└─────────────────────────────────────────────┘

Principle: Never trust data from lower layers to override higher layers.
```

### Dependency Security
```bash
# Python
pip-audit                          # Audit installed packages
safety check                       # Check against vulnerability DB
pip install pip-audit

# Node.js
npm audit                          # Built-in audit
npm audit fix                      # Auto-fix vulnerabilities
npx better-npm-audit audit         # Enhanced audit reporting

# Go
govulncheck ./...                  # Official Go vulnerability checker

# General: keep dependencies minimal
# Audit transitive dependencies
# Pin exact versions in lock files
```

### Container Security
```dockerfile
# ✅ Secure Dockerfile patterns
FROM python:3.12-slim AS builder

# Non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
RUN chown -R appuser:appuser /app

USER appuser

# Read-only rootfs + no-new-privileges
# docker run --read-only --security-opt=no-new-privileges ...
```

```bash
# Container scanning with Trivy
trivy image myapp:latest
trivy image --severity HIGH,CRITICAL myapp:latest

# Docker Bench Security (CIS benchmark)
docker run --rm -it --net host --pid host --userns host --cap-add audit_control \
  -v /var/lib:/var/lib -v /var/run/docker.sock:/var/run/docker.sock \
  -v /etc:/etc docker/docker-bench-security
```

## Workflow

### 1. Security Review Checklist
```
Code Review:
  □ No hardcoded secrets or credentials
  □ Input validation on all external inputs
  □ Parameterized queries (no string concatenation for SQL)
  □ Proper error handling (no stack traces to users)
  □ Authentication/authorization checks on endpoints
  □ Rate limiting implemented
  □ CORS configured correctly
  □ Dependencies up to date (npm audit / pip-audit)
  □ No unsafe deserialization (pickle, yaml.load without SafeLoader)
  □ Proper TLS/HTTPS configuration

Infrastructure:
  □ Containers run as non-root
  □ Read-only filesystem where possible
  □ Resource limits set (CPU, memory)
  □ Secrets managed externally (not in env vars or code)
  □ Network segmentation (internal services not exposed)
  □ Logging and monitoring enabled
```

### 2. Pre-Commit Security Setup
```bash
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks

  - repo: https://github.com/semgrep/semgrep
    rev: v1.56.0
    hooks:
      - id: semgrep
        args: ['--config', 'p/default', '--error']
```

### 3. CI/CD Security Gates
```yaml
# .github/workflows/security.yml
name: Security Scanning
on: [push, pull_request]

jobs:
  secret-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  sast:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: semgrep/semgrep-action@v1
        with:
          config: p/default p/owasp-top-ten

  dependency-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: npm ci
      - run: npm audit --audit-level=high

  container-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ github.sha }}
          severity: 'CRITICAL,HIGH'
          exit-code: '1'
```

## Tools

### Package Installation
```bash
# Semgrep (SAST)
pip install semgrep
# Or: brew install semgrep

# Gitleaks (secret detection)
go install github.com/gitleaks/gitleaks/v8@latest
# Or: brew install gitleaks

# Trivy (container/vulnerability scanning)
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Safety (Python dependency audit)
pip install safety

# pip-audit (Python dependency audit)
pip install pip-audit

# govulncheck (Go vulnerability check)
go install golang.org/x/vuln/cmd/govulncheck@latest

# npm audit (Node.js — built-in)
# No installation needed

# pre-commit hooks
pip install pre-commit
```

### Command-Line Utilities
```bash
# Semgrep
semgrep --version
semgrep scan --config p/default
semgrep scan --config .semgrep/ --error

# Gitleaks
gitleaks --version
gitleaks detect --source . --verbose
gitleaks protect --source . --staged

# Trivy
trivy --version
trivy fs .
trivy image myapp:latest --severity HIGH,CRITICAL

# Dependency auditing
pip-audit
safety check
npm audit
govulncheck ./...

# Docker security
docker scan myapp:latest  # Docker's built-in scan (uses Snyk)
```

## MCP Requirements
Recommended MCP servers for security work:
- **Semgrep MCP**: SAST scanning driven directly from the agent session
- **GitHub MCP**: read code, trigger scans, review findings
- **Vulnerability management MCP** (e.g., Dependency-Track): ingest and query findings
- **gitleaks MCP**: secret-scan working trees and staged changes

```json
{
  "mcpServers": {
    "semgrep": {
      "command": "semgrep",
      "args": ["mcp"],
      "description": "Semgrep MCP server for security scanning and code analysis"
    }
  }
}
```

## Best Practices

1. **Defense in depth**: Never rely on a single security control; layer input validation, auth checks, and output encoding
2. **Least privilege**: Every component gets only the permissions it needs; service accounts, container users, and database roles should be scoped tightly
3. **Secrets in code = compromised**: Use git-secrets, gitleaks pre-commit hooks, and secrets managers (Vault, AWS Secrets Manager)
4. **Validate all input**: Treat every external input as hostile; validate type, length, range, and format
5. **Parameterized queries always**: Never construct SQL from user input; use ORM parameterization or prepared statements
6. **Keep dependencies updated**: Run `npm audit`/`pip-audit` in CI; use Dependabot or Renovate for automated updates
7. **Secure defaults**: Ship with security enabled, not as an opt-in; use `--read-only`, `--no-new-privileges` by default
8. **Log security events**: Auth failures, permission denials, and input validation failures should be logged with context
9. **LLM input/output validation**: Never trust LLM user inputs or outputs blindly; validate both directions
10. **Regular security reviews**: Schedule periodic threat modeling and code security reviews

## Anti-patterns

- ❌ Storing secrets in environment variables committed to git
- ❌ Relying only on client-side validation (bypass trivial)
- ❌ Using `pickle.loads()` on untrusted data (remote code execution)
- ❌ Trusting system prompts as the only security boundary for LLMs
- ❌ Running containers as root in production
- ❌ Ignoring npm audit / pip-audit warnings
- ❌ Logging sensitive data (passwords, tokens, PII) in plaintext logs
- ❌ Using `yaml.load()` without `SafeLoader` (arbitrary code execution)
- ❌ No rate limiting on authentication endpoints (brute force)
- ❌ Security as an afterthought — bolted on instead of built in

## Verification

### Unit Tests
```bash
# Semgrep verification
semgrep --version
semgrep scan --config p/default --error --dry-run 2>&1 | head -5

# Gitleaks verification
gitleaks --version
gitleaks detect --source . --verbose 2>&1 | head -10

# Trivy verification
trivy --version
trivy image --severity CRITICAL alpine:3.19 2>&1 | head -10

# Pre-commit hooks verification
pre-commit install
pre-commit run --all-files

# Dependency audit
pip-audit --dry-run 2>&1 | head -10
npm audit --json 2>&1 | head -5
```

### Integration Tests
- CI pipeline blocks merge on CRITICAL vulnerabilities
- Pre-commit hook catches secrets before they enter git history
- Container scan blocks deployment of images with HIGH/CRITICAL CVEs
- Semgrep findings logged as PR comments for code review

## Examples

### Secure FastAPI Endpoint with Auth + Validation
```python
from fastapi import FastAPI, HTTPException, Depends, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, Field, validator
import re

app = FastAPI()
security = HTTPBearer()

class OrderRequest(BaseModel):
    item_id: str = Field(..., min_length=1, max_length=100)
    quantity: int = Field(..., ge=1, le=1000)
    notes: str = Field(default="", max_length=500)

    @validator("item_id")
    def validate_item_id(cls, v):
        if not re.match(r"^[a-zA-Z0-9_-]+$", v):
            raise ValueError("item_id contains invalid characters")
        return v

    @validator("notes")
    def validate_notes(cls, v):
        # Block prompt injection patterns in user text
        injection_patterns = [
            r"ignore\s+previous", r"system\s+prompt",
            r"you\s+are\s+now", r"<script",
        ]
        for pattern in injection_patterns:
            if re.search(pattern, v, re.IGNORECASE):
                raise ValueError("Notes contain disallowed content")
        return v

@app.post("/api/v1/orders")
async def create_order(
    order: OrderRequest,
    credentials: HTTPAuthorizationCredentials = Security(security),
):
    # Verify token
    user = await verify_token(credentials.credentials)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid token")

    # Check authorization (resource-level)
    if not await user_can_create_order(user):
        raise HTTPException(status_code=403, detail="Insufficient permissions")

    # Process with parameterized queries
    order_id = await db.execute(
        "INSERT INTO orders (user_id, item_id, quantity) VALUES (%s, %s, %s) RETURNING id",
        (user.id, order.item_id, order.quantity)
    )

    return {"order_id": order_id, "status": "created"}
```

### Complete Security Scanning Pipeline
```yaml
# Makefile targets for security
.PHONY: security-scan security-fix

security-scan:
	@echo "=== Secret Detection ==="
	gitleaks detect --source . --verbose
	@echo ""
	@echo "=== SAST (Semgrep) ==="
	semgrep scan --config p/default --config .semgrep/ --error
	@echo ""
	@echo "=== Dependency Audit ==="
	pip-audit || true
	npm audit || true
	@echo ""
	@echo "=== Container Scan ==="
	docker build -t security-test:scan .
	trivy image --severity HIGH,CRITICAL security-test:scan
	@echo ""
	@echo "✅ Security scan complete"

security-fix:
	semgrep scan --config p/default --autofix
	pip-audit --fix || true
	npm audit fix || true
```

### Prompt Injection Defense Middleware
```python
import re
from typing import Optional

class PromptInjectionGuard:
    """Defense layer for LLM-based applications."""

    BLOCKED_PATTERNS = [
        # Direct instruction overrides
        r"ignore\s+(all|any|previous|above|earlier)\s+(instructions?|prompts?|rules?)",
        r"you\s+are\s+now\s+(?:DAN|in\s+developer\s+mode|unfiltered)",
        r"disregard\s+(all|your|previous)",
        # System prompt extraction
        r"(?:repeat|show|print|reveal|output)\s+(?:your|the)\s+(?:system|initial|original)\s+(?:prompt|instructions?)",
        # Role hijacking
        r"(?:act|respond|behave)\s+as\s+(?:if|though)\s+you\s+(?:have|are|were)\s+no\s+restrictions",
        # Injection delimiters
        r"---+\s*END\s+OF\s+(?:SYSTEM|INSTRUCTIONS?)\s*---+",
        r"\[INST\]|\[/INST\]|<<SYS>>|<</SYS>>",
    ]

    def __init__(self, extra_patterns: Optional[list[str]] = None):
        self.compiled = [
            re.compile(p, re.IGNORECASE) for p in self.BLOCKED_PATTERNS
        ]
        if extra_patterns:
            self.compiled.extend(re.compile(p, re.IGNORECASE) for p in extra_patterns)

    def check(self, text: str) -> tuple[bool, Optional[str]]:
        """Returns (is_safe, reason)."""
        for pattern in self.compiled:
            match = pattern.search(text)
            if match:
                return False, f"Blocked: matched pattern '{match.group()}'"
        if len(text) > 50000:
            return False, "Input exceeds maximum allowed length"
        return True, None

# Usage
guard = PromptInjectionGuard()
is_safe, reason = guard.check(user_message)
if not is_safe:
    return {"error": "Your message could not be processed", "reason": reason}
```
