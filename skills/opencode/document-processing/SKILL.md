# Document Processing Skill

## Purpose
Provides document ingestion, parsing, and extraction capabilities using Unstructured, OCRmyPDF, Tesseract, Apache Tika, and PyMuPDF. Enables converting raw documents (PDF, DOCX, images) into machine-readable text for RAG pipelines and data engineering workflows.

## When to Activate
- Converting PDF/DOCX/HTML files to structured text
- Optical Character Recognition (OCR) on scanned documents
- Extracting tables, images, and metadata from documents
- Document normalization for RAG ingestion
- Batch processing large document collections

## Core Knowledge

### Document Processing Pipeline
```
Input Documents → Classification → Extraction → Normalization → Output
     ↓                ↓              ↓             ↓             ↓
  PDF/DOCX/     Detect file    Text/Table/   Clean/Structure  JSON/TXT/
  Images/HTML   type           Image/Meta    text            Markdown
```

### File Format Handling

#### PDF Processing
- **PyMuPDF (fitz)**: Fast text extraction, metadata, embedded images
- **Unstructured**: Advanced PDF parsing with layout detection
- **OCRmyPDF**: Adds searchable text layer to scanned PDFs
- **pdfplumber**: Table extraction with character-level precision

#### DOCX Processing
- **python-docx**: Native DOCX text extraction
- **mammoth**: DOCX → HTML/Markdown conversion

#### Image OCR
- **Tesseract**: Open-source OCR engine
- **PyTesseract**: Python wrapper for Tesseract
- **EasyOCR**: Deep learning OCR
- **PaddleOCR**: Advanced multilingual OCR

### OCR Techniques
```python
# Basic Tesseract OCR
import pytesseract
from PIL import Image

image = Image.open('scanned_page.png')
text = pytesseract.image_to_string(image, lang='eng')
print(text)

# OCR with pre-processing (better accuracy)
import cv2
import numpy as np

# Convert to grayscale and threshold
gray = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2GRAY)
_, thresh = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

# OCR the thresholded image
text = pytesseract.image_to_string(Image.fromarray(thresh), lang='eng')
```

### Table Extraction
```python
import pdfplumber

with pdfplumber.open('document.pdf') as pdf:
    page = pdf.pages[0]
    table = page.extract_table()
    
    # Convert to DataFrame
    import pandas as pd
    df = pd.DataFrame(table[1:], columns=table[0])
    print(df.head())
```

### Metadata Extraction
```python
import fitz  # PyMuPDF

doc = fitz.open('document.pdf')
metadata = doc.metadata
print(metadata)
# Output: {'format': 'PDF 1.7', 'title': '...', 'author': '...',
#          'subject': '...', 'keywords': '...', ...}

# Extract embedded images
for i, page in enumerate(doc):
    images = page.get_images()
    for img in images:
        xref = img[0]
        pix = fitz.Pixmap(doc, xref)
        if pix.n - pix.alpha < 4:  # Non-CMYK
            pix.save(f'page_{i}_image_{xref}.png')
```

## Workflow

### 1. Multi-Format Document Processing
```python
from unstructured.partition.auto import partition

def process_document(filepath):
    """Process any document type to structured text"""
    # Unstructured auto-detects file type
    elements = partition(filename=filepath)
    
    # Extract text content
    text = '\n\n'.join([str(e) for e in elements])
    
    # Extract metadata
    metadata = {
        'file_path': filepath,
        'file_type': filepath.split('.')[-1],
        'element_count': len(elements),
    }
    
    return text, metadata

text, meta = process_document('report.pdf')
print(f"Extracted {len(text)} characters from {meta['file_type']}")
```

### 2. OCR Pipeline for Scanned Documents
```python
import os
import fitz
import pytesseract
from PIL import Image
import io

def ocr_scanned_pdf(pdf_path, output_dir='ocr_output'):
    """OCR scanned PDF pages"""
    os.makedirs(output_dir, exist_ok=True)
    doc = fitz.open(pdf_path)
    all_text = []
    
    for page_num in range(len(doc)):
        # Extract page as image
        page = doc[page_num]
        pix = page.get_pixmap(dpi=200)  # 200 DPI for good OCR
        img_bytes = pix.tobytes('png')
        img = Image.open(io.BytesIO(img_bytes))
        
        # OCR the image
        text = pytesseract.image_to_string(img)
        all_text.append(text)
        
        # Save per-page result
        with open(f'{output_dir}/page_{page_num + 1}.txt', 'w') as f:
            f.write(text)
    
    doc.close()
    return '\n\n'.join(all_text)

text = ocr_scanned_pdf('scanned_book.pdf')
print(f"OCR'd {len(text)} characters")
```

