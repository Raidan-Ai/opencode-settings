---
name: agent-engineering
description: Agent architecture, design, delegation, multi-agent systems, state management, memory, planning, execution loops, tool design, HITL, and evaluation. Use for building, designing, debugging, or reviewing any autonomous agent system — from single ReAct loops to multi-agent swarms with planning and verification.
---

# Agent Engineering Skill

## Purpose
Provides comprehensive agent engineering capabilities: architecture design (ReAct, planner-executor, supervisor, swarm), multi-agent orchestration, state machines, memory systems, tool design and security, human-in-the-loop patterns, reliability strategies, and evaluation harnesses. Enables building correct, safe, and effective autonomous agent systems.

## When to Activate
- Designing or building any agent system (single or multi-agent)
- Implementing tool-calling loops, ReAct patterns, or planning agents
- Architecting multi-agent coordination (supervisor, swarm, hierarchical)
- Designing agent memory (working, episodic, semantic)
- Implementing human-in-the-loop approval or oversight patterns
- Evaluating agent quality (task completion, tool accuracy, safety)
- Debugging agent loops, tool failures, or coordination issues
- Reviewing agent architecture for reliability and safety

## Core Knowledge

### Agent Architecture Patterns

```
┌─────────────────────────────────────────────────────────────┐
│                    AGENT PATTERNS                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ReAct Loop (single agent)                                 │
│  ┌──────┐    ┌──────┐    ┌──────┐                         │
│  │Think │───→│ Act  │───→│Observe│──┐                     │
│  └──────┘    └──────┘    └──────┘  │                     │
│     ↑                              │                      │
│     └──────────────────────────────┘                      │
│                                                             │
│  Planner-Executor (two-tier)                               │
│  ┌──────────┐     ┌──────────┐                            │
│  │ Planner  │────→│ Executor │──→ Tool calls              │
│  │ (plan)   │←────│ (steps)  │──→ Observations           │
│  └──────────┘     └──────────┘                            │
│                                                             │
│  Supervisor (multi-agent)                                  │
│  ┌────────────┐                                           │
│  │ Supervisor │──→ Worker A ──→ Task result               │
│  │   (routes) │──→ Worker B ──→ Task result               │
│  │            │──→ Worker C ──→ Task result               │
│  └────────────┘                                           │
│                                                             │
│  Swarm (peer-to-peer)                                      │
│  ┌──────┐    ┌──────┐    ┌──────┐                        │
│  │Agent │◄──►│Agent │◄──►│Agent │  (shared state/pool)   │
│  │  A   │    │  B   │    │  C   │                        │
│  └──────┘    └──────┘    └──────┘                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### ReAct Loop
```python
# Core ReAct: Think → Act → Observe → loop
def react_agent(query: str, tools: dict, llm, max_steps: int = 10):
    """Standard ReAct loop for a single agent."""
    messages = [{"role": "user", "content": query}]
    
    for step in range(max_steps):
        # Think: LLM decides what to do
        response = llm.chat(messages, tools=tools)
        
        if not response.tool_calls:
            # LLM decided to answer (no more tool calls)
            return response.content
        
        # Act: Execute each tool call
        messages.append({"role": "assistant", "tool_calls": response.tool_calls})
        
        for call in response.tool_calls:
            result = tools[call.function.name](**call.function.arguments)
            messages.append({
                "role": "tool",
                "tool_call_id": call.id,
                "content": str(result),
            })
    
    return "Max steps reached without final answer."
```

### Planner-Executor Pattern
```python
# Planner generates a plan, executor runs steps sequentially
def planner_executor(query: str, tools: dict, llm):
    """Plan first, then execute each step."""
    
    # Phase 1: Planning
    plan_prompt = f"""
    Given this task: {query}
    Available tools: {list(tools.keys())}
    
    Return a numbered list of steps. Each step: tool_name | arguments | purpose
    """
    plan = llm.chat([{"role": "user", "content": plan_prompt}])
    steps = parse_plan(plan.content)  # [{tool, args, purpose}, ...]
    
    # Phase 2: Execution
    results = []
    for i, step in enumerate(steps):
        print(f"Step {i+1}: {step.purpose}")
        result = tools[step.tool](**step.args)
        results.append({"step": step, "result": result})
        
        # Optional: re-plan if a step fails
        if "error" in str(result).lower():
            # Re-plan from this point
            remaining = steps[i+1:]
            steps = re_plan(query, results, remaining, llm)
    
    return synthesize_answer(query, results, llm)
