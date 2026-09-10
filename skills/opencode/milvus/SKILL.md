# Milvus Skill

## Purpose
Provides dedicated Milvus vector database expertise including collection management, schema design, indexing (HNSW/IVF/DiskANN), hybrid search, metadata filtering, and production deployment. Specialized agent capability for Milvus-powered RAG and vector search systems.

## When to Activate
- Building production vector databases with Milvus
- Designing collection schemas and vector indexes
- Implementing HNSW, IVF, or DiskANN indexing strategies
- Configuring metadata filtering and hybrid search
- Scaling vector search for large datasets (millions/billions of vectors)
- Milvus Docker deployment and production architecture

## Core Knowledge

### Milvus Architecture
```
Client Libraries → gRPC/REST → Query Node → Data Node → Index → Vector Storage
     ↑                                      ↑
  SDKs                                      Persistent
  (Python, Java, Go, Node)                  Storage
```

### Collection Schema Design
```python
from pymilvus import MilvusClient, DataType, FieldSchema, CollectionSchema

# Define fields for a RAG collection
fields = [
    FieldSchema(name="id", dtype=DataType.INT64, is_primary=True, auto_id=False),
    FieldSchema(name="vector", dtype=DataType.FLOAT_VECTOR, dim=1536),
    FieldSchema(name="text", dtype=DataType.VARCHAR, max_length=65535),
    FieldSchema(name="source", dtype=DataType.VARCHAR, max_length=512),
    FieldSchema(name="page_number", dtype=DataType.INT64),
    FieldSchema(name="chunk_index", dtype=DataType.INT64),
    FieldSchema(name="metadata", dtype=DataType.VARCHAR, max_length=65535),
]

schema = CollectionSchema(
    fields=fields,
    description="RAG document collection with metadata filtering"
)
```

### Indexing Strategies

#### HNSW (Hierarchical Navigable Small World)
- Best for: Real-time search, moderate dataset sizes (thousands to millions)
- Parameters: `M` (connectivity, typically 16), `ef` (search accuracy, typically 64-512)
- Trade-off: Higher M = better recall but slower indexing
```python
index_params = {
    "index_type": "HNSW",
    "metric_type": "L2",
    "params": {"M": 16, "ef": 64}
}
```

#### IVF (Inverted File Index)
- Best for: Large datasets, batch search scenarios
- Parameters: `nlist` (number of clusters, typically 4096-65536 for million-scale)
- Trade-off: Higher nlist = better recall but slower build time
```python
index_params = {
    "index_type": "IVF",
    "metric_type": "L2",
    "params": {"nlist": 1024}
}
```

#### DiskANN (Disk-based Ann)
- Best for: Very large datasets (hundreds of millions), storage-efficient
- Parameters: `disk_ann_params` with `nlist`, `segment_size` controls
- Trade-off: Slower query speed than HNSW but much lower memory usage
```python
index_params = {
    "index_type": "DiskANN",
    "metric_type": "L2",
    "params": {"nlist": 4096, "segment_size": 10000}
}
```

### Search Parameters
```python
search_params = {
    "ann_width": 1,  # Number of probes for IVF/DiskANN (1 = fastest, more = more accurate)
    "radius": None,  # For L2 search: return results within this radius
    "rounds": 1,     # For DiskANN: number of refinement rounds
    "ef": 64         # For HNSW: search beam width (higher = more accurate but slower)
}
```

### Metadata Filtering
```python
# Filter by exact match
filter_expr = 'source == "report.pdf" AND page_number == 5'

# Filter with comparison operators
filter_expr = 'chunk_index > 0 AND chunk_index < 10'

# Filter with LIKE (substring)
filter_expr = 'metadata like "%%financial%%"'

# Combined with vector search
results = client.search(
    collection_name="rag_docs",
    data=[query_vector],
    anns_field="vector",
    expr=filter_expr,
    limit=5,
    output_fields=["text", "source", "page_number"]
)
```

