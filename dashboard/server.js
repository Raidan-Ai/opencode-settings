#!/usr/bin/env node
// OpenCode Dashboard Server v2
// Built-in http only — zero npm deps
// Binds 127.0.0.1, port 8877
// Fixes: string-aware JSONC parsing, recursive agent discovery,
//        real MCP + models extraction from config.

const http = require('http');
const fs = require('fs');
const os = require('os');
const path = require('path');

// ── Configurable paths (env-overridable, portable) ─────────────
// Defaults resolve under $HOME so the dashboard works on any
// machine after install.sh / install.ps1 copies it into place.
const PORT = Number(process.env.DASHBOARD_PORT || 8877);
const HOST = process.env.DASHBOARD_HOST || '127.0.0.1';
const DASHBOARD_DIR = process.env.DASHBOARD_DIR || __dirname;
const CONFIG_FILE = process.env.OPENCODE_CONFIG_FILE ||
    path.join(os.homedir(), '.config', 'opencode', 'opencode.jsonc');

// Agents live in ~/.config/opencode/agents (installed layout) or
// ~/.config/opencode/agent (legacy layout) — use whichever has content.
function resolveAgentDir() {
  if (process.env.OPENCODE_AGENT_DIR) return process.env.OPENCODE_AGENT_DIR;
  const candidates = [
    path.join(os.homedir(), '.config', 'opencode', 'agents'),
    path.join(os.homedir(), '.config', 'opencode', 'agent')
  ];
  for (const c of candidates) {
    try { if (fs.readdirSync(c).length > 0) return c; } catch { /* empty */ }
  }
  return candidates[0];
}
const AGENT_DIR = resolveAgentDir();

const SKILLS_DIR = process.env.OPENCODE_SKILLS_DIR ||
    path.join(os.homedir(), '.config', 'opencode', 'skills');

// ── String-aware JSONC comment stripper ─────────────────────────
// Correctly handles "//" and "/* */" that appear inside string literals
// (e.g. URLs like https://...).
function stripComments(jsonStr) {
  let out = '';
  let i = 0;
  let inStr = false;
  let esc = false;
  const n = jsonStr.length;
  while (i < n) {
    const c = jsonStr[i];
    if (inStr) {
      out += c;
      if (esc) esc = false;
      else if (c === '\\') esc = true;
      else if (c === '"') inStr = false;
    } else {
      if (c === '"') { inStr = true; out += c; }
      else if (c === '/' && jsonStr[i + 1] === '/') {
        while (i < n && jsonStr[i] !== '\n') i++;
        out += '\n';
      } else if (c === '/' && jsonStr[i + 1] === '*') {
        i += 2;
        while (i + 1 < n && !(jsonStr[i] === '*' && jsonStr[i + 1] === '/')) i++;
        i++;
      } else out += c;
    }
    i++;
  }
  return out;
}

function safeParse(jsonStr, defaultVal = {}) {
  try {
    return JSON.parse(stripComments(jsonStr));
  } catch {
    return defaultVal;
  }
}

// ── Frontmatter parser ──────────────────────────────────────────
function parseFrontmatter(content) {
  const fm = {};
  const lines = content.split('\n');
  let inFm = false;
  let started = false;
  for (const line of lines) {
    if (line.trim() === '---') {
      if (!started) { inFm = true; started = true; continue; }
      break;
    }
    if (inFm) {
      const m = line.match(/^([\w-]+):\s*(.*)$/);
      if (m) fm[m[1]] = m[2].trim();
    }
  }
  return fm;
}

// ── Recursive agent discovery under AGENT_DIR ───────────────────
function walkMd(dir, base, acc) {
  let entries;
  try { entries = fs.readdirSync(dir, { withFileTypes: true }); }
  catch { return; }
  for (const e of entries) {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) {
      walkMd(full, base, acc);
    } else if (e.isFile() && e.name.endsWith('.md')) {
      const rel = path.relative(base, full);
      const content = fs.readFileSync(full, 'utf-8');
      const fm = parseFrontmatter(content);
      acc.push({
        name: fm.name || path.basename(e.name, '.md'),
        path: rel,
        description: fm.description || '',
        mode: fm.mode || 'subagent',
        model: fm.model || '',
        temperature: fm.temperature !== undefined ? fm.temperature : 0.1,
        raw: content
      });
    }
  }
}

function getAgents() {
  const agents = [];
  try { walkMd(AGENT_DIR, AGENT_DIR, agents); } catch { /* empty */ }
  return agents;
}

// ── Skills discovery ────────────────────────────────────────────
function getSkills() {
  const skills = [];
  try {
    const dirs = fs.readdirSync(SKILLS_DIR, { withFileTypes: true });
    for (const dir of dirs) {
      if (!dir.isDirectory()) continue;
      const skillPath = path.join(SKILLS_DIR, dir.name, 'SKILL.md');
      if (!fs.existsSync(skillPath)) continue;
      const content = fs.readFileSync(skillPath, 'utf-8');
      const fm = parseFrontmatter(content);
      skills.push({
        name: fm.name || dir.name,
        description: fm.description || '',
        path: path.join(dir.name, 'SKILL.md')
      });
    }
    skills.sort((a, b) => a.name.localeCompare(b.name));
  } catch { /* empty */ }
  return skills;
}

// ── Config-backed MCP + models ──────────────────────────────────
function getConfig() {
  try {
    const raw = fs.readFileSync(CONFIG_FILE, 'utf-8');
    return { raw, parsed: safeParse(raw) };
  } catch {
    return { raw: '', parsed: {} };
  }
}