```

### Supervisor Pattern (Multi-Agent)
```python
# Supervisor routes tasks to specialized workers
def supervisor_agent(query: str, workers: dict, supervisor_llm):
    """Supervisor decides which worker handles the task."""
    
    worker_descriptions = {
        name: w.description for name, w in workers.items()
    }
    
    # Supervisor chooses worker
    route_prompt = f"""
    Task: {query}
    Available workers: {worker_descriptions}
    Return the worker name best suited for this task.
    """
    response = supervisor_llm.chat([{"role": "user", "content": route_prompt}])
    chosen_worker = response.content.strip()
    
    # Dispatch to worker
    result = workers[chosen_worker].execute(query)
    return result
```

### Agent State Machines (LangGraph-style)
```python
from langgraph.graph import StateGraph, END
from typing import TypedDict, Annotated

class AgentState(TypedDict):
    messages: list
    next_step: str
    tool_results: list

# Define nodes (functions that modify state)
def think(state: AgentState) -> AgentState:
    """LLM decides what to do next."""
    response = llm.chat(state["messages"])
    return {**state, "next_step": response.next_action}

def act(state: AgentState) -> AgentState:
    """Execute the chosen tool."""
    result = execute_tool(state["next_step"], state["messages"])
    return {**state, "tool_results": state["tool_results"] + [result]}

def should_continue(state: AgentState) -> str:
    """Edge function: route to next node."""
    if state["next_step"] == "finish":
        return END
    return "act"

# Build graph
graph = StateGraph(AgentState)
graph.add_node("think", think)
graph.add_node("act", act)
graph.set_entry_point("think")
graph.add_conditional_edges("think", should_continue, {"act": "act", END: END})
graph.add_edge("act", "think")  # After acting, think again

app = graph.compile()
result = app.invoke({"messages": [user_msg], "next_step": "", "tool_results": []})
```

### Agent Memory Types

```
┌─────────────────────────────────────────────────────┐
│                 MEMORY ARCHITECTURE                  │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Working Memory                                     │
│  ┌─────────────────────────────────┐               │
│  │ Current context window          │               │
│  │ (conversation messages,         │               │
│  │  recent tool results)           │               │
│  │ Volatile, bounded by tokens     │               │
│  └─────────────────────────────────┘               │
│                                                     │
│  Episodic Memory                                   │
│  ┌─────────────────────────────────┐               │
│  │ Past interactions and outcomes  │               │
│  │ (successes, failures, patterns) │               │
│  │ Stored in vector DB or files    │               │
│  └─────────────────────────────────┘               │
│                                                     │
│  Semantic Memory                                   │
│  ┌─────────────────────────────────┐               │
│  │ Learned facts, rules, patterns  │               │
│  │ (domain knowledge, tool usage)  │               │
│  │ RAG-retrieved at runtime        │               │
│  └─────────────────────────────────┘               │
│                                                     │
└─────────────────────────────────────────────────────┘
```

```python
class AgentMemory:
    """Multi-layer memory system."""
    
    def __init__(self):
        self.working = []      # Current conversation
        self.episodic = []     # Past experiences (vector DB)
        self.semantic = []     # Learned facts (RAG store)
    
    def recall(self, query: str, k: int = 5) -> list:
        """Retrieve relevant memories for current context."""
        # Search episodic memory (past experiences)
        episodic = self.search_episodic(query, k)
        # Search semantic memory (facts/knowledge)
        semantic = self.search_semantic(query, k)
        return episodic + semantic
    
    def store_episode(self, task: str, result: str, success: bool):
        """Record what happened for future reference."""
        self.episodic.append({
            "task": task,
            "result": result,
            "success": success,
            "timestamp": datetime.now(),
        })
        # Embed and store in vector DB for retrieval
        embedding = embed(f"{task}: {result}")
        vector_store.upsert(embedding, metadata={"task": task, "success": success})
```

### Tool Design & Security

```python
# Tool definition pattern (OpenAI function-calling style)
TOOLS = {
    "search_database": {
        "type": "function",
        "function": {
            "name": "search_database",
            "description": "Search the product database by keyword",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "Search query"},
                    "limit": {"type": "integer", "default": 10},
                },
                "required": ["query"],
            },
        },
    }
}

# Security: input validation, output sanitization, rate limiting
def safe_tool(tool_fn, validator=None, rate_limit=None):
    """Wrap a tool with safety checks."""
    call_count = 0
    
    def wrapper(**kwargs):
        nonlocal call_count
        
        # Input validation
        if validator:
            kwargs = validator(kwargs)
        
        # Rate limiting
        if rate_limit:
            call_count += 1
            if call_count > rate_limit:
                return {"error": "Rate limit exceeded"}
        
        # Execute
        result = tool_fn(**kwargs)
        
        # Output sanitization (strip PII, secrets, etc.)
        return sanitize_output(result)
    
    return wrapper
