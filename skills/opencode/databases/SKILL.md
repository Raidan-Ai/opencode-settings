---
name: databases
description: Provides relational, document, in-memory, and vector database expertise including PostgreSQL (pgvector), Redis, SQLite, MongoDB, schema design, migrations, query optimization, indexing, and security. Activate for any database design, ORM/SQL, migration, indexing, or query-tuning task.
---

# Databases Skill

## Purpose
Provides comprehensive database engineering capabilities: relational (PostgreSQL, SQLite), document (MongoDB), in-memory (Redis), and vector stores (pgvector, Qdrant, Chroma). Covers schema design, migrations, indexing strategy, query optimization, and security so agents can build correct, fast, and safe data layers.

## When to Activate
- Designing database schemas, tables, collections, or indexes
- Choosing between SQL, NoSQL, in-memory, or vector storage
- Writing SQL, ORM queries, or database access code
- Running migrations with Alembic or equivalent
- Optimizing slow queries (EXPLAIN ANALYZE, index selection)
- Securing database connections, credentials, and access
- Implementing vector search with pgvector/Qdrant/Chroma
- Caching with Redis or embedding models with pgvector

## Core Knowledge

### Database Type Selection
```
Use case                        → Choice
Structured relational data      → PostgreSQL / SQLite
High-throughput key/value cache → Redis
Flexible/evolving documents     → MongoDB
Semantic/vector search          → PostgreSQL + pgvector / Qdrant / Chroma
Embedded, single-file, local    → SQLite
```

### PostgreSQL Connection (psycopg + SQLAlchemy)
```python
# psycopg (psycopg3)
import psycopg

with psycopg.connect(
    "host=localhost dbname=app user=app password=secret port=5432"
) as conn:
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM users WHERE id = %s", (1,))
        row = cur.fetchone()
```
```python
# SQLAlchemy 2.0
from sqlalchemy import create_engine, text
engine = create_engine("postgresql+psycopg://app:secret@localhost:5432/app")
with engine.connect() as conn:
    result = conn.execute(text("SELECT id FROM users WHERE id = :x"), {"x": 1})
```

### pgvector Setup & Similarity Search
```sql
-- Enable the extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Table with an embedding column (e.g. OpenAI text-embedding-3-small = 1536 dims)
CREATE TABLE documents (
    id      BIGSERIAL PRIMARY KEY,
    content TEXT,
    embedding vector(1536)
);

-- Insert: pass embedding via parameterized query
-- psycopg: cur.execute("INSERT INTO documents (content, embedding) VALUES (%s, %s)",
--                      ("hello", embedding_list))

-- Cosine similarity search (ORDER BY <-> operator, indexed)
SELECT id, content, 1 - (embedding <=> :query_embedding) AS similarity
FROM documents
ORDER BY embedding <=> :query_embedding
LIMIT 5;

-- Create a HNSW index for fast approximate search (exact index = ivfflat)
CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops);
```

### Redis Basics (redis-py)
```python
import redis

r = redis.Redis(host="localhost", port=6379, decode_responses=True)

# Simple set/get with TTL
r.set("user:1", '{"name": "ada"}', ex=60)   # expires in 60s
value = r.get("user:1")

# Cache-aside pattern
def get_user(user_id):
    key = f"user:{user_id}"
    cached = r.get(key)
    if cached:
        return json.loads(cached)
    user = db.fetch_user(user_id)           # miss → hit DB
    r.set(key, json.dumps(user), ex=300)
    return user
```

### SQLite Pragmas
```sql
PRAGMA journal_mode = WAL;        -- concurrent reads/writes
PRAGMA synchronous = NORMAL;      -- balanced durability/performance
PRAGMA foreign_keys = ON;         -- enforce FK constraints
PRAGMA busy_timeout = 5000;       -- avoid "database is locked"
```