### 3. Docx Processing
```python
from docx import Document
from docx.opc.constants import RELATIONSHIP_TYPE

def process_docx(filepath):
    """Extract text, tables, and images from DOCX"""
    doc = Document(filepath)
    
    # Extract paragraphs
    paragraphs = [p.text for p in doc.paragraphs if p.text.strip()]
    
    # Extract tables
    tables = []
    for table in doc.tables:
        rows = []
        for row in table.rows:
            rows.append([cell.text for cell in row.cells])
        tables.append(rows)
    
    # Extract images
    images = []
    for rel in doc.part.rels.values():
        if "image" in rel.reltype:
            images.append(rel.target_part.blob)
    
    return {
        'paragraphs': paragraphs,
        'tables': tables,
        'image_count': len(images)
    }

result = process_docx('report.docx')
print(f"Found {len(result['paragraphs'])} paragraphs, {len(result['tables'])} tables, {result['image_count']} images")
```

### 4. Document Normalization for RAG
```python
import hashlib
import json
from unstructured.partition.auto import partition

def normalize_for_rag(filepath, chunk_size=1000, chunk_overlap=200):
    """Normalize a document into RAG-ready chunks"""
    # Extract raw text
    elements = partition(filename=filepath)
    full_text = '\n\n'.join([str(e) for e in elements])
    
    # Split into chunks
    chunks = []
    for i in range(0, len(full_text), chunk_size - chunk_overlap):
        chunk = full_text[i:i + chunk_size]
        if len(chunk.strip()) < 50:  # Skip tiny chunks
            continue
        
        chunks.append({
            'id': hashlib.md5(chunk.encode()).hexdigest(),
            'text': chunk,
            'source': filepath,
            'chunk_index': len(chunks)
        })
    
    return chunks

chunks = normalize_for_rag('manual.pdf')
print(f"Normalized document into {len(chunks)} chunks")
print(json.dumps(chunks[0], indent=2))
```

### 5. Multimodal Document Processing
```python
from unstructured.partition.auto import partition

def process_multimodal(filepath):
    """Extract text AND images from documents"""
    elements = partition(filename=filepath, strategy="hi_res")
    
    text_elements = []
    image_elements = []
    
    for element in elements:
        if element.category == "Image":
            image_elements.append({
                'image_path': element.metadata.image_path,
                'caption': element.text if hasattr(element, 'text') else ''
            })
        elif element.category in ("Text", "Title", "Header", "Footer"):
            text_elements.append(str(element))
    
    return {
        'text': '\n\n'.join(text_elements),
        'images': image_elements
    }

result = process_multimodal('product_catalog.pdf')
print(f"Extracted {len(result['text'])} chars of text, {len(result['images'])} images")
```

## Tools

### Package Installation
```bash
# Core PDF processing
pip install pymupdf pdfplumber

# Document parsing (Unstructured)
pip install "unstructured[pdf,docx,pptx]"

# OCR
pip install pytesseract pillow
# Tesseract binary: sudo apt-get install tesseract-ocr

# OCR with image processing
pip install opencv-python-headless

# DOCX processing
pip install python-docx mammoth

# DataFrame handling
pip install pandas

# Batch processing
pip install concurrent-futures
```

### Command-Line Utilities
```bash
# Tesseract CLI (direct)
tesseract image.png output.txt -l eng

# OCRmyPDF (add searchable text to scanned PDFs)
ocrmypdf input.pdf output.pdf

# PDF text extraction with pdftotext (poppler-utils)
pdftotext input.pdf output.txt

# Install poppler-utils for pdfplumber dependencies
sudo apt-get install poppler-utils
```

### MCP Integration
```json
{
  "mcpServers": {
    "document-processing": {
      "command": "npx",
      "args": ["-y", "document-processing-mcp"],
      "description": "Document extraction MCP server",
      "tools": ["extract_pdf", "extract_docx", "ocr_image", "chunk_document"]
    }
  }
}
```

## Best Practices

