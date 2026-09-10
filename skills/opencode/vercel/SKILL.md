---
name: vercel
description: Vercel deployment platform for frontend and edge applications. Covers vercel CLI, projects, deployments, preview URLs, environment variables, edge functions, Vercel AI SDK, and monorepo configuration. Activate for any Vercel deployment, project setup, preview, or environment-variable task.
---

# Vercel Skill

## Purpose

Provides Vercel deployment platform capabilities: project setup, deployments (production + preview), alias/preview URLs, environment variables, edge functions (Edge Middleware / Vercel Edge), serverless function scaling, and Vercel AI SDK integration. Enables reliable, Git-integrated frontend and full-stack deployment.

## When to Activate

- Deploying a frontend (Next.js, React, etc.) or full-stack app to Vercel
- Managing projects, deployments, domains, and aliases
- Configuring environment variables per environment (production/preview/development)
- Writing Edge Middleware or serverless API routes
- Setting up Git-based CI/CD (auto-deploy on push/PR)
- Using the Vercel MCP server for agent-assisted project/deployment management
- Integrating the Vercel AI SDK (streaming, tool use)

## Core Knowledge

### Vercel MCP (verified official)

- **Type**: remote MCP with **OAuth** — no token pasting required; public tools work unauthenticated, authenticated tools (projects, deployments, analytics) trigger OAuth.
- **Remote URL**: `https://mcp.vercel.com`
- **Docs**: https://vercel.com/docs/mcp/vercel-mcp (tools ref: `/docs/agent-resources/vercel-mcp/tools`)
- **Install to other clients**: `npx -y add-mcp https://mcp.vercel.com` (`-g` for global)

```jsonc
"vercel": {
  "type": "remote",
  "url": "https://mcp.vercel.com",
  "enabled": false
}
```

- Start with `"enabled": false`; enable after confirming the OAuth flow works in your environment.

### Vercel CLI

```bash
vercel --version
vercel login          # authenticate (GitHub/GitLab/Bitbucket/email)
vercel link           # link local project to a Vercel project
vercel dev            # run locally (mirrors prod runtime incl. edge/serverless)
vercel env pull .env.local   # pull env vars
```

### Deployment Lifecycle

```bash
# Deploy from a linked directory (prompts for production vs preview)
vercel
# Or explicit:
vercel --prod                 # production deployment
vercel --preview              # preview deployment
vercel promote                # promote a preview build to production
vercel ls                     # list deployments for current project
vercel inspect <url>          # details of a deployment
vercel rollback               # rollback to previous production deployment
```

### Projects & Environment

```bash
vercel projects ls
vercel project rm <name>
vercel env add <name> production|preview|development   # add env var, then enter value
vercel env rm <name> <env>
vercel env ls
```

### Configuration (vercel.json)

```json
{
  "framework": "nextjs",
  "buildCommand": "npm run build",
  "outputDirectory": ".next",
  "regions": ["iad1", "hkg1"],
  "functions": {
    "api/*.js": { "maxDuration": 30 }
  }
}
```

### Vercel AI SDK (basics)

```ts
import { generateText } from 'ai';
import { openai } from '@ai-sdk/openai';

const { text } = await generateText({
  model: openai('gpt-4o'),
  prompt: 'Hello',
});
```

## Workflow

1. **Authenticate**: `vercel login` or rely on MCP OAuth; never hardcode tokens.
2. **Link/init**: `vercel link` to associate the local directory with a Vercel project.
3. **Set env vars** per environment via `vercel env add` (values stay server-side, not committed).
4. **Develop** with `vercel dev` for local prod parity (edge + serverless).
5. **Deploy**: `vercel` for a preview (auto URLs per PR) or `vercel --prod` for production.
6. **Configure CI**: Git integration auto-deploys on push; use preview URLs for automated checks.
7. **Review**: inspect deployment logs, check edge/function runtime, verify env var presence.
8. **Protect production**: require approval or use preview-protection for sensitive teams.

## Tools

```bash
vercel --version
vercel login
vercel link
vercel dev
vercel / vercel --prod
vercel ls / vercel inspect / vercel promote / vercel rollback
vercel env add|rm|ls|pull
vercel projects ls
npx -y add-mcp https://mcp.vercel.com   # register MCP with another client
```

### MCP Requirements

- Remote server: type `remote`, url `https://mcp.vercel.com`.
- Uses OAuth; no API token needed in config.
- Keep `"enabled": false` until you verify the OAuth session works.

## Best Practices

1. Use `vercel dev` for local parity to catch edge/serverless issues pre-deploy.
2. Store env var names in `.env.example`; keep secrets only in `vercel env add` (never commit `.env`).
3. Scope env vars to the correct environment (production/preview/development).
4. Prefer Git-based (CI/deploy-hooks) over manual CLI deploys for production.
5. Use `vercel.json` `regions` to deploy to the right data centers for latency/cost.
6. Set function `maxDuration` and memory limits realistically.
7. Roll back via `vercel rollback` instead of redeploying manually for quick recovery.
8. In monorepos, configure the correct `rootDirectory` / `outputDirectory` per project.

## Anti-patterns

- ❌ Committing `.env` or production secrets to git.
- ❌ Untracked framework/build settings (missing `vercel.json`) causing wrong builds.
- ❌ Hardcoding environment-specific values in code instead of using env vars.
- ❌ Ignoring Hydration/framework mismatch errors.
- ❌ Deploying from a local machine for production without CI review/approval.
- ❌ Overlooking edge/function cold starts and `maxDuration` timeouts for heavy routes.
- ❌ Mixing multiple projects/deployments in one directory without `rootDirectory` config.

## Verification

```bash
# CLI authenticated and linked
vercel whoami
vercel link --yes

# Verify env var present for an environment
vercel env ls

# List & inspect deployments
vercel ls
vercel inspect <deployment-url>

# Local parity build
vercel dev
# Then hit the local URL and verify the route responds correctly.

# MCP: after enabling, list projects via the MCP tool and confirm auth.
```

- After a deploy, visit the deployment preview URL and production URL to confirm the route/functions behave identically.
- Check Vercel dashboard logs for edge/function errors.

## Examples

### Deploy a Next.js app to production

```bash
vercel login
vercel link
vercel env add DATABASE_URL production
vercel env add NEXT_PUBLIC_API_URL production
vercel --prod
```

### Pull env vars for local development

```bash
vercel link
vercel env pull .env.local
# .env.local is gitignored — never commit
```

### Edge Middleware example (Next.js)

```ts
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const auth = request.cookies.get('token');
  if (!auth && request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
  return NextResponse.next();
}

export const config = { matcher: ['/dashboard/:path*'] };
```