### Hybrid Search (Vector + Filter)
Milvus supports combining vector search with boolean filter expressions:
```python
# Vector search + metadata filter simultaneously
results = client.search(
    collection_name="rag_docs",
    data=[query_vector],
    anns_field="vector",
    expr="source == 'interview.pdf' AND page_number >= 3",
    limit=10,
    output_fields=["text", "source", "page_number"]
)
```

### Partition Management
- **Partitions**: Logical subsets of a collection for efficient filtering
- Use case: Tenancy, time-based data segregation, department isolation
```python
# Create partition
client.create_partition(
    collection_name="rag_docs",
    partition_name="finance_docs"
)

# Insert into specific partition
client.insert(
    collection_name="rag_docs",
    data=[{
        "id": 1,
        "vector": embedding,
        "text": "financial data...",
        "partition_name": "finance_docs"  # or use partition field
    }],
    partition_name="finance_docs"
)

# Query within partition
results = client.search(
    collection_name="rag_docs",
    data=[query_vector],
    anns_field="vector",
    partition_names=["finance_docs"],  # Only search within this partition
    limit=5
)
```

### Persistence and Durability
```python
# Durability levels (DurableNode via gRPC)
# Default: async replication, may lose recent writes on crash
# Synchronous: wait for data to be durable before acknowledging

# Enable durable writes
from pymilvus import MilvusClient

client = MilvusClient(
    uri="http://localhost:19530",
    defaultdurablewritelength=100,   # batch size
    defaultdurabletimeout=60          # timeout in seconds
)

# Check durability status
status = client.get_compact_state(collection_name="rag_docs")
```

### Data Management Operations

#### Flushing Data
```python
# Force flush in-memory data to disk
client.flush(collection_name="rag_docs")
```

#### Compacting Data
```python
# Run compaction to optimize storage and search performance
client.compact_collection(collection_name="rag_docs")
```

#### Releasing Partitions
```python
# Release a partition from memory (makes it on-disk only)
client.release_partition(collection_name="rag_docs", partition_name="old_partition")
```

## Workflow

### 1. Milvus Deployment
```bash
# Docker Compose for production Milvus
version: '3'
services:
  milvus:
    image: milvusdb/milvus:latest
    container_name: milvus
    ports:
      - "19530:19530"  # gRPC
      - "19531:19531"  # REST API
    environment:
      - MICRO_DIST_URL="https://milvus.minio.docker.io"
      - MINIO_URL="minio:9000"
      - MINIO_ACCESS_KEY="minioadmin"
      - MINIO_SECRET_KEY="minioadmin"
    volumes:
      - milvus_data:/var/lib/milvus

  minio:
    image: minio/minio:latest
    container_name: minio
    command: server /data --console-address ":9001"
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      - MINIO_ACCESS_KEY="minioadmin"
      - MINIO_SECRET_KEY="minioadmin"

volumes:
  milvus_data:
```

### 2. Collection Creation with Optimal Index
```python
from pymilvus import MilvusClient, DataType, FieldSchema, CollectionSchema, IndexParams

client = MilvusClient(uri="http://localhost:19530")

# Define schema
fields = [
    FieldSchema(name="id", dtype=DataType.INT64, is_primary=True, auto_id=True),
    FieldSchema(name="vector", dtype=DataType.FLOAT_VECTOR, dim=1536),
    FieldSchema(name="text", dtype=DataType.VARCHAR, max_length=65535),
    FieldSchema(name="source", dtype=DataType.VARCHAR, max_length=512),
    FieldSchema(name="page_number", dtype=DataType.INT64),
    FieldSchema(name "chunk_index", dtype=DataType.INT64),
]

schema = CollectionSchema(fields=fields, description="RAG document collection")

# Create collection
client.create_collection(
    collection_name="rag_docs",
    schema=schema,
    index_params={  # Create HNSW index on vector field
        "index_name": "hnsw_vec",
        "field_name": "vector",
        "index_type": "HNSW",
        "metric_type": "L2",
        "params": {"M": 16, "ef": 64}
    }
)

# Wait for index to build
client.wait_for_index_building_complete("rag_docs")
```

