# Pi Setup Guide — Global Model Routing Configuration

This guide helps Pi users configure a multi-tier model routing strategy for cost-efficient code generation. Once set up, the routing applies **globally to all Pi projects**.

## Recommended Global Config

### 1. Default Orchestrator Model

**`~/.pi/agent/settings.json`**

Set the default session model to a capable reasoning model that can orchestrate sub-agents:

```json
{
  "defaultProvider": "openrouter",
  "defaultModel": "deepseek/deepseek-v4-pro",
  "defaultThinkingLevel": "high",
  "skills": ["~/.agents/skills"]
}
```

**Cost rationale:** The orchestrator handles low-volume, high-value work (planning, architecture, dispatch). A mid-cost reasoning model like V4 Pro ($0.44/M in) provides strong reasoning without the expense of top-tier models.

**Alternatives:**
| Model | Cost/M in | Trade-off |
|-------|-----------|-----------|
| `deepseek/deepseek-v4-pro` | $0.44 | Good cost/reasoning balance |
| `~anthropic/claude-sonnet-latest` | $2.00 | Better reasoning, more expensive |
| `~anthropic/claude-opus-latest` | $5.00 | Best reasoning, expensive — use as deep-think only |

### 2. Model Overrides (Optional)

**`~/.pi/agent/models.json`**

Only needed if you want entries for models not auto-discovered by Pi:

```json
{
  "providers": {
    "openrouter": {
      "modelOverrides": {
        "openrouter/free": {
          "name": "OpenRouter: Free Model Router",
          "reasoning": false,
          "input": ["text"],
          "contextWindow": 128000,
          "maxTokens": 8192,
          "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 }
        }
      }
    }
  }
}
```

### 3. Presets — Model Routing Tiers

**`~/.pi/agent/presets.json`**

Define presets for each role in the routing hierarchy. Switch with `/preset <name>` or `Ctrl+Shift+U` to cycle.

```json
{
  "$schema": "./presets.schema.json",
  "_note": "Multi-tier model routing via OpenRouter.",

  "plan": {
    "provider": "openrouter",
    "model": "moonshotai/kimi-k3",
    "thinkingLevel": "high",
    "tools": ["read", "grep", "find", "ls"],
    "instructions": "You are in PLANNING / ARCHITECTURE mode... [read-only]"
  },

  "code": {
    "provider": "openrouter",
    "model": "qwen/qwen3-coder-next",
    "thinkingLevel": "medium",
    "tools": ["read", "bash", "edit", "write", "grep", "find", "ls"],
    "instructions": "You are in CODING / IMPLEMENTATION mode..."
  },

  "search": {
    "provider": "openrouter",
    "model": "deepseek/deepseek-v4-flash",
    "thinkingLevel": "off",
    "tools": ["read", "grep", "find", "ls"],
    "instructions": "You are in SEARCH / EXPLORATION mode... [read-only]"
  },

  "worker": {
    "provider": "openrouter",
    "model": "qwen/qwen3-coder-next",
    "thinkingLevel": "low",
    "tools": ["read", "bash", "edit", "write", "grep", "find", "ls"],
    "instructions": "You are a WORKER agent. Complete focused sub-tasks precisely."
  },

  "deep-think": {
    "provider": "openrouter",
    "model": "moonshotai/kimi-k3",
    "thinkingLevel": "max",
    "tools": ["read", "grep", "find", "ls"],
    "instructions": "Reserved for the hardest problems. Do NOT edit files."
  }
}
```

#### Model Options by Tier

| Tier | Role | Recommended | Cost/M in | Alternative |
|------|------|-------------|-----------|-------------|
| Orchestrator | Planning, dispatch | `moonshotai/kimi-k3` | $0.60 | `deepseek/deepseek-v4-pro` ($0.44) |
| Worker | Implementation | `qwen/qwen3-coder-next` | $0.11 | `z-ai/glm-4.7` ($0.40) |
| Explorer | Search, file reads | `deepseek/deepseek-v4-flash` | $0.14 | `openai/gpt-5-nano` ($0.05) |
| Deep-think | Circuit breaker | `anthropic/claude-opus-4.8` | $5.00 | `~anthropic/claude-opus-latest` ($5) |

