# RAG Skill

## Purpose
Provides Retrieval-Augmented Generation capabilities including document ingestion, chunking, embeddings, retrieval, reranking, and vector database integration (Milvus, Pinecone, Weaviate). Enables building RAG pipelines from scratch.

## When to Activate
- Building or modifying RAG systems
- Implementing document retrieval for LLM applications
- Need semantic search over private/document collections
- Integrating with vector databases (Milvus, Pinecone, Weaviate, Qdrant)
- Query expansion, hybrid search, or reranking requirements

## Core Knowledge

### RAG Pipeline Architecture
```
Document Ingestion → Chunking → Embeddings → Storage → Retrieval → Reranking → LLM Response
     ↓              ↓           ↓            ↓           ↓              ↓              ↓
  PDF/URL        Semantic     OpenAI/      Vector      Maximal Marginal  Diversity/     Relevance
               Chunking     Cohere       DB (Milvus/  Routing         Fusion         scoring
                                            Pinecone)                   +
                                                   Reciprocal
                                                    Rank Fusion
```

### Chunking Strategies
- **Fixed-size**: Split text into fixed-size chunks with overlap
- **Recursive**: Split by hierarchy (paragraph → sentence → word)
- **Semantic**: Split by topic coherence (chapters, sections)
- **Token-aware**: Ensure chunks fit within token limits

### Embedding Models
- OpenAI: `text-embedding-ada-002`, `text-embedding-3-large`
- Cohere: `embed-english-v3.0`, `embed-multilingual-v3.0`
- HuggingFace: `all-MPNetBase-v2`, `all-MiniLM-L6-v2`
- FlagEmbedding: BAAI models for multilingual tasks

### Retrieval Methods
- **Vector search**: Cosine similarity, L2 distance, dot product
- **Keyword search**: BM25, TF-IDF
- **Hybrid search**: Combination of vector + keyword (RRF - Reciprocal Rank Fusion)
- **Metadata filtering**: Filter by metadata before/after vector search

### Reranking
- **Cross-encoder**: Re-rank top-k candidates for relevance
- **Cohere Rerank**: External reranking service
- **Listwise**: Re-rank entire candidate list

### Vector Databases
- **Milvus**: Scalable, production-grade, supports HNSW/IVF/DiskANN
- **Pinecone**: Managed service, easy setup
- **Weaviate**: Vector search + object database
- **Qdrant**: Vector search with extensive filter support
- **Chroma**: Lightweight, development-focused

## Workflow

### 1. Document Ingestion
```bash
# Install required packages
pip install unstructured[pdf] pypdf2 langchain

# Extract text from various formats
python -c "
from unstructured.partition.pdf import partition_pdf
elements = partition_pdf(filename='document.pdf')
text = '\n\n'.join([str(e) for e in elements])
"

# Or use PyMuPDF for faster PDF extraction
python -c "
import fitz
doc = fitz.open('document.pdf')
text = ''.join([page.get_text() for page in doc])
"
```

### 2. Chunking
```python
from langchain.text_splitter import RecursiveCharacterTextSplitter

 splitter = RecursiveCharacterTextSplitter(
     chunk_size=1000,
     chunk_overlap=200,
     separators=["\n\n", "\n", " ", ""]
 )
chunks = splitter.split_text(raw_text)
```

### 3. Embeddings
```python
from langchain.embeddings import OpenAIEmbeddings

embeddings = OpenAIEmbeddings()
vector = embeddings.embed_query(text)
```

### 4. Vector Database (Milvus example)
```python
from pymilvus import MilvusClient, DataType

client = MilvusClient(uri='http://localhost:19530')

# Create collection
client.create_collection(
    collection_name='rag_docs',
    schema={
        'dimension': 1536,
        'field_definitions': [
            {'name': 'id', 'data_type': DataType.INT64, 'is_primary': True},
            {'name': 'vector', 'data_type': DataType.FLOAT_VECTOR, 'dim': 1536},
            {'name': 'text', 'data_type': DataType.VARCHAR, 'max_length': 65535},
            {'name': 'metadata', 'data_type': DataType.VARCHAR, 'max_length': 65535}
        ]
    }
)

# Insert vectors
client.insert(
    collection_name='rag_docs',
    data=[{
        'id': 1,
        'vector': embedding_vector,
        'text': chunk_text,
        'metadata': json.dumps(meta_dict)
    }]
)

# Search similar vectors
results = client.search(
    collection_name='rag_docs',
    data=[query_vector],
    anns_field='vector',
    limit=5,
    output_fields=['text', 'metadata']
)
```

### 5. Retrieval + Reranking
```python
# First retrieve top-k candidates
retrieved = vector_db.search(query_vector, top_k=20)

# Rerank using cross-encoder
from sentence_transformers import CrossEncoder
cross_encoder = CrossEncoder('ms-marco-MiniLM-L-6-v2')
pairs = [(query, doc['text']) for doc in retrieved]
scores = cross_encoder.predict(pairs)

# Return re-ranked results
reranked = sorted(zip(retrieved, scores), key=lambda x: x[1], reverse=True)[:5]
```

### 6. Query Expansion
```python
# Add synonyms or related terms to improve recall
query_expansion_terms = ['synonym1', 'related_term2', 'associated_concept']
expanded_query = query + ' ' + ' '.join(query_expansion_terms)
```

## Tools

### Package Installation
```bash
# Core RAG packages
pip install langchain langchain-openai pymilvus

# Chunking and document processing
pip install unstructured pypdf2 python-docx mammoth

# Embedding models
pip install openai cohere sentence-transformers

# Reranking
pip install sentence-transformers

# Vector database clients
pip install pymilvus qdrant-client weaviate-client pinecone-client

# Alternative: use OpenAI's built-in vector store
# (no additional client needed if using OpenAIAssistants)
```

