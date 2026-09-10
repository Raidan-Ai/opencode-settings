<div dir="rtl" lang="ar">

# 📂 إعدادات OpenCode — نسخة احتياطية شاملة

نسخة احتياطية كاملة من إعدادات OpenCode — العوامل (Agents)، المهارات (Skills)، الإضافات (Plugins)، الأوامر (Commands)، وملفات السياق (Context).

> **🔒 ضمان الأمان:** جميع بيانات الاعتماد في هذا المستودع عبارة عن نصوص بديلة (`{env:VAR}` أو `your_..._here`). تتواجد الرموز الحقيقية فقط في بيئتك المحلية / ملفات `.env` المُستبعدة من Git.

---

## 📋 محتويات المستودع

| المجلد | المحتوى | العدد |
|--------|---------|-------|
| 🤖 `agents/` | تعريفات العوامل الأساسية والمساعدين | 50 ملف |
| 🛠️ `skills/opencode/` | مهارات OpenCode (Cloudflare, Frontend, Security, ...) | 47 مجلد |
| 🛠️ `skills/nvidia/` | مهارات NVIDIA (cuOpt, DOCA, Jetson, TAO, DeepStream, ...) | 363 مجلد |
| ⚡ `plugins/` | إضافات OpenCode (notif.ts) | 1 ملف |
| 📜 `commands/` | أوامر شريط الأوامر المخصصة | 12 ملف |
| 📝 `context/` | السياق والمعايير وسير العمل | 176 ملف |
| ⚙️ `config/` | ملفات الإعدادات الإضافية (agent-metadata.json) | 1 ملف |
| 🔧 `tools/` | أدوات مخصصة (.load env, gemini) | 2 ملف |

> **الإجمالي: 5,614 ملف** — جاهز للنسخ والتثبيت على أي جهاز.

---

## 🖥️ المتطلبات

| المتطلب | الحد الأدنى | ملاحظات |
|---------|------------|---------|
| **Node.js** | 20+ | لعملية تثبيت الإضافات |
| **Git** | أي إصدار | لاستنساخ المستودع |
| **OpenCode CLI** | أحدث إصدار | لتشغيل العوامل والمهارات |
| **نظام التشغيل** | Linux / macOS / Windows | متوافق مع الأنظمة الثلاثة |

---

## ⚡ التثبيت السريع

### 🐧 Linux / macOS

```bash
# 1. استنساخ المستودع
git clone git@github.com:Raidan-Ai/opencode-settings.git ~/opencode-settings
cd ~/opencode-settings

# 2. تشغيل سكربت التثبيت
bash install.sh
```

### 🪟 Windows (PowerShell — كمسؤول)

```powershell
# 1. استنساخ المستودع
git clone git@github.com:Raidan-Ai/opencode-settings.git $HOME\opencode-settings
cd $HOME\opencode-settings

# 2. تشغيل سكربت التثبيت (كمسؤول)
.\install.ps1
```

---

## 🔧 التثبيت اليدوي

### Linux / macOS

```bash
# إنشاء مجلد الإعدادات
mkdir -p ~/.config/opencode

# نسخ العوامل والأدوات
cp -r agents commands config context plugins skills tools ~/.config/opencode/
cp opencode.jsonc env.example package.json ~/.config/opencode/

# نسخ مهارات NVIDIA
mkdir -p ~/.agents
cp -r skills/nvidia/* ~/.agents/skills/
cp skill-lock.json ~/.agents/.skill-lock.json

# تجهيز ملف البيئة
cp ~/.config/opencode/env.example ~/.config/opencode/.env
# ✏️ حرر ملف .env بإعداداتك الخاصة
```

### Windows (PowerShell)

```powershell
# إنشاء مجلد الإعدادات
New-Item -ItemType Directory -Force $HOME\.config\opencode

# نسخ العوامل والأدوات
Copy-Item -Recurse agents,commands,config,context,plugins,skills,tools $HOME\.config\opencode\
Copy-Item opencode.jsonc,env.example,package.json $HOME\.config\opencode\

# نسخ مهارات NVIDIA
New-Item -ItemType Directory -Force $HOME\.agents
Copy-Item -Recurse skills\nvidia\* $HOME\.agents\skills\
Copy-Item skill-lock.json $HOME\.agents\.skill-lock.json

# تجهيز ملف البيئة
Copy-Item $HOME\.config\opencode\env.example $HOME\.config\opencode\.env
# ✏️ حرر ملف .env بإعداداتك الخاصة
```