### MongoDB (pymongo)
```python
from pymongo import MongoClient

client = MongoClient("mongodb://localhost:27017")
db = client["app"]
users = db["users"]

# Create a unique index
users.create_index([("email", 1)], unique=True)

# CRUD
user_id = users.insert_one({"name": "bob", "email": "b@x.io"}).inserted_id
users.update_one({"_id": user_id}, {"$set": {"name": "robert"}})
doc = users.find_one({"email": "b@x.io"})
users.delete_one({"_id": user_id})
```

### Indexing Strategies
| Index type | Use for | Example |
|-----------|---------|---------|
| **BTREE** (default) | Equality + range on scalar columns | `WHERE price BETWEEN 10 AND 20` |
| **GIN** | Arrays, JSONB, full-text | `WHERE tags @> '["red"]'` |
| **HNSW** | Approximate vector similarity | pgvector `USING hnsw` |
| **Unique** | Enforce uniqueness for integrity | emails, usernames |
| **Composite** | Multi-column filters in match order | `(account_id, created_at)` |

## Workflow

### Migrations with Alembic
Why they matter: migrations version schema changes so every environment (dev/staging/prod) evolves identically, enabling rollbacks and code review.
```bash
pip install alembic
alembic init alembic          # scaffold
# edit alembic/env.py: set sqlalchemy.url or use app config

# Generate + apply a migration
alembic revision --autogenerate -m "add users table"
alembic upgrade head

# Roll back one step / to a target
alembic downgrade -1
alembic downgrade <revision_id>
```

### Query Optimization Workflow
```bash
# 1. Run the slow query with actual plan
EXPLAIN (ANALYZE, BUFFERS) SELECT ... FROM orders WHERE customer_id = 7;

# 2. Look for Sequential Scan on large tables →
#    add an index and re-check for Index Scan / Bitmap Heap Scan
```
Optimization checks: `EXPLAIN (ANALYZE)` to find seq scans and high row estimates; add indexes to match `WHERE`/`JOIN` columns; verify index is actually used.

### Vector/Embedding Search (Qdrant)
```python
from qdrant_client import QdrantClient, models

client = QdrantClient(":memory:")   # or url=... for server
client.create_collection(
    collection_name="docs",
    vectors_config=models.VectorParams(size=1536, distance=models.Distance.COSINE),
)
client.upsert(collection_name="docs", points=[
    models.PointStruct(id=1, vector=embedding, payload={"text": "..."})
])
hits = client.search(collection_name="docs", query_vector=embedding, limit=5)
```

### Chroma
```python
import chromadb
client = chromadb.Client()
col = client.get_or_create_collection("docs")
col.add(ids=["1"], embeddings=[embedding], documents=["hello"])
res = col.query(query_embeddings=[embedding], n_results=5)
```

## Tools
```bash
# PostgreSQL
pip install psycopg[binary] sqlalchemy alembic
docker run -d --name pg -e POSTGRES_PASSWORD=secret -p 5432:5432 pgvector/pgvector:pg16

# Redis
pip install redis
docker run -d --name redis -p 6379:6379 redis:7

# MongoDB
pip install pymongo
docker run -d --name mongo -p 27017:27017 mongo:7

# Vector stores
pip install qdrant-client chromadb
docker run -d --name qdrant -p 6333:6333 qdrant/qdrant
```

## MCP Requirements
Recommended MCP servers for database work:
- **PostgreSQL MCP** (e.g. `@modelcontextprotocol/server-postgres`): query schemas/data directly
- **SQLite MCP**: local embedded DB inspection
- **Redis MCP**: key inspection and cache debugging
- **Qdrant / Chroma MCP**: vector collection management

## Best Practices
1. **Use parameterized queries** (never string-interpolate user input) to prevent SQL injection.
2. **Store connection strings in secrets**, not code — parse from env vars / secret manager.
3. **Enforce least privilege**: dedicated DB users per app/role with only needed grants.
4. **Index match your hot query patterns**; verify with `EXPLAIN (ANALYZE)`.
5. **Always use migrations** for schema changes; never hand-edit prod DDL.
6. **Cache with TTLs** and invalidate on writes to avoid stale reads.
7. **Wrap writes in transactions** for multi-step consistency.
8. **Add foreign keys and constraints** at the DB layer, not just in app code.