### 3. Insert Data
```python
# Insert vectors with payload
client.insert(
    collection_name="rag_docs",
    data=[{
        "vector": embedding_vector_1,
        "text": "First document chunk...",
        "source": "doc1.pdf",
        "page_number": 1,
        "chunk_index": 0
    }, {
        "vector": embedding_vector_2,
        "text": "Second document chunk...",
        "source": "doc1.pdf",
        "page_number": 1,
        "chunk_index": 1
    }]
)
```

### 4. Search with Filtering
```python
# Search with metadata filter
results = client.search(
    collection_name="rag_docs",
    data=[query_vector],
    anns_field="vector",
    expr="source == 'doc1.pdf' AND page_number == 1",
    limit=3,
    output_fields=["text", "source", "page_number"]
)

for result in results[0]:
    print(f"Score: {result['distance']}")
    print(f"Text: {result['entity']['text'][:200]}...")
    print(f"Source: {result['entity']['source']}")
    print("---")
```

### 5. Hybrid Search Example
```python
# Vector search with range filter AND metadata filter
results = client.search(
    collection_name="rag_docs",
    data=[query_vector],
    anns_field="vector",
    expr="page_number >= 5 AND page_number <= 10",  # Range filter
    limit=5,
    output_fields=["text", "page_number"]
)
```

### 6. Partition-Aware Workflow
```python
# Create partitions for different document sets
client.create_partition(collection_name="rag_docs", partition_name="user_docs")
client.create_partition(collection_name="rag_docs", partition_name="admin_docs")

# Insert data into specific partitions
client.insert(
    collection_name="rag_docs",
    data=[{"vector": v1, "text": "user data", "partition_name": "user_docs"}],
    partition_name="user_docs"
)

client.insert(
    collection_name="rag_docs",
    data=[{"vector": v2, "text": "admin data", "partition_name": "admin_docs"}],
    partition_name="admin_docs"
)

# Search within specific partition
results = client.search(
    collection_name="rag_docs",
    data=[query_vector],
    anns_field="vector",
    partition_names=["user_docs"],  # Only search user_docs partition
    limit=5
)
```

## Tools

### Package Installation
```bash
# Primary Milvus client
pip install pymilvus

# Alternative: use MilvusClient directly
pip install milvus-client

# Docker for local deployment
# (Docker already installed - see validation section)

# Verification tools
pip install pytest
```

### Command-Line Utilities
```bash
# Start Milvus via Docker
docker run -d -p 19530:19530 -p 19531:19531 \
  -e MICRO_DIST_URL="https://milvus.minio.docker.io" \
  -e MINIO_URL="minio:9000" \
  -e MINIO_ACCESS_KEY="minioadmin" \
  -e MINIO_SECRET_KEY="minioadmin" \
  milvusdb/milvus:latest

# Check Milvus is running
python -c "from pymilvus import MilvusClient; c = MilvusClient('http://localhost:19530'); print('Collections:', c.list_collections())"

# Create a test collection
python -c "
from pymilvus import MilvusClient, DataType, FieldSchema, CollectionSchema
c = MilvusClient('http://localhost:19530')
fields = [
    FieldSchema(name='id', dtype=DataType.INT64, is_primary=True, auto_id=True),
    FieldSchema(name='vector', dtype=DataType.FLOAT_VECTOR, dim=1536),
    FieldSchema(name='text', dtype=DataType.VARCHAR, max_length=65535),
]
schema = CollectionSchema(fields=fields, desc='test')
c.create_collection('test', schema=schema,
    index_params={'index_name': 'idx', 'field_name': 'vector',
                  'index_type': 'HNSW', 'metric_type': 'L2', 'params': {'M': 16, 'ef': 64}})
print('Collection created:', c.has_collection('test'))
"
```