---

## 🗂️ هيكل المشروع

```
codedata/
├── opencode.jsonc        # الإعدادات الرئيسية (مُنظّف — بدون أسرار)
├── env.example           # قالب متغيرات البيئة
├── package.json          # تبعيات الإضافات
├── skill-lock.json       # سجل مهارات Skill Registry
├── install.sh            # سكربت التثبيت (Linux / macOS)
├── install.ps1           # سكربت التثبيت (Windows)
├── README.md             # التوثيق بالإنجليزية
├── README-ar.md          # التوثيق بالعربية ← أنت هنا
├── agents/               # تعريفات العوامل
│   ├── core/             # العوامل الأساسية
│   ├── content/          # عوامل المحتوى
│   ├── meta/             # عوامل الإدارة
│   ├── subagents/        # المساعدون المتخصصون
│   └── data/             # عوامل البيانات
├── skills/
│   ├── opencode/         # مهارات OpenCode (47 مجلد)
│   └── nvidia/           # مهارات NVIDIA (363 مجلد)
├── commands/             # أوامر مخصصة
├── context/              # ملفات السياق والمعايير
├── config/               # إعدادات_agent-metadata.json
├── plugins/              # إضافات TypeScript
└── tools/                # أدوات مخصصة (env, gemini)
```

---

## 🔑 المتغيرات المطلوبة

جميع الأسرار مُشارة إليها عبر `{env:VAR}` في `opencode.jsonc`. قم بإنشاء ملف `.env` وتعبئته:

| المتغّر | الغرض |
|---------|-------|
| `GITHUB_TOKEN` | خادم GitHub MCP (رمز PAT بنطاق `repo`) |
| `NOTION_TOKEN` | خادم Notion MCP (رمز Bearer) |
| `COMPOSIO_API_KEY` | خادم Composio MCP (مفتاح المستهلك) |
| `RAIDAN_BASE_URL` | عنوان Raidan المتوافق مع OpenAI (مثل بوابة Cloudflare tunnel الخاصة بك) |
| `DATABASE_URL` | PostgreSQL (معطّل افتراضيًا) |
| `REDIS_URL` | Redis (معطّل افتراضيًا) |
| `MILVUS_ADDR` | Milvus Vector DB (معطّل افتراضيًا) |
| `AWS_REGION` / `AWS_PROFILE` | AWS MCP (معطّل افتراضيًا) |
| `GEMINI_API_KEY` | أداة Gemini |
| `TELEGRAM_BOT_TOKEN` / `TELEGRAM_CHAT_ID` | إضافة Telegram (اختياري) |

---

## 🛡️ ملاحظات الأمان

- ⚠️ **لا تقم بتشفير هذا المستودع** — تحتوي ملفات العوامل على اتفاقيات ملكية خاصة.
- 📋 فحص الأسرار قبل الدفع:
  ```bash
  grep -rlnE "ghp_|ntn_|sk-[A-Za-z0-9]|AKIA[0-9A-Z]|Bearer [A-Za-z0-9_-]{20,}" . --exclude-dir=node_modules
  ```
- 🚫 ملفات `.env` و`node_modules` مستبعدة من Git تلقائيًا.
- 🔄 إذا قمت بالترقّي، استبدل `{env:RAIDAN_BASE_URL}` في `opencode.jsonc` بعنوانك الخاص.

---

## 📦 التحديث من المصدر

```bash
# إعادة مزامنة الإعدادات بعد تغييرات محلية (Linux / macOS):
rsync -av --exclude node_modules ~/.config/opencode/ ./ --include opencode.jsonc

# تنظيف قبل الدفع: استبدل أي رموز جديدة بنصوص بديلة {env:VAR}.
```

---

## 📜 الترخيص

إعدادات شخصية. ترخيص MIT. العوامل والمهارات تحتفظ بترخيصاتها الأصلية (Cloudflare, NVIDIA, Superpowers, ...).

---

*آخر تحديث: سبتمبر 2026*
</div>
