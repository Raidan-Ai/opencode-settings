<div dir="rtl" lang="ar">

# 📂 إعدادات OpenCode — نسخة احتياطية شاملة

نسخة احتياطية كاملة من إعدادات OpenCode — العوامل (Agents)، المهارات (Skills)، الإضافات (Plugins)، الأوامر (Commands)، وملفات السياق (Context).

<p dir="ltr">
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
  ![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey)
  ![Agents](https://img.shields.io/badge/Agents-50-blue)
  ![Skills](https://img.shields.io/badge/Skills-410-purple)
  ![Dashboard](https://img.shields.io/badge/Dashboard-Zero--Dependency-green)
</p>

> **🔒 ضمان الأمان:** جميع بيانات الاعتماد في هذا المستودع عبارة عن نصوص بديلة (`{env:VAR}` أو `your_..._here`). تتواجد الرموز الحقيقية فقط في بيئتك المحلية / ملفات `.env` المُستبعدة من Git.

---

<a id="contents"></a>
## 📑 فهرس المحتويات

1. [المزايا](#features)
2. [محتويات المستودع](#contents-table)
3. [المتطلبات](#requirements)
4. [التثبيت](#installation)
5. [لوحة التحكم](#dashboard)
6. [هيكل المشروع](#structure)
7. [المتغيرات المطلوبة](#env)
8. [خوادم MCP](#mcp)
9. [المزودون](#providers)
10. [ملاحظات الأمان](#security)
11. [إلغاء التثبيت](#uninstall)
12. [التحديث من المصدر](#update)
13. [استكشاف الأخطاء والأسئلة الشائعة](#faq)
14. [المساهمة](#contributing)
15. [الترخيص](#license)

---

<a id="features"></a>
## ✨ المزايا

- **50 ملف تعريف عامل** عبر 6 فئات — العوامل الأساسية (core)، المحتوى (content)، الإدارة (meta)، المساعدون المتخصصون (subagents)، والبيانات (data) — مع نصوص نظام مخصصة لكل دور.
- **410 مهارات (47 مهارة OpenCode + 363 مهارة NVIDIA)** — Cloudflare، Frontend، Security، cuOpt، DOCA، Jetson، TAO، DeepStream، NeMo، وغيرها — كل مهارة بملف `SKILL.md` خاص بها.
- **12 أمر شريط مخصص** لسير العمل الشائعة.
- **176 ملف سياق** — نظام السياق (أساسي، تطوير، ذكاء مشروع، واجهة مستخدم).
- **12 خادم MCP مُهيأ** — context7 وGitHub ومجموعة Cloudflare وNotion وComposio وcodebase-memory مفعّلة افتراضيًا؛ و9 خوادم أخرى معدة مسبقًا (معطّلة حتى تضيف بيانات الاعتماد).
- **لوحة تحكم ويب بدون أي تبعيات** — استعرض وحرّر العوامل والمهارات والإعدادات وخوادم MCP من <http://127.0.0.1:8877> (مكتبات Node القياسية فقط — لا حاجة إلى `npm install`).
- **سكربتا تثبيت متعدد المنصات** — `install.sh` (Linux / macOS) و`install.ps1` (Windows) مع دعم المعاينة (dry-run) وإلغاء التثبيت والنسخ الاحتياطي والتحقق.
- **بدون أسرار بالتصميم** — كل رمز هو نص بديل `{env:VAR}`؛ لا تُرفع المفاتيح في المستودع أبدًا.

---

<a id="contents-table"></a>
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

<a id="requirements"></a>
## 🖥️ المتطلبات

| المتطلب | الحد الأدنى | ملاحظات |
|---------|------------|---------|
| **Node.js** | 20+ | لعملية تثبيت الإضافات |
| **Git** | أي إصدار | لاستنساخ المستودع |
| **OpenCode CLI** | أحدث إصدار | لتشغيل العوامل والمهارات |
| **نظام التشغيل** | Linux / macOS / Windows | متوافق مع الأنظمة الثلاثة |

---

<a id="installation"></a>
## ⚡ التثبيت

### 🐧 Linux / macOS

```bash
# 1. استنساخ المستودع
git clone git@github.com:Raidan-Ai/opencode-settings.git ~/opencode-settings
cd ~/opencode-settings

# 2. تشغيل سكربت التثبيت
bash install.sh
```

**خيارات سكربت التثبيت (`install.sh`):**

| الخيار | الوصف |
|--------|-------|
| `-h`, `--help` | عرض نص الاستخدام |
| `--dry-run` | طباعة ما *سيتم* تنفيذه — بدون نسخ أي شيء |
| `--uninstall` | إزالة المجلدات المثبتة (بعد نسخها احتياطيًا إلى `*.uninstall-backup.<ts>`) |
| `--no-dashboard` | تخطي نسخ لوحة التحكم |
| `--no-backup` | تخطي خطوة النسخ الاحتياطي |
| `--force` | الكتابة فوق الموجود بدون سؤال (الافتراضي: يسأل إذا كان الهدف موجودًا) |
| `--prefix <dir>` | التثبيت في مسار مخصص بدلًا من `~/.config/opencode` |

### 🪟 Windows (PowerShell)

```powershell
# 1. استنساخ المستودع
git clone git@github.com:Raidan-Ai/opencode-settings.git $HOME\opencode-settings
cd $HOME\opencode-settings

# 2. تشغيل سكربت التثبيت (لا يتطلب صلاحيات المسؤول)
.\install.ps1
```

**خيارات سكربت التثبيت (`install.ps1`):**

| الخيار | الوصف |
|--------|-------|
| `-Help` | عرض نص الاستخدام |
| `-DryRun` | طباعة ما *سيتم* تنفيذه — بدون نسخ أي شيء |
| `-Uninstall` | إزالة المجلدات المثبتة (بعد نسخها احتياطيًا) |
| `-NoDashboard` | تخطي نسخ لوحة التحكم |
| `-NoBackup` | تخطي خطوة النسخ الاحتياطي |
| `-Force` | الكتابة فوق الموجود بدون سؤال |
| `-Prefix <dir>` | التثبيت في مسار مخصص بدلًا من `%USERPROFILE%\.config\opencode` |

> سكربتا التثبيت ينسخان الإعدادات إلى `~/.config/opencode` (نفس المسار على الأنظمة الثلاثة)، ويقومان بنسخ احتياطي لأي إعدادات موجودة، ثم ينتهيان بخطوة تحقق تطبع التعدادات.

---

<a id="manual"></a>
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

<a id="dashboard"></a>
## 🖥️ لوحة التحكم (استعراض وتحرير إعداداتك)

يأتي المستودع مع **لوحة تحكم ويب بدون أي تبعيات** (مكتبات Node القياسية فقط — لا حاجة
إلى `npm install`). سكربتا التثبيت ينسخانها تلقائيًا إلى `~/.config/opencode/dashboard/`.

```bash
# التشغيل (Linux / macOS)
node ~/.config/opencode/dashboard/server.js

# Windows
node "$HOME\.config\opencode\dashboard\server.js"
```

افتح <http://127.0.0.1:8877> — استعرض العوامل والمهارات والنماذج وخوادم MCP
وملف `opencode.jsonc`، وحرّرها مباشرة من المتصفح (كل عملية حفظ تنشئ نسخة احتياطية
`.bak-dash-*` أولاً). متغيرات إضافية: `DASHBOARD_PORT` و`DASHBOARD_HOST`
و`OPENCODE_AGENT_DIR` و`OPENCODE_SKILLS_DIR` و`OPENCODE_CONFIG_FILE`.
التوثيق الكامل للواجهة والإعدادات في `dashboard/README.md`.

---

<a id="structure"></a>
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
├── agents/               # 50 تعريف عامل مخصص (core, content, meta, subagents, data)
├── commands/             # 12 أمر شريط مخصص
├── config/               # إعدادات_agent-metadata.json
├── context/              # نظام السياق — 176 ملف (core, development, project-intelligence, ui)
├── plugins/              # إضافات TypeScript
├── skills/
│   ├── opencode/         # 47 مهارة OpenCode (Cloudflare, Frontend, Security, ...)
│   └── nvidia/           # 363 مهارة NVIDIA (cuOpt, DOCA, Jetson, TAO, DeepStream, ...)
├── tools/                # أدوات مخصصة (env, gemini)
└── dashboard/            # لوحة تحكم ويب بدون تبعيات (واجهة للعوامل والمهارات والإعدادات)
```

---

<a id="env"></a>
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
| `ALIBABA_CLOUD_ACCESS_KEY_ID` / `_SECRET` | Alibaba Cloud Ops MCP (معطّل افتراضيًا) |
| `GEMINI_API_KEY` | أداة Gemini |
| `TELEGRAM_BOT_TOKEN` / `TELEGRAM_CHAT_ID` | إضافة Telegram (اختياري) |
| `MINIMAX_API_KEY` | MiniMax API (اختياري) |

---

<a id="mcp"></a>
## 🔌 خوادم MCP

| الخادم | الحالة | ملاحظات |
|--------|--------|---------|
| context7 | ✅ مفعّل | عن بُعد، بدون مصادقة |
| github | ✅ مفعّل | يتطلب `GITHUB_TOKEN` |
| cloudflare (+docs, bindings, builds, observability) | ✅ مفعّل | OAuth — `opencode mcp auth cloudflare` |
| notion | ✅ مفعّل | يتطلب `NOTION_TOKEN` |
| composio | ✅ مفعّل | يتطلب `COMPOSIO_API_KEY` |
| codebase-memory | ✅ مفعّل | برنامج محلي في `~/.codebase-memory` (v0.10.8) |
| playwright / postgres / redis / milvus / azure / aws / vercel / gcloud / firebase | ⛔ معطّل | فعّلها بعد توفير بيانات الاعتماد |

---

<a id="providers"></a>
## 🏷️ المزودون

`opencode.jsonc` يعرّف مزودي النماذج (K3, DeepSeekPro, Nemotron, Raidan) كنقاط نهاية متوافقة مع OpenAI. يتم الإعلان عن *نقطة النهاية* فقط — **لا تُخزَّن أي مفاتيح API في هذا المستودع**. أضف مفتاحك عبر متغيرات البيئة أو تدفق مصادقة OpenCode.

---

<a id="security"></a>
## 🛡️ ملاحظات الأمان

- ⚠️ **لا تقم بتشفير هذا المستودع** — تحتوي ملفات العوامل على اتفاقيات ملكية خاصة.
- 📋 فحص الأسرار قبل الدفع:
  ```bash
  grep -rlnE "ghp_|ntn_|sk-[A-Za-z0-9]|AKIA[0-9A-Z]|Bearer [A-Za-z0-9_-]{20,}" . --exclude-dir=node_modules
  ```
- 🚫 ملفات `.env` و`node_modules` مستبعدة من Git تلقائيًا.
- 🔄 إذا قمت بالترقّي، استبدل `{env:RAIDAN_BASE_URL}` في `opencode.jsonc` بعنوانك الخاص.

---

<a id="uninstall"></a>
## 🗑️ إلغاء التثبيت

يدعم سكربتا التثبيت إلغاء تثبيت نظيف **مع نسخ احتياطي أولًا** — لا يُحذف أي شيء
بدون نسخة زمنية (`*.uninstall-backup.<ts>`).

```bash
# Linux / macOS — معاينة أولًا، ثم الإلغاء
bash install.sh --uninstall --dry-run
bash install.sh --uninstall
```

```powershell
# Windows — معاينة أولًا، ثم الإلغاء
.\install.ps1 -Uninstall -DryRun
.\install.ps1 -Uninstall
```

> إلغاء التثبيت يزيل `~/.config/opencode` و`~/.agents` (بعد نسخهما احتياطيًا).
> للإكمال، احذف أيضًا النسخة المحلية المستنسخة: `rm -rf ~/opencode-settings`.

---

<a id="update"></a>
## 📦 التحديث من المصدر

```bash
# إعادة مزامنة الإعدادات بعد تغييرات محلية (Linux / macOS):
rsync -av --exclude node_modules ~/.config/opencode/ ./ --include opencode.jsonc

# تنظيف قبل الدفع: استبدل أي رموز جديدة بنصوص بديلة {env:VAR}.
```

---

<a id="faq"></a>
## ❓ استكشاف الأخطاء والأسئلة الشائعة

**OpenCode لا يرى العوامل الخاصة بي.**
تأكد من أن العوامل في `~/.config/opencode/agents`، ثم أعد تشغيل OpenCode. شغّل `bash install.sh --dry-run` للتأكد من أن السكربت يرى الملفات.

**منفذ لوحة التحكم مستخدم بالفعل.**
ربما تعمل نسخة أخرى. استخدم منفذًا مختلفًا: `DASHBOARD_PORT=9000 node ~/.config/opencode/dashboard/server.js`، أو أوقف العملية القديمة أولًا.

**المهارات لا تظهر.**
المهارات في `~/.config/opencode/skills/` (OpenCode) و`~/.agents/skills/` (NVIDIA). أعد تشغيل سكربت التثبيت — فهو ينسخ الموقعين ويتحقق من التعدادات.

**كيف أتحقق من التثبيت؟**
أعد تشغيل سكربت التثبيت — ينتهي بخطوة تحقق تفحص `opencode.jsonc` وتعدّد ملفات العوامل وتؤكد وجود لوحة التحكم. توقّع أن تطابق التعدادات: 50 عاملًا، 47 مهارة OpenCode، 363 مهارة NVIDIA.

---

<a id="contributing"></a>
## 🤝 المساهمة

1. انسخ المستودع (fork) وأنشئ فرع ميزة.
2. أبقِ كل سر خارجًا — استخدم نصوص بديلة `{env:VAR}` لأي شيء خاص بالجهاز أو المستخدم.
3. شغّل فحص الأسرار من [ملاحظات الأمان](#security) قبل الدفع.
4. افتح طلب سحب (PR) يصف التغيير (عامل، مهارة، أو إعداد) وما يضيفه.

---

<a id="license"></a>
## 📜 الترخيص

إعدادات شخصية. ترخيص MIT. العوامل والمهارات تحتفظ بترخيصاتها الأصلية (Cloudflare, NVIDIA, Superpowers, ...).

---

*آخر تحديث: سبتمبر 2026*
</div>
