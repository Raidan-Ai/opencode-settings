---
name: project-detection
description: Scan a project to determine which skills and agents to activate. Map project signals (package.json, tsconfig, pyproject, requirements, docs, config) to a skill activation matrix.
---

# Project Detection Skill

## Purpose

Automatically detect the type of project present in a given directory and recommend which OpenCode skills and agents to activate. This enables the orchestrator to select the appropriate tools for the task at hand without manual configuration.

## When to activate

- When the orchestrator starts and needs to determine which skills to load
- When a new project directory is encountered
- When switching between different project types within a session
- As a preprocessing step before task planning or implementation

## Core knowledge — Detection table: FILE SIGNALS → ACTIVATED SKILLS

| Signal (file present) | Detected Project Type | Activated Skills |
| --- | --- | --- |
| `package.json` has `"next"` | Next.js App Router project | frontend, nextjs, react, typescript, ai-chat (if Vercel AI SDK) |
| `package.json` has `"@langchain"` \|\| `"langchain"` \|\| `"llamaindex"` \|\| `"chromadb"` \|\| `"qdrant_client"` | RAG backend | data-engineer, scraping-engineer, milvus-engineer |
| Any `pyproject.toml` has `"langchain"` \|\| `"llamaindex"` \|\| `"chromadb"` \|\| `"qdrant_client"` | Python RAG project | data-engineer, scraping-engineer, milvus-engineer |
| `docker-compose.yml` present | Dockerized project | docker |
| `Dockerfile` present | Docker project (build/runtime) | docker |
| `requirements.txt` has `"fastapi"` | FastAPI backend | backend |
| `requirements.txt` has `"flask"` \|\| `"django"` | Python web backend | backend |
| `Icecast.xml` present \|\| `liquidsoap` scripts | Broadcast/audio streaming | broadcast-radio |
| `package.json` has `"@ffmpeg-installer"` \|\| `"fluent-ffmpeg"` | FFmpeg processing | ffmpeg-engineer |
| `.nvmrc` present \|\| `package.json` present | Node.js toolchain | frontend, nextjs, react, typescript |
| `terraform` files (`.tf`) present | Infrastructure as code | devops |
| `kubernetes` yaml (`.yaml`, `.yml`) present | K8s deployment | kubernetes (if present in skills list) |
| `.gitpod.yml` \|\| `.github/workflows/` | CI/CD environment | devops, task-management |
| `go.mod` present | Go project | backend (go) |
| `Cargo.toml` present | Rust project | backend (rust) |
| `pyproject.toml` present (no RAG signals) | Python project | data-engineer |
| `README.md` mentions `"AI"` \|\| `"ML"` \|\| `"neural"` | AI-enhanced project | ai-architect (if applicable) |
| `slang` \|\| `slangc` files | Slang shader compiler | (context-specific) |

## Detection Priority & Conflict Resolution

1. **Most specific signals first**: RAG signals (langchain, chroma, qdrant) take priority over general Python signals
2. **One project type per detection**: If multiple signals match, prioritize based on the above table order
3. **Fallback**: If no specific signals match, default to generic `backend` and `frontend` skills
4. **Explicit override**: If `OPENCODE_SKILL_OVERRIDE` env var is set, respect it

## Workflow

### Step 1: Scan the project directory
Look for signal files in this order:

1. Check `package.json` (Node.js/TypeScript projects)
2. Check `pyproject.toml` or `requirements.txt` (Python projects)
3. Check Docker signals (`docker-compose.yml`, `Dockerfile`)
4. Check broadcast signals (`Icecast.xml`, liquidsoap)
5. Check infrastructure signals (`terraform`, `k8s yaml`)
6. Check language-specific signals (`go.mod`, `Cargo.toml`)

### Step 2: Match signals to skills
For each signal found, consult the detection table and add the corresponding skills to the activation set.

### Step 3: Resolve conflicts
Apply priority rules to resolve any overlapping signals.

### Step 4: Return activation matrix
Output a map of detected project type → list of activated skills.

### Step 5: Orchestrator loads corresponding skills
The orchestrator uses this matrix to automatically load the appropriate skills and agents.

## Best practices

- **Scan comprehensively**: Check all possible signal files, not just the most obvious one
- **Prioritize specificity**: RAG/ML signals should override general language signals
- **Document new signals**: If adding a new project type, update the detection table
- **Test with real projects**: Verify detection works on known projects before deploying
- **Cache results**: Project detection results can be cached for the session to avoid re-scanning

## Anti-patterns

- ❌ Assuming `package.json` always means a web app (could be a CLI tool or library)
- ❌ Overlooking `pyproject.toml` in favor of `requirements.txt` (modern Python projects use pyproject)
- ❌ Activating too many skills indiscriminately (keep the activation set minimal)
- ❌ Ignoring conflict resolution (multiple signals may match different project types)
- ❌ Not checking for RAG-specific signals in Python projects

## Verification

Run detection on sample directories to verify correctness:

### Example 1: Next.js + AI app
```bash
# Directory: /path/to/my-nextjs-app/
# Contains: package.json with "next", possibly "langchain" dependency
result = detect_project("/path/to/my-nextjs-app/")
# Expected: { project: "nextjs-ai-app", skills: ["frontend", "nextjs", "react", "typescript", "ai-chat"] }
```

### Example 2: RAG backend
```bash
# Directory: /path/to/rag-bot/
# Contains: pyproject.toml with "langchain" dependency
result = detect_project("/path/to/rag-bot/")
# Expected: { project: "rag-backend", skills: ["data-engineer", "scraping-engineer", "milvus-engineer"] }
```

### Example 3: Radio playout system
```bash
# Directory: /path/to/radio-playout/
# Contains: Icecast.xml config, liquidsoap scripts
result = detect_project("/path/to/radio-playout/")
# Expected: { project: "radio-playout", skills: ["broadcast-radio", "liquidsoap-engineer"] }
```

## Examples

### Detection on sample directories

**Directory: `/home/ecs-user/projects/my-web-app/`**
- `package.json` exists with `"next"` and `"react"` dependencies
- No `pyproject.toml`, no `docker-compose.yml`
- **Detection result**: `nextjs` project → activate: `frontend, nextjs, react, typescript`

**Directory: `/home/ecs-user/projects/data-pipeline/`**
- `pyproject.toml` exists with `"chromadb"` and `"langchain"` 
- No `package.json`
- **Detection result**: `rag-backend` project → activate: `data-engineer, scraping-engineer, milvus-engineer`

**Directory: `/home/ecs-user/projects/radio-show/`**
- `Icecast.xml` present with streaming configuration
- `liquidsoap` script files present
- No `package.json`, no `pyproject.toml`
- **Detection result**: `radio-playout` project → activate: `broadcast-radio`

## Integration

The project-detection skill is invoked by the orchestrator at startup or when a new directory is provided. The output format is:

```json
{
  "project_type": "nextjs-ai-app|rag-backend|radio-playout|generic|unknown",
  "skills": ["skill1", "skill2", ...],
  "confidence": 0.95
}
```

The orchestrator uses this to:
1. Load the appropriate skill files
2. Select the appropriate agent subagents
3. Configure the task planning context
4. Set up the verification pipeline

## Extension

To add a new project type detection:

1. Add the signal file to one of the signal categories above
2. Add a row to the detection table with the appropriate activated skills
3. Update the priority rules if needed
4. Add verification examples
5. Test with a real project directory