```

### Human-in-the-Loop Patterns

```
┌─────────────────────────────────────────────────────────────┐
│                  HITL APPROVAL PATTERNS                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Gate Approval (blocking)                               │
│     Agent ──→ Request ──→ Human ──→ Approve/Reject         │
│                                      ↓                      │
│                                 Execute or Abort            │
│                                                             │
│  2. Async Notification (non-blocking)                      │
│     Agent ──→ Execute ──→ Notify Human ──→ Feedback         │
│                                  (review after)             │
│                                                             │
│  3. Confidence Threshold                                   │
│     if confidence < 0.7:                                   │
│         ask_human()                                        │
│     else:                                                  │
│         execute()                                          │
│                                                             │
│  4. Rolling Review                                         │
│     Agent does N steps, then pauses for human review       │
│     Human approves batch, then agent continues             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

```python
class HITLAgent:
    """Agent with human-in-the-loop approval gates."""
    
    def __init__(self, llm, tools, approval_threshold: float = 0.7):
        self.llm = llm
        self.tools = tools
        self.threshold = approval_threshold
    
    def execute_with_approval(self, query: str, human_approve):
        """Execute with human approval for high-risk actions."""
        plan = self.plan(query)
        
        for step in plan:
            risk = self.assess_risk(step)
            
            if risk.score >= self.threshold:
                # Ask human for approval
                approved = human_approve(
                    action=step.action,
                    risk=risk,
                    context=step.context,
                )
                if not approved:
                    continue  # Skip this step
            
            result = self.execute_step(step)
            yield {"step": step, "result": result, "approved": risk.score < self.threshold}
```

### Agent Evaluation

```python
# Agent evaluation harness
class AgentEvaluator:
    """Evaluate agent quality across multiple dimensions."""
    
    def evaluate(self, agent, test_cases: list[dict]) -> dict:
        """Run evaluation suite and return metrics."""
        results = {
            "task_completion": [],
            "tool_accuracy": [],
            "efficiency": [],
            "safety": [],
        }
        
        for case in test_cases:
            # Run agent on test case
            output = agent.execute(case["query"])
            
            # Task completion: did it solve the problem?
            results["task_completion"].append(
                self.check_completion(output, case["expected"])
            )
            
            # Tool accuracy: were the right tools called?
            results["tool_accuracy"].append(
                self.check_tool_calls(agent.tool_log, case["expected_tools"])
            )
            
            # Efficiency: how many steps?
            results["efficiency"].append(
                len(agent.tool_log) / case.get("optimal_steps", 1)
            )
            
            # Safety: no forbidden actions?
            results["safety"].append(
                self.check_safety(agent.tool_log, case.get("forbidden", []))
            )
        
        return {k: sum(v)/len(v) for k, v in results.items() if v}
```

### Framework Reference (Knowledge Sources)

| Framework | Best For | Key Concept |
|-----------|----------|-------------|
| **LangGraph** | Stateful multi-agent workflows | State machines with conditional edges |
| **pydantic-ai** | Type-safe agent tools | Pydantic model tool definitions |
| **DSPy** | Optimizing prompts/modules | Signature-based prompt engineering |
| **AutoGen** | Multi-agent conversations | Agent-to-agent chat protocols |
| **CrewAI** | Role-based multi-agent | Task delegation with role specialization |
| **Semantic Kernel** | Enterprise .NET/Python agents | Plugin-based architecture |

## Workflow

### 1. Design Agent Architecture
```bash
# Decision tree for choosing a pattern:
# Single task, single agent? → ReAct loop
# Complex multi-step? → Planner-Executor
# Multiple specialized domains? → Supervisor + Workers
# Cooperative problem-solving? → Swarm
# High-stakes with oversight? → HITL with approval gates
```

### 2. Implement Tool System
```bash
# Define tools with clear schemas
# Validate inputs, sanitize outputs
# Add rate limiting and error handling
# Test tools independently before integrating
```

### 3. Build Memory Layer
```bash
# Working memory: manage context window (summarize old messages)
# Episodic: store past interactions in vector DB
# Semantic: RAG over documentation/knowledge base
```

### 4. Add Safety & HITL
```bash
# Define risk levels for each tool/action
# Implement approval gates for high-risk operations
# Add logging and audit trails
```

### 5. Evaluate & Iterate
```bash
# Create test cases with known correct outcomes
# Run evaluation suite
# Identify failure modes
# Tune prompts, tools, and routing
```