### 4. Global Agent Rules

**`~/.pi/agent/AGENTS.md`**

Document the delegation strategy so Pi applies it consistently:

```markdown
# Pi Global Agent Configuration

Multi-tier model routing strategy for cost-efficient code generation.

Orchestrator (default): deepseek/deepseek-v4-pro  — planning, architecture, dispatch
Worker (sub-agents):    deepseek/deepseek-v4-flash — implementation, test writing
Explorer (search):      openai/gpt-5-nano          — grep/read/lint
Deep-think (rare):      anthropic/claude-opus-4.8  — hardest problems only

Presets: /plan, /code, /search, /worker, /deep-think

The build skill (`/build`) follows the escalation ladder:
1. 2 attempts with worker model
2. 2 attempts with escalated model
3. Circuit breaker → Opus 4.8 or halt

skills: ["~/.agents/skills"]
```

### 5. Verify Installation

After configuring, verify Pi loads your settings:

```bash
# Check default model
pi -e "print default model"  # Should show your orchestrator model

# Test preset switching
pi --preset search -e "grep -r 'class.*Handler' src/ | head -3"

# Check presets are recognized
pi --preset plan -e "read specs/*.md"
```

## Sub-Agent Routing in Pi — pi-subagents Extension

Presets route the *parent session*. Routing *sub-agents* requires the [`pi-subagents`](https://github.com/nicobailon/pi-subagents) extension:

```bash
pi install npm:pi-subagents
```

### Agents: workflow personas + builtin gap-fillers

The workflow's own agents live in `.agents/agents/` (canonical, model-agnostic) and are auto-discovered per project: `planner`, `backend-developer`, `frontend-developer`, `code-reviewer`, `code-debugger`, `security-reviewer`, `critic`, `frontend-design-validator`, `context-document-optimizer`, `software-design-expert-review`.

The extension's builtins fill roles the workflow does not define — keep these enabled:

| Builtin | Role it fills |
|---------|---------------|
| `scout` | Fast codebase recon (Claude Code's built-in Explore equivalent) |
| `oracle` | Advisory second opinion before risky decisions |
| `researcher` | Web/docs research (needs `pi install npm:pi-web-access`) |
| `context-builder` | Heavy context-gathering pass before planning |

Disable the overlapping builtins so the fleet stays unambiguous: `worker` (≈ backend/frontend-developer), `reviewer` (≈ code-reviewer), `delegate`, `advisor`.

### Settings

Add a `subagents` block to `~/.pi/agent/settings.json` (agent name → model, with `fallbackModels` for provider failures and hard caps against runaway fan-out):

```json
"subagents": {
  "defaultModel": "qwen/qwen3-coder-next",
  "globalConcurrencyLimit": 6,
  "maxSubagentDepth": 2,
  "maxSubagentSpawnsPerSession": 30,
  "agentOverrides": {
    "planner":            { "model": "moonshotai/kimi-k3", "thinking": "high" },
    "oracle":             { "model": "moonshotai/kimi-k3", "thinking": "high" },
    "backend-developer":  { "model": "qwen/qwen3-coder-next", "fallbackModels": ["z-ai/glm-4.7"] },
    "frontend-developer": { "model": "qwen/qwen3-coder-next", "fallbackModels": ["z-ai/glm-4.7"] },
    "code-debugger":      { "model": "qwen/qwen3-coder-next", "fallbackModels": ["z-ai/glm-4.7"] },
    "code-reviewer":      { "model": "z-ai/glm-4.7" },
    "security-reviewer":  { "model": "z-ai/glm-4.7" },
    "software-design-expert-review": { "model": "z-ai/glm-4.7" },
    "critic":             { "model": "z-ai/glm-4.7" },
    "scout":              { "model": "deepseek/deepseek-v4-flash", "thinking": "off" },
    "context-builder":    { "model": "deepseek/deepseek-v4-flash" },
    "context-document-optimizer": { "model": "deepseek/deepseek-v4-flash" },
    "researcher":         { "model": "deepseek/deepseek-v4-flash" },
    "worker":   { "disabled": true },
    "reviewer": { "disabled": true },
    "delegate": { "disabled": true },
    "advisor":  { "disabled": true }
  }
}
```

Dispatch is natural language ("Have backend-developer implement this task") or the `subagent` tool. Do NOT pass per-call model params — `agentOverrides` resolves each agent's model automatically, and `fallbackModels` absorbs provider errors/rate-limits.

### Tier rationale

| Tier | Model | $/M in | Why |
|------|-------|--------|-----|
| Plan / oracle / circuit breaker | `moonshotai/kimi-k3` | $0.60 | 1M context, strong reasoning, thinking levels low/high/max |
| Build / debug | `qwen/qwen3-coder-next` | $0.11 | Purpose-built for coding agents, cheapest of the strong coder tier |
| Review / escalation | `z-ai/glm-4.7` | $0.40 | Flagship reasoning + programming; different model family than the builder — catches builder blind spots |
| Scout / context / docs | `deepseek/deepseek-v4-flash` | $0.14 | 1M context, very cheap, fast |

Budget alternative for the build tier: `z-ai/glm-4.7-flash` ($0.06/M in) if cost pressure beats quality headroom.

## How Build Skill Sub-Agent Routing Works

The `/build` skill's Model Routing table assigns explicit model IDs to each sub-agent role:

| Role | Agent | OpenRouter Model ID | Cost/M in |
|------|-------|--------------------|-----------|
| Planning / circuit breaker | `planner` | `moonshotai/kimi-k3` | $0.60 |
| Second opinion | `oracle` | `moonshotai/kimi-k3` | $0.60 |
| Coding agents | `backend-developer`, `frontend-developer` | `qwen/qwen3-coder-next` | $0.11 |
| Debugger (1-2) | `code-debugger` | `qwen/qwen3-coder-next` | $0.11 |
| Debugger (3-4) | `code-debugger` | `z-ai/glm-4.7` | $0.40 |
| Reviews | `code-reviewer`, `security-reviewer`, `software-design-expert-review`, `critic` | `z-ai/glm-4.7` | $0.40 |
| Search / recon | `scout` | `deepseek/deepseek-v4-flash` | $0.14 |

On Claude Code, these are passed to the Agent tool when dispatching sub-agents. On Pi, they are resolved from `subagents.agentOverrides` (see previous section). Each sub-agent runs independently with its own model and context.

**Escalation:** If a debugger fails 2 times with the build-tier model (`qwen3-coder-next`), it escalates to the review-tier model (`glm-4.7`) for 2 more attempts. If all 4 fail, the circuit breaker trips: `planner` on `kimi-k3` analyzes every attempt before the user is asked to intervene.

## Cost Estimate

| Build phase | Model | Tokens | Cost |
|------------|-------|--------|------|
| 4 coding agents | V4 Flash | ~100K | ~$0.01 |
| 2 code reviews | V4 Pro | ~50K | ~$0.03 |
| 5 search calls | GPT-5 Nano | ~25K | ~$0.001 |
| **Build total** | | | **~$0.04** |

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Preset not found | Model ID doesn't exist on OpenRouter | Check `curl -s https://openrouter.ai/api/v1/models \| jq '.data[].id' \| grep <model-id>` |
| Sub-agent fails with "model not found" | Build skill references a model not in Pi's registry | Set the model in `models.json` as an override |
| High costs | Using Opus for everything | Switch default model to V4 Pro, only use deep-think preset for hard problems |
| Slow responses | Thinking level too high on cheap models | Lower thinkingLevel to "low" or "off" for worker/search presets |