### MCP Integration
```json
{
  "mcpServers": {
    "milvus": {
      "command": "docker",
      "args": ["run", "-d", "-p", "19530:19530", "-p", "19531:19531", 
                "-e", "MICRO_DIST_URL=https://milvus.minio.docker.io",
                "-e", "MINIO_URL=minio:9000",
                "-e", "MINIO_ACCESS_KEY=minioadmin",
                "-e", "MINIO_SECRET_KEY=minioadmin",
                "milvusdb/milvus:latest"],
      "description": "Production Milvus vector database with MinIO storage",
      "ports": [19530, 19531],
      "health_check": {
        "command": ["curl", "-f", "http://localhost:19531/api/v2/status"],
        "interval": 30000,
        "timeout": 10000
      }
    }
  }
}
```

## Best Practices

1. **Choose the right index type**:
   - HNSW: Real-time search, moderate datasets
   - IVF: Large datasets, batch-oriented queries
   - DiskANN: Very large datasets (100M+), memory-constrained

2. **Index parameter tuning**:
   - HNSW: Start with M=16, ef=64; adjust based on recall vs speed needs
   - IVF: nlist = 2 * sqrt(total_vectors) is a good starting point
   - DiskANN: segment_size controls trade-off between query speed and storage

3. **Metadata filtering design**:
   - Use VARCHAR for string filters (source, doc_type, etc.)
   - Use INT64 for numeric filters (page_number, chunk_index, timestamps)
   - Create partitions for large-scale tenancy requirements
   - Combine vector search with filters for precise retrieval

4. **Search parameter selection**:
   - HNSW: ef=64-128 balances accuracy and speed for most use cases
   - IVF: ann_width=1 (single probe) for fastest; increase for better recall
   - DiskANN: rounds=1 default; increase for challenging queries

5. **Persistence strategy**:
   - Enable durable writes for production: `defaultdurablewritelength=10`, `defaultdurabletimeout=30`
   - Regular compaction to optimize storage
   - Monitor `get_compact_state` for durability status

6. **Partition strategy**:
   - Use partitions for logical data segregation (not as primary filter mechanism)
   - Partitions reduce search scope but don't replace metadata filtering
   - Create partitions based on expected query patterns (tenancy, time ranges)

7. **Memory management**:
   - HNSW index lives in memory; size scales with M parameter and vector dimension
   - For large datasets, prefer IVF/DiskANN over HNSW
   - Monitor Milvus server resources (CPU, memory, disk)

## Anti-patterns

- ❌ Using HNSW for billions of vectors (memory-intensive, choose DiskANN/IVF instead)
- ❌ Setting M too high (e.g., M=128) without sufficient memory - recall gains diminish beyond M=32
- ❌ Using IVF with too few nlist clusters (e.g., nlist=100 for 1M vectors) - severe recall degradation
- ❌ Forgetting to wait for index building before searching
- ❌ Mixing float32 and float64 vectors in same collection
- ❌ No metadata filtering (all results returned, including irrelevant ones)
- ❌ Using auto_id without considering data integrity needs
- ❌ Not flushing/compacting regularly (performance degradation over time)

## Verification