## Tools
```bash
# LangGraph
pip install langgraph

# Pydantic AI
pip install pydantic-ai

# DSPy
pip install dspy

# AutoGen
pip install autogen-agentchat

# CrewAI
pip install crewai

# Semantic Kernel
pip install semantic-kernel

# Vector DB for memory
pip install chromadb qdrant-client

# Evaluation
pip install ragas deep-eval
```

## MCP Requirements
- **Agent Memory MCP**: Persistent memory storage and retrieval
- **Tool Registry MCP**: Dynamic tool discovery and registration
- **Evaluation MCP**: Automated agent testing and benchmarking
- **Audit MCP**: Action logging and compliance tracking

## Best Practices

1. **Start simple**: Single ReAct loop first, add complexity only when needed
2. **Tool granularity**: Each tool does ONE thing well; compose via the agent loop
3. **Explicit schemas**: Every tool parameter has a description and type
4. **Graceful degradation**: Handle tool failures, timeouts, and invalid outputs
5. **Idempotent tools**: Design tools so re-running is safe
6. **Context management**: Summarize old messages to stay within token limits
7. **Observability**: Log every tool call, LLM decision, and state transition
8. **Evaluation-first**: Define success metrics before building the agent
9. **Safety by default**: Assume tools can be misused; validate everything
10. **Human override**: Always provide a way for humans to intervene

## Anti-patterns

- ❌ Infinite loops without max-step limits (runaway agents)
- ❌ Trusting LLM output as tool input without validation (injection)
- ❌ Storing secrets in agent memory or context (leakage)
- ❌ No rate limiting on tool calls (API cost explosion)
- ❌ Single agent doing everything (lost coherence at scale)
- ❌ Skipping evaluation (shipping untested agents)
- ❌ Ignoring tool failures (agent keeps going on errors)
- ❌ Hardcoded routing logic (no adaptability)
- ❌ No audit trail (can't debug or comply)

## Verification

### Architecture Review Checklist
- [ ] Agent pattern chosen appropriate for task complexity
- [ ] Tools have explicit schemas with descriptions
- [ ] Max steps / timeout defined to prevent infinite loops
- [ ] Error handling for all tool calls
- [ ] Memory bounded (context window, storage limits)
- [ ] HITL gates for high-risk actions
- [ ] Evaluation metrics defined and measured
- [ ] Audit logging enabled

### Test Commands
```bash
# Verify agent dependencies are installed
python -c "import langgraph; print('LangGraph OK')"
python -c "import pydantic_ai; print('Pydantic AI OK')"

# Run agent evaluation
python -m pytest tests/agent/ -v

# Check for infinite loop protection
grep -r "max_steps\|max_iterations\|timeout" src/agent/
```

## Examples

### Complete ReAct Agent with Memory
```python
from typing import Callable
import json

class ReactAgent:
    """Full ReAct agent with tool calling and memory."""
    
    def __init__(self, llm, tools: dict[str, Callable], max_steps: int = 10):
        self.llm = llm
        self.tools = tools
        self.max_steps = max_steps
        self.memory = {"working": [], "episodic": []}
    
    def run(self, query: str) -> str:
        self.memory["working"] = [{"role": "user", "content": query}]
        
        for step in range(self.max_steps):
            # Add system prompt with tool descriptions
            tool_descs = json.dumps([
                {"name": name, "doc": fn.__doc__}
                for name, fn in self.tools.items()
            ])
            
            response = self.llm.chat(
                self.memory["working"],
                tools=list(self.tools.values()),
            )
            
            if not response.tool_calls:
                # Final answer
                answer = response.content
                self.memory["episodic"].append({"query": query, "answer": answer})
                return answer
            
            # Execute tools
            self.memory["working"].append({
                "role": "assistant",
                "tool_calls": response.tool_calls,
            })
            
            for call in response.tool_calls:
                result = self.tools[call.name](**call.args)
                self.memory["working"].append({
                    "role": "tool",
                    "tool_call_id": call.id,
                    "content": json.dumps(result),
                })
        
        return "Maximum steps reached without a final answer."
```

### Supervisor with Specialized Workers
```python
def create_supervisor(workers: dict, supervisor_llm):
    """Create a supervisor that routes to specialized workers."""
    
    worker_list = "\n".join([
        f"- {name}: {w.description}" for name, w in workers.items()
    ])
    
    def supervisor(query: str) -> str:
        # Route
        route_prompt = f"""Route this task to the best worker.
        
Task: {query}
Workers:
{worker_list}

Return ONLY the worker name."""
        
        response = supervisor_llm.chat([{"role": "user", "content": route_prompt}])
        worker_name = response.content.strip()
        
        if worker_name not in workers:
            return f"Unknown worker: {worker_name}"
        
        # Execute
        result = workers[worker_name].execute(query)
        return result
    
    return supervisor
```