function getMcpEntries() {
  const { parsed } = getConfig();
  const mcps = parsed.mcp || {};
  return Object.entries(mcps).map(([name, v]) => ({
    name,
    type: v.type || (v.command ? 'local' : 'remote'),
    enabled: !!v.enabled,
    url: v.url || '',
    command: Array.isArray(v.command) ? v.command.join(' ') : ''
  }));
}

function getModels() {
  const { parsed } = getConfig();
  const providers = parsed.provider || {};
  const list = [];
  for (const [provider, cfg] of Object.entries(providers)) {
    const models = cfg.models || {};
    for (const modelId of Object.keys(models)) {
      list.push({ provider, model: modelId, label: `${provider}/${modelId}` });
    }
  }
  return list;
}

function getConfigSummary() {
  const { parsed } = getConfig();
  return {
    plugins: Array.isArray(parsed.plugin) ? parsed.plugin.filter(p => typeof p === 'string').concat(
      parsed.plugin.filter(p => Array.isArray(p)).map(p => p[0])
    ) : [],
    disabledProviders: parsed.disabled_providers || [],
    providers: Object.keys(parsed.provider || {}),
    mcpCount: Object.keys(parsed.mcp || {}).length,
    enabledMcp: Object.entries(parsed.mcp || {}).filter(([, v]) => !!v.enabled).map(([k]) => k)
  };
}

// ── HTTP server ─────────────────────────────────────────────────
const server = http.createServer((req, res) => {
  const url = req.url || '/';
  const method = req.method || 'GET';

  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Request-Method', 'GET, PUT, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Cache-Control', 'no-store');

  if (method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  const json = (code, obj) => {
    res.writeHead(code, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(obj));
  };

  if (url === '/api/status') {
    return json(200, { ok: true, version: '2.1.0', uptime: Math.floor(process.uptime()), port: PORT });
  }

  if (url === '/api/agents' && method === 'GET') {
    return json(200, getAgents());
  }

  if (url.startsWith('/api/agent?') && method === 'GET') {
    const qs = new URL(url, 'http://x').searchParams;
    const rel = qs.get('path') || qs.get('name') || '';
    if (!rel || path.isAbsolute(rel) || rel.includes('..')) return json(400, { error: 'Invalid path' });
    const full = path.join(AGENT_DIR, rel);
    if (!fs.existsSync(full) || !full.startsWith(AGENT_DIR)) return json(404, { error: 'Agent not found' });
    const content = fs.readFileSync(full, 'utf-8');
    return json(200, { frontmatter: parseFrontmatter(content), raw: content });
  }

  if (url.startsWith('/api/agent') && method === 'PUT') {
    let body = '';
    req.on('data', c => { body += c; });
    req.on('end', () => {
      try {
        const { path: rel, raw } = JSON.parse(body);
        if (!rel || path.isAbsolute(rel) || rel.includes('..')) return json(400, { error: 'Invalid path' });
        const full = path.join(AGENT_DIR, rel);
        if (!full.startsWith(AGENT_DIR)) return json(400, { error: 'Invalid path' });
        const bak = full + '.bak-dash-' + Date.now();
        if (fs.existsSync(full)) fs.copyFileSync(full, bak);
        fs.writeFileSync(full, raw);
        return json(200, { success: true, backedUpTo: bak });
      } catch (e) {
        return json(400, { error: e.message });
      }
    });
    return;
  }

  if (url === '/api/skills') {
    return json(200, getSkills());
  }

  if (url === '/api/config' && method === 'GET') {
    return json(200, getConfig());
  }

  if (url === '/api/config' && method === 'PUT') {
    let body = '';
    req.on('data', c => { body += c; });
    req.on('end', () => {
      const parsed = safeParse(body);
      if (Object.keys(parsed).length === 0) return json(400, { error: 'Invalid config JSONC' });
      const bak = CONFIG_FILE + '.bak-dash-' + Date.now();
      fs.copyFileSync(CONFIG_FILE, bak);
      fs.writeFileSync(CONFIG_FILE, body);
      return json(200, { success: true, backedUpTo: bak });
    });
    return;
  }

  if (url === '/api/mcp') {
    return json(200, getMcpEntries());
  }

  if (url === '/api/models') {
    return json(200, getModels());
  }

  if (url === '/api/summary') {
    return json(200, getConfigSummary());
  }

  // Static files
  if (url === '/' || url === '/index.html') {
    const p = path.join(DASHBOARD_DIR, 'public', 'index.html');
    if (!fs.existsSync(p)) return json(404, { error: 'index.html missing' });
    res.writeHead(200, { 'Content-Type': 'text/html' });
    return fs.createReadStream(p).pipe(res);
  }

  if (url.startsWith('/public/')) {
    const p = path.join(DASHBOARD_DIR, 'public', url.substring(8));
    if (!fs.existsSync(p) || !p.startsWith(DASHBOARD_DIR)) return json(404, { error: 'Not found' });
    const ext = path.extname(p);
    const ct = ext === '.html' ? 'text/html' :
               ext === '.css' ? 'text/css' :
               ext === '.js' ? 'application/javascript' :
               ext === '.svg' ? 'image/svg+xml' : 'application/octet-stream';
    res.writeHead(200, { 'Content-Type': ct });
    return fs.createReadStream(p).pipe(res);
  }

  return json(404, { error: 'Not Found' });
});

server.listen(PORT, HOST, () => {
  console.log(`OpenCode Dashboard v2 listening at http://${HOST}:${PORT}`);
  console.log(`Agents dir: ${AGENT_DIR}`);
  console.log(`Skills dir: ${SKILLS_DIR}`);
  console.log(`Config:    ${CONFIG_FILE}`);
});

process.on('uncaughtException', (err) => console.error('Uncaught Exception:', err));
process.on('unhandledRejection', (reason) => console.error('Unhandled Rejection:', reason));