1. **Choose extraction strategy by document type**:
   - Text PDFs: Unstructured (fast, accurate)
   - Scanned PDFs: OCR pipeline (Tesseract/OCRmyPDF)
   - Complex layouts: Unstructured with `strategy="hi_res"` for OCR-based extraction
   
2. **Pre-process images for better OCR**:
   - Convert to grayscale
   - Apply thresholding (OTSU)
   - Increase DPI to 200-300 for scanned documents
   - Use `--psm 6` for blocks of text, `--psm 4` for sparse text

3. **Handle encoding and special characters**:
   - Use `encoding='utf-8'` when writing extracted text
   - Normalize whitespace (collapse multiple spaces/newlines)
   - Handle non-breaking spaces and em-dashes

4. **Batch processing strategy**:
   - Use `concurrent.futures.ThreadPoolExecutor` for parallel processing
   - Track processed files to avoid re-processing
   - Save intermediate results (per-page, per-document) for resumability

5. **Metadata always**:
   - Preserve source filename, page number, and document type
   - Include extraction timestamp and method used
   - Attach confidence scores for OCR results

## Anti-patterns

- ❌ OCR-ing text-based PDFs (wastes time and degrades quality)
- ❌ Extracting without preserving page order (breaks document structure)
- ❌ Ignoring scanned-image PDFs (they need OCR, not text extraction)
- ❌ Using `partition()` without checking for empty results
- ❌ Not handling multi-line table cells (corrupted tabular data)
- ❌ Storing binary images without metadata (orphaned data)

## Verification

### Unit Tests
```python
def test_pdf_text_extraction():
    import fitz
    doc = fitz.open('test.pdf')
    page = doc[0]
    text = page.get_text()
    assert len(text) > 50  # Has meaningful content
    doc.close()

def test_docx_paragraph_extraction():
    from docx import Document
    doc = Document('test.docx')
    paragraphs = [p.text for p in doc.paragraphs if p.text.strip()]
    assert len(paragraphs) > 0

def test_ocr_returns_text():
    import pytesseract
    from PIL import Image
    # Create a simple test image with text
    img = Image.new('RGB', (400, 100), 'white')
    # (In practice, draw text on this image)
    text = pytesseract.image_to_string(img)
    assert isinstance(text, str)

def test_unstructured_partition():
    from unstructured.partition.auto import partition
    elements = partition(filename='test.pdf')
    assert len(elements) > 0
    assert hasattr(elements[0], 'text')
```

### Integration Tests
- End-to-end: PDF → Text → Chunks → RAG-ready format
- Batch: Process 10+ files with parallel processing
- OCR: Scanned PDF → Searchable text (verify with keywords)
- Table: Invoice PDF → Structured table data

## Examples

### Complete Document Processing Service
```python
import os
import fitz
import concurrent.futures
from dataclasses import dataclass
from typing import List, Dict

@dataclass
class ProcessedDocument:
    filename: str
    text: str
    pages: int
    metadata: Dict
    chunks: List[str]

def extract_text_single(pdf_path: str) -> ProcessedDocument:
    """Extract text from a single PDF (worker function)"""
    doc = fitz.open(pdf_path)
    pages_text = []
    
    for page in doc:
        pages_text.append(page.get_text())
    
    full_text = '\n\n'.join(pages_text)
    doc.close()
    
    # Simple chunking
    chunks = []
    for i in range(0, len(full_text), 900):
        chunks.append(full_text[i:i + 1000])
    
    return ProcessedDocument(
        filename=os.path.basename(pdf_path),
        text=full_text,
        pages=len(pages_text),
        metadata={'pages': len(pages_text), 'chars': len(full_text)},
        chunks=chunks
    )

def process_pdf_batch(pdf_paths: List[str], max_workers=4) -> List[ProcessedDocument]:
    """Process multiple PDFs in parallel"""
    results = []
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = {executor.submit(extract_text_single, path): path for path in pdf_paths}
        for future in concurrent.futures.as_completed(futures):
            result = future.result()
            results.append(result)
            print(f"Processed {result.filename}: {len(result.chunks)} chunks")
    
    return results

# Usage
pdf_files = ['doc1.pdf', 'doc2.pdf', 'doc3.pdf']
processed = process_pdf_batch(pdf_files)
total_chunks = sum(len(d.chunks) for d in processed)
print(f"Processed {len(processed)} documents -> {total_chunks} total chunks")
```