### Unit Tests
```python
def test_milvus_connection():
    from pymilvus import MilvusClient
    c = MilvusClient('http://localhost:19530')
    collections = c.list_collections()
    assert isinstance(collections, list)

def test_create_collection_with_index():
    from pymilvus import MilvusClient, DataType, FieldSchema, CollectionSchema, IndexParams
    c = MilvusClient('http://localhost:19530')
    
    fields = [
        FieldSchema(name='id', dtype=DataType.INT64, is_primary=True, auto_id=True),
        FieldSchema(name='vector', dtype=DataType.FLOAT_VECTOR, dim=1536),
        FieldSchema(name='text', dtype=DataType.VARCHAR, max_length=65535),
    ]
    schema = CollectionSchema(fields=fields, desc='test')
    
    # Create with HNSW index
    c.create_collection(
        'test',
        schema=schema,
        index_params={
            'index_name': 'hnsw_idx',
            'field_name': 'vector',
            'index_type': 'HNSW',
            'metric_type': 'L2',
            'params': {'M': 16, 'ef': 64}
        }
    )
    
    assert c.has_collection('test')
    
    # Verify index exists
    index_info = c.get_index_info('test', 'vector')
    assert index_info['index_name'] == 'hnsw_idx'

def test_metadata_filtering():
    from pymilvus import MilvusClient
    c = MilvusClient('http://localhost:19530')
    
    # Create collection with metadata fields
    fields = [
        FieldSchema(name='id', dtype=DataType.INT64, is_primary=True, auto_id=True),
        FieldSchema(name='vector', dtype=DataType.FLOAT_VECTOR, dim=1536),
        FieldSchema(name='source', dtype=DataType.VARCHAR, max_length=512),
        FieldSchema(name='page_number', dtype=DataType.INT64),
    ]
    schema = CollectionSchema(fields=fields, desc='test_filtering')
    
    c.create_collection('test_filtering', schema=schema)
    
    # Insert test data
    c.insert('test_filtering', [
        {'id': 1, 'vector': [0.1]*1536, 'source': 'doc1.pdf', 'page_number': 1},
        {'id': 2, 'vector': [0.2]*1536, 'source': 'doc2.pdf', 'page_number': 5},
    ])
    
    # Search with filter
    results = c.search(
        'test_filtering',
        data=[[0.3]*1536],
        anns_field='vector',
        expr='source == "doc1.pdf" AND page_number == 1',
        limit=1
    )
    
    assert len(results[0]) == 1
    assert results[0][0]['entity']['source'] == 'doc1.pdf'

def test_hybrid_search():
    from pymilvus import MilvusClient
    c = MilvusClient('http://localhost:19530')
    
    # Create collection
    fields = [
        FieldSchema(name='id', dtype=DataType.INT64, is_primary=True, auto_id=True),
        FieldSchema(name='vector', dtype=DataType.FLOAT_VECTOR, dim=1536),
        FieldSchema(name='page_number', dtype=DataType.INT64),
    ]
    schema = CollectionSchema(fields=fields, desc='hybrid')
    c.create_collection('hybrid', schema=schema)
    
    # Insert data
    c.insert('hybrid', [
        {'id': 1, 'vector': [0.1]*1536, 'page_number': 1},
        {'id': 2, 'vector': [0.2]*1536, 'page_number': 5},
        {'id': 3, 'vector': [0.3]*1536, 'page_number': 8},
    ])
    
    # Vector search with page range filter
    results = c.search(
        'hybrid',
        data=[[0.15]*1536],
        anns_field='vector',
        expr='page_number >= 1 AND page_number <= 5',
        limit=2
    )
    
    # Should only return results with page_number 1 and 5
    assert len(results[0]) <= 2
    for r in results[0]:
        assert 1 <= r['entity']['page_number'] <= 5
```

### Integration Tests
- End-to-end: Insert vectors → search with filters → verify correct results
- Index type comparison: HNSW vs IVF vs DiskANN recall rates
- Partition query performance vs global query
- Durability: Verify data survives restart

## Examples

