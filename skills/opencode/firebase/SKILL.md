---
name: firebase
description: Firebase development on Google's app platform. Covers Firebase CLI, Authentication, Cloud Firestore, Cloud Storage, Cloud Functions, Hosting, Security Rules, and the Emulator Suite, plus the Firebase MCP server. Activate for any Firebase project, auth, database, storage, functions, or hosting task.
---

# Firebase Skill

## Purpose

Provides Firebase development capabilities across Authentication, Cloud Firestore (+ SQL Connect), Cloud Storage, Cloud Functions, Hosting, Security Rules, and the Emulator Suite for local development. Enables building and operating full-stack apps using the Firebase CLI and the official Firebase MCP server.

## When to Activate

- Setting up or managing Firebase projects
- Implementing Firebase Authentication (email, OAuth providers, anonymous, custom tokens)
- Modeling and querying data in Cloud Firestore
- Managing Cloud Storage buckets and files, including security rules
- Deploying and debugging Cloud Functions (v1/v2)
- Deploying web apps to Firebase Hosting or App Hosting
- Writing and testing Security Rules
- Running the Emulator Suite for local development and automated tests
- Using the Firebase MCP server for agent-assisted project/data work

## Core Knowledge

### Firebase MCP Server (verified official)

- **Ships in the Firebase CLI** — not a separate package.
- **Command**: `npx -y firebase-tools@latest mcp` (stdio)
- **Docs**: https://firebase.google.com/docs/cli/mcp-server · **Source**: firebase/firebase-tools `src/mcp`
- **Auth**: same credentials as the Firebase CLI — logged-in user (`firebase login`) or Application Default Credentials (ADC). **No separate API key.**
- **Options**:
  - `--dir ABSOLUTE_DIR_PATH` — absolute path of the dir containing `firebase.json` to set project context (if omitted, `get_project_directory`/`set_project_directory` tools are offered).
  - `--only FEATURE_1,FEATURE_2` — limit exposed tools, e.g. `--only auth,firestore,storage`.

```jsonc
"firebase-mcp": {
  "type": "local",
  "command": ["npx", "-y", "firebase-tools@latest", "mcp"],
  "enabled": false
}
```

- Start with `"enabled": false`; flight-check in a live session before enabling.
- Firebase agent skills can be installed alongside to teach models how to use MCP tools effectively.

### Firebase CLI

```bash
firebase --version
firebase login           # authenticate (browser)
firebase login:ci        # generate a refresh token for CI (use as secret)
firebase use --add       # select/add project alias
firebase init            # scaffold (choose features)
firebase deploy          # deploy selected features
firebase serve           # local preview (hosting/functions)
firebase emulators:start # run emulator suite
```

### Core Services

- **Authentication**: email/password, OAuth providers (Google, GitHub, etc.), phone, anonymous, custom tokens, sign-in links.
- **Cloud Firestore**: NoSQL document DB, real-time sync, subcollections, queries, transactions, offline persistence; plus **SQL Connect** for relational data.
- **Cloud Storage**: object/file storage for images, media, user uploads; governed by Security Rules.
- **Cloud Functions**: v1 (Node) / v2 (Cloud Run-based) event-driven + HTTPS functions.
- **Hosting**: static + SSR hosting, rich rewrites, headers, redirects.
- **Security Rules**: declarative access control for Firestore + Storage.

### Security Rules (example — Firestore)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
    match /posts/{id} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if resource.data.uid == request.auth.uid;
    }
  }
}
```

### Emulator Suite

```bash
firebase emulators:start                 # all emulators
firebase emulators:start --only firestore,auth
firebase emulators:exec "npm test"       # run tests against emulators
# Uses Firestore/Storage emulator + Auth emulator; no cloud cost or side effects.
```

## Workflow

1. **Authenticate**: `firebase login` (interactive) or `firebase login:ci` (CI token).
2. **Init**: `firebase init` to scaffold features and generate `firebase.json` + `.firebaserc`.
3. **Develop locally** with the Emulator Suite to iterate without cloud cost or data side effects.
4. **Model data**: design Firestore collections/subcollections with security rules in mind (deny by default, then allow).
5. **Test security rules** using the rules emulator (`@firebase/rules-unit-testing` or `firebase emulators:exec`).
6. **Deploy** with `firebase deploy` scoped to the changed features (`--only functions,hosting`).
7. **Verify**: exercise the deployed endpoints, check Functions logs, confirm Security Rules enforce access.
8. **Monitor**: use Firebase console + Cloud functions logs; enable error tracking.

## Tools

```bash
firebase login / login:ci
firebase init / use / projects:list
firebase deploy [--only functions,hosting,firestore:rules,storage]
firebase serve / emulators:start
firebase firestore:indexes
firebase functions:log / functions:shell
npx -y firebase-tools@latest mcp      # MCP (stdio)
```

### MCP Requirements

- Local server: `npx -y firebase-tools@latest mcp`, stdio.
- Optional args: `--dir <abs path>`, `--only auth,firestore,storage`.
- Auth = existing CLI/ADC credentials; no API key.

## Best Practices

1. Deny-by-default Security Rules; grant the minimum access pattern (`read`/`write`/`create`/`update`/`delete` granularity).
2. Validate all rules against the emulator before deploying to production.
3. Use the Emulator Suite for local dev and CI tests; isolate test projects in CI.
4. Keep Functions small and idempotent (event handlers may be retried).
5. Use `--only` targeting to limit deploys and blast radius.
6. Store secrets (API keys, tokens) in environment config / Secret Manager, never in source.
7. Set `firebase.json` ignored project aliases; keep `.firebaserc` committed for team consistency.
8. Enable App Check for production auth to protect your backend resources.

## Anti-patterns

- ❌ Committing `.firebase` local state, service-account JSON keys, or `login:ci` tokens to git.
- ❌ Writing permissive rules like `allow read, write: if true` for real user data.
- ❌ Developing/deploying directly against production without emulators or staging.
- ❌ Deploying untested Security Rules that lock users out or expose data.
- ❌ Keeping large binary files in Firestore instead of Cloud Storage.
- ❌ Ignoring Security Rules for Storage (files left publicly readable/writable).
- ❌ Hardcoding project config or secrets array in app code.

## Verification

```bash
# CLI authenticated + project selected
firebase login:list
firebase projects:list
firebase use <project>

# List current rules / indexes
firebase firestore:indexes

# Check function logs
firebase functions:log --open

# Emulator parity: start suite, run rule tests, confirm no rule violations
firebase emulators:exec "npm test"
```

- Before/after changing Security Rules, run `firebase emulators:exec "npm test"` to prove allow/deny behavior.
- After deploys, exercise read/write paths for both authenticated and anonymous/unauthenticated users in the console.

## Examples

### Initialize a new project

```bash
firebase login
firebase init
# Select: Hosting, Firestore, Functions, Storage, Emulators
firebase use --add
```

### Run Firestore rules tests against the emulator

```bash
firebase emulators:exec "npm test" --only firestore
```

### Deploy only what changed

```bash
firebase deploy --only functions:onUserCreated
firebase deploy --only hosting
firebase deploy --only firestore:rules
```

### Deploy a backend for a web app

```bash
firebase init hosting
firebase login
firebase deploy --only hosting
# Visit the Hosting URL and verify the site + rewrites to Functions work.
```