### Command-Line Utilities
```bash
# Check embedding dimensions
python -c "import openai; e = openai.Embedding.create(input='test', model='text-embedding-ada-002'); print(len(e['data'][0]['embedding']))"

# Test Milvus connection
python -c "from pymilvus import MilvusClient; c = MilvusClient('http://localhost:19530'); print(c.list_collections())"
```

## MCP Requirements

### Recommended MCPs
- **Milvus**: For production vector database deployment
- **PostgreSQL + pgvector**: For combined relational + vector storage
- **Redis**: For caching embedding results and session state
- **GitHub**: For code versioning and repository management

### Example MCP Configuration
```json
{
  "mcpServers": {
    "milvus": {
      "command": "docker",
      "args": ["run", "-d", "-p", "19530:19530", "-p", "19531:19531", "milvusdb/milvus:latest"],
      "description": "Milvus vector database"
    },
    "pgvector": {
      "command": "docker",
      "args": ["run", "-d", "-e", "POSTGRES_DB=rag", "-e", "POSTGRES_USER=raguser", "-e", "POSTGRES_PASSWORD=ragpass", "-p", "5432:5432", "postgres:15-pgvector"],
      "description": "PostgreSQL with pgvector extension"
    }
  }
}
```

## Best Practices

1. **Start with simple chunking**: Use RecursiveCharacterTextSplitter with reasonable chunk_size (500-1000) and chunk_overlap (100-200)
2. **Use hybrid search**: Combine vector similarity with BM25 keyword search for best recall
3. **Limit retrieval size**: Retrieve 20-30 candidates, then rerank to top 3-5 for LLM context
4. **Metadata filtering**: Always include relevant metadata (source, page, document type) for filtering and attribution
5. **Evaluate with test set**: Use a held-out test set to evaluate recall@k and answer relevance
6. **Handle edge cases**: Empty results, no matching vectors, oversized context windows
7. **Persist embeddings**: Cache embedding results to avoid recomputation on document changes
8. **Version your schema**: Track vector database schema changes across deployments

## Anti-patterns

- ❌ Chunking without overlap (breaks context across chunk boundaries)
- ❌ Using overly large chunks (exceeds context window, reduces relevance)
- ❌ Only vector search (keyword queries fail without BM25)
- ❌ No reranking (top-k vector results may include irrelevant matches)
- ❌ Missing metadata (can't filter or attribute sources)
- ❌ Infinite loops in ingestion (poorly structured documents)
- ❌ Using only one embedding model (different domains perform differently)

## Verification

### Unit Tests
```python
def test_chunking():
    from langchain.text_splitter import RecursiveCharacterTextSplitter
    text = "This is a test sentence. " * 100
    splitter = RecursiveCharacterTextSplitter(chunk_size=50, chunk_overlap=10)
    chunks = splitter.split_text(text)
    assert len(chunks) > 1
    # Verify overlap is preserved
    assert any("sentence. This is" in c for c in chunks)

def test_embedding_dimension():
    import openai
    embed = openai.Embedding.create(input="test", model="text-embedding-ada-002")
    assert len(embed['data'][0]['embedding']) == 1536

def test_milvus_connection():
    from pymilvus import MilvusClient
    # Test with non-existent host to verify error handling
    try:
        c = MilvusClient('http://invalid:19530')
        c.list_collections()
        assert False, "Should have raised connection error"
    except Exception as e:
        assert "connection" in str(e).lower() or "unreachable" in str(e).lower()
```

### Integration Tests
- End-to-end RAG pipeline with sample documents
- Query expansion improves recall
- Reranking improves relevance score
- Hybrid search (vector + BM25) outperforms vector-only

## Examples

### Basic RAG Pipeline
```python
import os
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.embeddings import OpenAIEmbeddings
from langchain.vectorstores import Milvus
from langchain.chains import RetrievalQA

# 1. Load and chunk documents
loader = UnstructuredPDFLoader("docs.pdf")
documents = loader.load()
splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
chunks = splitter.split_documents(documents)

# 2. Create vector store
embeddings = OpenAIEmbeddings()
vectorstore = Milvus.from_documents(
    chunks,
    embeddings,
    collection_name="rag_docs",
    connection_addr="localhost:19530"
)

# 3. Build RAG chain
qa_chain = RetrievalQA.from_chain_type(
    llm=OpenAI(),
    chain_type="stuff",
    retriever=vectorstore.as_retriever(search_kwargs={"k": 3})
)

# 4. Query
response = qa_chain.invoke("What is this document about?")
print(response['result'])
```

### Hybrid Search (Vector + BM25)
```python
from langchain.vectorstores import Qdrant
from langchain.retrievers import EnsembleRetriever
from langchain.schema import Document

# Vector store retriever
vector_retriever = Qdrant.from_documents(
    documents,
    embeddings,
    collection_name="docs"
).as_retriever(search_type="similarity", search_kwargs={"k": 10})

# BM25 keyword retriever (using Chroma with BM25)
keyword_retriever = ...

# Combine using EnsembleRetriever
ensemble = EnsembleRetriever(
    retrievers=[vector_retriever, keyword_retriever],
    weights=[0.7, 0.3]
)

results = ensemble.get_relevant_documents("query here")
```

### Query Expansion Example
```python
def expand_query(query, expansion_terms=None):
    if expansion_terms is None:
        expansion_terms = []
    if not expansion_terms:
        # Auto-expand using simple synonyms (basic example)
        expansion_terms = ["alternative", "related", "associated"]
    return f"{query} {' '.join(expansion_terms)}"

expanded = expand_query("web scraping", ["data extraction", "crawler"])
# Returns: "web scraping data extraction crawler"
```