### Complete RAG Pipeline with Milvus
```python
import numpy as np
from pymilvus import MilvusClient, DataType, FieldSchema, CollectionSchema

client = MilvusClient(uri="http://localhost:19530")

# 1. Create collection schema
fields = [
    FieldSchema(name="id", dtype=DataType.INT64, is_primary=True, auto_id=True),
    FieldSchema(name="vector", dtype=DataType.FLOAT_VECTOR, dim=1536),
    FieldSchema(name="text", dtype=DataType.VARCHAR, max_length=65535),
    FieldSchema(name="source", dtype=DataType.VARCHAR, max_length=512),
    FieldSchema(name="page_number", dtype=DataType.INT64),
    FieldSchema(name="chunk_index", dtype=DataType.INT64),
]

schema = CollectionSchema(
    fields=fields,
    description="RAG document collection with full metadata"
)

# 2. Create collection with HNSW index
client.create_collection(
    collection_name="rag_documents",
    schema=schema,
    index_params={
        "index_name": "hnsw_vec",
        "field_name": "vector",
        "index_type": "HNSW",
        "metric_type": "L2",
        "params": {"M": 16, "ef": 64}
    }
)

# 3. Wait for index to build
import time
while True:
    state = client.get_compact_state("rag_documents")
    if state == "completed":
        break
    time.sleep(2)

# 4. Insert sample vectors (from document chunks)
sample_vectors = [
    {"id": i, "vector": np.random.rand(1536).tolist(), 
     "text": f"Document chunk {i} about renewable energy...",
     "source": "renewable_energy.pdf",
     "page_number": (i % 10) + 1,
     "chunk_index": i}
    for i in range(100)
]
client.insert(collection_name="rag_documents", data=sample_vectors)

# 5. Search with metadata filter
query_vec = np.random.rand(1536).tolist()
results = client.search(
    collection_name="rag_documents",
    data=[query_vec],
    anns_field="vector",
    expr="source == 'renewable_energy.pdf' AND page_number >= 3",
    limit=5,
    output_fields=["text", "source", "page_number"]
)

print(f"Found {len(results[0]} results matching criteria:")
for r in results[0]:
    print(f"  - Page {r['entity']['page_number']}: {r['entity']['text'][:100]}...")
    print(f"    Score: {r['distance']:.4f}")
```

### IVF Index for Large Dataset
```python
from pymilvus import MilvusClient, DataType, FieldSchema, CollectionSchema

client = MilvusClient(uri="http://localhost:19530")

# For >1M vectors, use IVF instead of HNSW
fields = [
    FieldSchema(name="id", dtype=DataType.INT64, is_primary=True, auto_id=True),
    FieldSchema(name="vector", dtype=DataType.FLOAT_VECTOR, dim=1536),
    FieldSchema(name="text", dtype=DataType.VARCHAR, max_length=65535),
]

schema = CollectionSchema(fields=fields, description="Large-scale RAG collection")

client.create_collection(
    collection_name="massive_rag",
    schema=schema,
    index_params={
        "index_name": "ivf_idx",
        "field_name": "vector",
        "index_type": "IVF",
        "metric_type": "L2",
        "params": {"nlist": 4096}  # 4096 clusters for ~1M vectors
    }
)

# Search with IVF (set ann_width for number of probes)
results = client.search(
    collection_name="massive_rag",
    data=[query_vector],
    anns_field="vector",
    search_params={"ann_width": 32},  # Probe 32 of 4096 clusters
    limit=10,
    output_fields=["text"]
)
```

### DiskANN for Very Large Scale
```python
from pymilvus import MilvusClient, DataType, FieldSchema, CollectionSchema

client = MilvusClient(uri="http://localhost:19530")

# For 100M+ vectors with memory constraints
fields = [
    FieldSchema(name="id", dtype=DataType.INT64, is_primary=True, auto_id=True),
    FieldSchema(name="vector", dtype=DataType.FLOAT_VECTOR, dim=1536),
    FieldSchema(name="text", dtype=DataType.VARCHAR, max_length=65535),
    FieldSchema(name="timestamp", dtype=DataType.VARCHAR, max_length=512),
]

schema = CollectionSchema(fields=fields, description="Extreme-scale vector database")

client.create_collection(
    collection_name="extreme_rag",
    schema=schema,
    index_params={
        "index_name": "diskann_idx",
        "field_name": "vector",
        "index_type": "DiskANN",
        "metric_type": "L2",
        "params": {
            "nlist": 4096,
            "segment_size": 10000,  # Control segment size for balancing
            "extra_mmap_ratio": 0.1
        }
    }
)

# DiskANN search parameters
results = client.search(
    collection_name="extreme_rag",
    data=[query_vector],
    anns_field="vector",
    search_params={
        "ann_width": 1,       # Number of probes (1 = fastest)
        "rounds": 2,         # Refinement rounds
        "radius": None       # L2 distance radius (None = no limit)
    },
    limit=10,
    output_fields=["text"]
)
```