## Anti-patterns
- ❌ String-interpolating values into SQL (SQL injection)
- ❌ Committing secrets/connection strings (rotation + exposure risk)
- ❌ Running a full-text/JSON query on a plain BTREE index (use GIN)
- ❌ Indexing every column (write amplification, bloat)
- ❌ Hand-editing prod schema without a migration
- ❌ Using a single superuser for all app operations
- ❌ Storing embeddings without an HNSW/ivfflat index (linear scans)
- ❌ Ignoring `EXPLAIN` before "optimizing" blindly

## Verification

### Unit Tests
```python
# test_db.py
from sqlalchemy import create_engine, text


def test_parameterized_query_prevents_injection():
    engine = create_engine("sqlite:///:memory:")
    with engine.begin() as conn:
        conn.execute(text("CREATE TABLE users (id INTEGER PRIMARY KEY, email TEXT)"))
        conn.execute(text("INSERT INTO users (email) VALUES (:e)"), {"e": "a@x.io"})
        # Injection attempt should return zero rows, not drop the table
        rows = conn.execute(
            text("SELECT email FROM users WHERE email = :e"),
            {"e": "x' OR '1'='1"},
        ).fetchall()
        assert len(rows) == 0


def test_redis_cache_aside():
    import redis
    r = redis.Redis(host="localhost", port=6379, decode_responses=True)
    r.set("k", "v", ex=60)
    assert r.get("k") == "v"


def test_sqlite_wal_pragma():
    from sqlite3 import connect
    conn = connect(":memory:")
    conn.execute("PRAGMA journal_mode = WAL")
    mode = conn.execute("PRAGMA journal_mode").fetchone()[0]
    assert mode == "wal"
```

### Integration Checks
- `psql -c "CREATE EXTENSION IF NOT EXISTS vector;"` on PostgreSQL
- `redis-cli ping` → PONG
- `mongosh --eval "db.runCommand({ping:1})"`
- Run `alembic upgrade head`, then `alembic current` to confirm applied version

## Examples

### Full PostgreSQL + pgvector RAG data layer
```python
import psycopg

EMBEDDING_DIM = 1536

def init_schema(conn):
    with conn.cursor() as cur:
        cur.execute("CREATE EXTENSION IF NOT EXISTS vector")
        cur.execute(f"""
            CREATE TABLE IF NOT EXISTS documents (
                id BIGSERIAL PRIMARY KEY,
                content TEXT,
                embedding vector({EMBEDDING_DIM})
            )
        """)
        cur.execute(
            "CREATE INDEX IF NOT EXISTS idx_docs_embedding "
            "ON documents USING hnsw (embedding vector_cosine_ops)"
        )
    conn.commit()

def add_document(conn, content, embedding):
    with conn.cursor() as cur:
        cur.execute(
            "INSERT INTO documents (content, embedding) VALUES (%s, %s)",
            (content, embedding),
        )
    conn.commit()

def search(conn, query_embedding, limit=5):
    with conn.cursor() as cur:
        cur.execute(
            "SELECT content, 1 - (embedding <=> %s) AS sim "
            "FROM documents ORDER BY embedding <=> %s LIMIT %s",
            (query_embedding, query_embedding, limit),
        )
        return [{"content": c, "similarity": float(s)} for c, s in cur.fetchall()]
```

### Parameterized ORM write (SQLAlchemy)
```python
from sqlalchemy.orm import Session
from sqlalchemy import select

def create_user(session: Session, email: str, role: str) -> None:
    # Always bind parameters via the ORM/query builder, never f-strings
    session.add(User(email=email, role=role))
    session.commit()

def find_admins(session: Session):
    return session.scalars(select(User).where(User.role == "admin")).all()
```
