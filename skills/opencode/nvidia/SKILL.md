---
name: nvidia
description: NVIDIA platform development including NIM microservices, CUDA optimization, cuOpt routing, RAG AI Blueprints, GPU management, and NVIDIA Agent Skills integration. Activate for NVIDIA GPU operations, NIM deployment, CUDA development, NVIDIA container tooling, or when installing NVIDIA skills into coding agents.
---

# NVIDIA Skill

## Purpose
Provides comprehensive NVIDIA platform development: NIM microservices, CUDA optimization, cuOpt routing, RAG AI Blueprints, GPU management, and NVIDIA Agent Skills integration for AI-assisted GPU-accelerated workflows.

## When to Activate
- Working with NVIDIA NIM microservices or the Integrate API
- Deploying or optimizing CUDA/C++ GPU code
- Using NVIDIA cuOpt for route optimization
- Building RAG systems with NVIDIA AI Blueprints
- Installing NVIDIA skills into coding agents
- Managing GPU resources (nvidia-smi, container runtime)

## Core Knowledge

### NVIDIA NIM / Integrate API
- **Endpoint**: `https://integrate.api.nvidia.com/v1`
- **Auth**: API key with `nvapi-*` prefix
- **Protocol**: OpenAI-compatible — drop-in replacement for OpenAI SDK calls

```python
from openai import OpenAI

client = OpenAI(
    base_url="https://integrate.api.nvidia.com/v1",
    api_key="nvapi-..."
)
resp = client.chat.completions.create(
    model="nvidia/llama-3.3-70b-instruct",
    messages=[{"role": "user", "content": "Explain GPU memory hierarchy"}],
)
print(resp.choices[0].message.content)
```

```bash
curl -s https://integrate.api.nvidia.com/v1/chat/completions \
  -H "Authorization: Bearer nvapi-..." -H "Content-Type: application/json" \
  -d '{"model": "nvidia/llama-3.3-70b-instruct",
       "messages": [{"role": "user", "content": "Hello, NIM!"}]}'
```

### NVIDIA Agent Skills (skills catalog — NOT MCP servers)
- **Repo**: github.com/NVIDIA/skills · **Docs**: docs.nvidia.com/skills
- **Categories**: Physical AI, robotics, simulation, CUDA-X, RAG (many Apache-2.0)
- **Install**: `npx skills@latest add nvidia/skills` (requires skills CLI ≥ v1.5.16)

```bash
npx skills add nvidia/skills --skill cuda-optimization   # specific skill
npx skills list                                          # verify installed
npx skills update                                        # keep current
```

### GPU Management
```bash
nvidia-smi                                                     # status
nvidia-smi --query-gpu=name,temperature.gpu,utilization.gpu,memory.used,memory.total --format=csv
watch -n 1 nvidia-smi                                          # live view
nvcc --version                                                 # CUDA toolkit version
```

### NIM Container Deployment
```bash
docker pull nvcr.io/nim/meta/llama-3.1-8b-instruct:latest
docker run -d --gpus all -p 8000:8000 \
  -e NVIDIA_API_KEY=nvapi-... \
  nvcr.io/nim/meta/llama-3.1-8b-instruct:latest
curl http://localhost:8000/v1/models                          # smoke test
```

### RAG AI Blueprints & cuOpt
```python
# RAG with NVIDIA components (langchain integration)
from langchain_nvidia_ai_endpoints import NVIDIAEmbeddings, ChatNVIDIA
embedder = NVIDIAEmbeddings(model="nvidia/nv-embedqa-e5-v5", model_type="passage")
vectors = embedder.embed_documents(["NVIDIA makes GPUs", "CUDA is a parallel platform"])
llm = ChatNVIDIA(model="nvidia/llama-3.3-70b-instruct",
                 base_url="https://integrate.api.nvidia.com/v1")

# cuOpt — vehicle routing:  pip install nvidia-cuopt
import nvidia_cuopt
from nvidia_cuopt import cuOptService
solution = cuOptService.get_optimized_routes(
    cost_matrix=[[...]], num_vehicles=5, depot=0)
```

## Workflow
```bash
# 1. Verify environment
nvidia-smi && nvcc --version
npx skills add nvidia/skills                      # install NVIDIA agent skills

# 2. Configure NIM API
export NVIDIA_API_KEY="nvapi-..."
curl -s https://integrate.api.nvidia.com/v1/models \
  -H "Authorization: Bearer $NVIDIA_API_KEY" | jq   # list models

# 3. Iterate with inference
# (OpenAI-compatible chat completions — see Core Knowledge above)
```

## Tools
```bash
nvidia-smi                        # GPU status/utilization
nvcc --version                    # CUDA compiler
npx skills list                   # NVIDIA agent skills inventory
curl <NIM base>/v1/models         # NIM endpoint probe
```

## MCP Requirements

### NVIDIA NIM (OpenAI-compatible, not native MCP)
- **Endpoint**: `https://integrate.api.nvidia.com/v1`, API key `nvapi-*` in `Authorization: Bearer`
- **Note**: NIM exposes an OpenAI-compatible API, not native MCP. Use the OpenAI SDK directly, or wrap it for MCP clients.

### opencode.jsonc Config Block
```jsonc
// NIM is reached via the OpenAI-compatible API from code (OpenAI SDK).
// It is NOT a native MCP server; no MCP entry is required.
// For NVIDIA agent capabilities, install skills instead:
//   npx skills@latest add nvidia/skills
"nvidia-nim": {
  "type": "remote",
  "url": "https://integrate.api.nvidia.com/v1",
  "enabled": false
}
```

## Best Practices
1. **Key security**: Keep `nvapi-*` keys in env vars/secrets managers — never in code
2. **NIM managed first**: Prefer `integrate.api.nvidia.com`; self-host only for latency/data residency
3. **Model selection**: Match model to task — 70B-class for reasoning, smaller for speed/cost
4. **Monitor utilization**: <30% GPU utilization suggests over-provisioning
5. **Batch inference** to improve GPU utilization and reduce request cost
6. **Skills over MCP**: NVIDIA ships agent skills (instruction sets) — use `npx skills add`, not MCP config

## Anti-patterns
- ❌ Committing `nvapi-*` keys to repos (rotate immediately if leaked)
- ❌ Running NIM containers without GPU passthrough (`--gpus all`) — they fail
- ❌ Ignoring VRAM limits (check `nvidia-smi` before sizing workloads)
- ❌ Treating NVIDIA skills as MCP servers (they are instruction sets)
- ❌ Using 70B-class models for trivial tasks (wasteful cost/latency)

## Verification
```bash
nvidia-smi                                   # driver + GPU present
nvcc --version                               # CUDA toolkit works
curl -s https://integrate.api.nvidia.com/v1/models \
  -H "Authorization: Bearer $NVIDIA_API_KEY" | jq '.data[0].id'   # API key valid
npx skills list                              # agent skills installed
```

## Examples
```bash
# Quick NIM inference test
curl -s https://integrate.api.nvidia.com/v1/chat/completions \
  -H "Authorization: Bearer $NVIDIA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "nvidia/llama-3.3-70b-instruct",
       "messages": [{"role": "system", "content": "You are a CUDA expert."},
                    {"role": "user", "content": "Optimize this kernel for shared memory"}],
       "temperature": 0.2}' | jq '.choices[0].message.content'
```