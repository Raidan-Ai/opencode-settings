# Web Research & Scraping Skill

## Purpose
Provides comprehensive web research, scraping, and browser automation capabilities using Playwright, Crawlee, Firecrawl, and other tools. Enables automated data extraction from websites, dynamic content rendering, and structured research workflows.

## When to Activate
- Building web research agents or bots
- Extracting data from websites for LLM applications
- Dynamic content rendering (JavaScript-heavy sites)
- Competitive research, price monitoring, lead generation
- Content aggregation and RAG source collection
- API reverse-engineering and form submission

## Core Knowledge

### Web Scraping Methodologies

#### Static Site Scraping
- **Tool**: BeautifulSoup, lxml, Cheerio (Node)
- **Use case**: Simple HTML pages without JavaScript
- **Workflow**: Fetch HTML → Parse → Extract → Store

#### Dynamic Site Scraping
- **Tool**: Playwright, Puppeteer, Selenium
- **Use case**: JavaScript-rendered sites, SPA, infinite scroll
- **Workflow**: Launch browser → Navigate → Wait for content → Extract → Screenshot

#### API Scraping
- **Tool**: requests, httpx, aiohttp
- **Use case**: Reverse-engineered APIs, JSON endpoints
- **Workflow**: Inspect network → Make API calls → Handle auth → Parse JSON

### Playwright Architecture
```
Browser Types
┌────────────────────────────────────┐
│ Chromium (default)                 │
│ Firefox                              │
│ WebKit (Safari emulation)          │
└────────────────────────────────────┘
          ↓
      Browser
          ↓
      Context (isolated storage/cookies)
          ↓
      Page / Frame
          ↓
      ElementHandle / Locator
```

### Playwright Selectors
- **CSS Selectors**: `page.locator('button.submit')`
- **Text Selectors**: `page.locator(:text('Submit'))`
- **Role Selectors**: `page.getByRole('button', {name: 'Submit'})`
- **XPath**: `page.locator('//button[@type="submit"]')`

### Crawlee Framework
- **Router**: Handles URL routing and request management
- **Request Pool**: Manages concurrent requests with concurrency limits
- **Session**: Persists cookies and state across requests
- **Proxy Configuration**: Rotating proxies for large-scale scraping

### Firecrawl Service
- **Full-page extraction**: Extract clean text/HTML from any page
- **Sitemap generation**: Auto-discover and crawl sitemaps
- **API integration**: REST API for scalable crawling
- **Output formats**: Markdown, JSON, HTML cleaning

## Workflow

### 1. Playwright Basic Scraping
```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    # Launch browser (headless by default)
    browser = p.chromium.launch(headless=True)
    context = browser.new_context()
    page = context.new_page()
    
    # Navigate to page
    page.goto('https://example.com')
    
    # Wait for specific element
    page.wait_for_selector('h1')
    
    # Extract title
    title = page.title()
    
    # Extract all links
    links = page.locator('a').all_inner_texts()
    
    # Take screenshot
    page.screenshot(path='screenshot.png')
    
    # Close
    browser.close()
    
    print(f"Title: {title}")
    print(f"Found {len(links)} links")
```

### 2. Playwright with Wait Strategies
```python
from playwright.sync_api import sync_playwright, TimeoutError as PlaywrightTimeout

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto('https://dynamic-site.com')
    
    # Wait for network idle (default: wait until 'load')
    page.wait_for_load_state('networkidle')
    
    # Wait for specific element with timeout
    try:
        page.wait_for_selector('.product-card', timeout=10000)
        cards = page.locator('.product-card').all()
        print(f"Found {len(cards)} product cards")
    except PlaywrightTimeout:
        print("Timed out waiting for product cards")
    
    browser.close()
```

### 3. Infinite Scroll Scraping
```python
from playwright.sync_api import sync_playwright

def scrape_infinite_scroll(url, max_scrolls=20):
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        page.goto(url)
        
        last_height = page.evaluate("document.body.scrollHeight")
        scrolls = 0
        
        while scrolls < max_scrolls:
            # Scroll to bottom
            page.evaluate("window.scrollTo(0, document.body.scrollHeight)")
            page.wait_for_timeout(1000)  # Wait for content to load
            
            new_height = page.evaluate("document.body.scrollHeight")
            if new_height == last_height:
                # No new content loaded
                break
            last_height = new_height
            scrolls += 1
        
        # Extract data
        items = page.locator('.item').all_inner_texts()
        browser.close()
        return items

results = scrape_infinite_scroll('https://example.com/feed', max_scrolls=10)
print(f"Scraped {len(results)} items")
```

### 4. Playwright with Authentication
```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=False)  # Headful for manual auth
    context = browser.new_context(
        # Store auth state
        storage_state='auth.json'
    )
    page = context.new_page()
    page.goto('https://login-required.com')
    
    # Manual login or use stored state
    # ... login flow ...
    
    # Save auth state for future use
    context.storage_state(path='auth.json')
    
    # Now authenticated pages work
    page.goto('https://dashboard.com')
    print(page.title())
    
    browser.close()
```

### 5. Crawlee Scraping Example
```python
from crawlee import *
from crawlee.router import Router
from crawlee.requests import Request
from crawlee.storage_keywords import RequestQueue, Dataset

async def main():
    # Initialize crawler
    crawler = WebCrawler(
        max_requests_per_crawl=100,
        max_crawl_time_secs=300,
    )
    
    # Add start URL
    await crawler.add_request(Request(url='https://example.com'))
    
    # Define request handler
    async def handle_request(context, request):
        page = context.playwright_page
        await page.goto(request.url)
        
        # Extract data
        title = await page.title()
        price = await page.locator('.price').text_content()
        
        # Save to dataset
        await context.push_data({
            'url': request.url,
            'title': title,
            'price': price,
        })
    
    # Run crawler
    await crawler.run()

if __name__ == '__main__':
    import asyncio
    asyncio.run(main())
```

### 6. Firecrawl Integration
```python
import requests

# Initialize Firecrawl API
FIRECRAWL_API_KEY = "your_key_here"

def firecrawl_scrape(url):
    """Scrape and extract clean content from a URL"""
    response = requests.post(
        f"https://api.firecrawl.ai/v1/scrape",
        json={"url": url},
        headers={"Authorization": f"Bearer {FIRECRAWL_API_KEY}"}
    )
    return response.json()

def firecrawl_sitemap(url):
    """Generate sitemap for a domain"""
    response = requests.post(
        f"https://api.firecrawl.ai/v1/sitemap",
        json={"url": url},
        headers={"Authorization": f"Bearer {FIRECRAWL_API_KEY}"}
    )
    return response.json()

# Usage
data = firecrawl_scrape('https://blog.example.com/post-1')
print(f"Extracted {len(data.get('data', {}).get('text', ''))} chars")
```

### 7. Browser Automation with Playwright
```python
from playwright.sync_api import sync_playwright
import time

def browser_automation():
    with sync_playwright() as p:
        # Launch with debug mode for observation
        browser = p.chromium.launch(headless=False)
        context = browser.new_context()
        page = context.new_page()
        
        # Navigate and interact
        page.goto('https://www.google.com')
        
        # Fill search box
        page.fill('textarea[aria-label="Search"]', 'playwright python')
        
        # Click search button
        page.click('button[aria-label="Google Search"]')
        
        # Wait for results
        page.wait_for_load_state('networkidle')
        
        # Extract first result
        first_result = page.locator('h3').first
        result_text = first_result.text_content()
        print(f"First result: {result_text}")
        
        # Take screenshot
        page.screenshot(path='search-results.png')
        
        # Close
        browser.close()

browser_automation()
```

## Tools

### Package Installation
```bash
# Core: Playwright with browsers
pip install playwright
playwright install  # Install browsers

# Alternative: Crawlee
pip install crawlee

# Firecrawl API
pip install firecrawl-py

# BeautifulSoup (static scraping)
pip install beautifulsoup4 lxml

# HTTP client (API scraping)
pip install httpx aiohttp

# Requests fallback
pip install requests

# Data storage
pip install pandas
```

### Command-Line Utilities
```bash
# Install Playwright browsers
playwright install

# Check Playwright installation
playwright test --help

# Run a simple Playwright script
python -c "
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto('https://example.com')
    print(f'Page title: {page.title()}')
    browser.close()
"
```

### MCP Integration
```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp", "--browser", "chrome"],
      "description": "Playwright MCP server for browser automation",
      "ports": ["puppeteer", "playwright"],
      "health_check": {
        "command": ["curl", "-f", "http://localhost:port/health"],
        "interval": 30000
      }
    },
    "firecrawl": {
      "type": "http",
      "url": "https://mcp.firecrawl.ai/mcp",
      "description": "Firecrawl MCP for web scraping and extraction",
      "requires_api_key": true
    }
  }
}
```

### Verification Script
```bash
python -c "
from playwright.sync_api import sync_playwright
import sys

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto('https://example.com')
    assert page.title() == 'Example Domain', f'Unexpected title: {page.title()}'
    browser.close()
    print('Playwright verification: PASSED')
    sys.exit(0)
"
```

## Best Practices

1. **Always use headless mode in production**: Unless debugging, launch browsers in headless mode for performance
2. **Respect robots.txt**: Check robots.txt before scraping; honor crawl delays
3. **Add appropriate delays**: Between requests to avoid rate limiting and being blocked
4. **Use explicit waits**: Prefer `wait_for_selector` over `wait_for_timeout` when possible
5. **Handle modals and overlays**: Dismiss cookie banners, age verification, etc. before extracting
6. **Rotate user agents**: Use different user agents for multiple requests to same domain
7. **Error handling**: Gracefully handle 404s, timeouts, and element-not-found scenarios
8. **Clean up resources**: Always close browsers/contexts in finally blocks
9. **Store authentication state**: Save `storage_state.json` after login to avoid repeated auth
10. **Respect terms of service**: Don't scrape copyrighted content or violate ToS

## Anti-patterns

- ❌ Using `wait_for_timeout` excessively (use explicit waits instead)
- ❌ Scraping at maximum speed without any delays (getting IP blocked)
- ❌ Not handling dynamic content loading (missing data)
- ❌ Ignoring cookie consent and overlays (broken extraction)
- ❌ Using the same browser instance for unrelated tasks (state contamination)
- ❌ Not handling pagination (incomplete data)
- ❌ Extracting without checking content validity (garbage data)
- ❌ Storing sensitive credentials in code (use env vars or secret management)

## Verification

### Unit Tests
```python
def test_playwright_basic():
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        page.goto('https://example.com')
        assert page.title() == 'Example Domain'
        browser.close()

def test_playwright_navigation():
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        page.goto('https://example.com')
        # Click on link
        page.click('text=More information...')
        page.wait_for_load_state('networkidle')
        assert 'more' in page.url.lower() or 'about' in page.url.lower()
        browser.close()

def test_crawlee_import():
    import crawlee
    assert crawlee is not None
    print('Crawlee import: PASSED')
```

### Integration Tests
- End-to-end scraping: Navigate → Extract → Verify data correctness
- Playwright browser launch and page navigation
- Crawlee request handling and dataset storage
- Firecrawl API integration and response parsing

## Examples

### Complete Scraping Pipeline
```python
import asyncio
from playwright.async_api import async_playwright
import pandas as pd

async def scrape_quotes_page():
    """Scrape quotes from a multi-page website"""
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context()
        page = await context.new_page()
        
        all_quotes = []
        page_num = 1
        
        while True:
            await page.goto(f'https://quotes.toscrape.com/page/{page_num}')
            await page.wait_for_selector('.quote')
            
            # Extract quotes on current page
            quotes = await page.locator('.quote').all()
            for quote in quotes:
                text = quote.locator('.text').text_content()
                author = quote.locator('.author').text_content()
                all_quotes.append({
                    'text': text,
                    'author': author,
                    'page': page_num
                })
            
            # Check for next page
            next_btn = page.locator('.next')
            if await next_btn.is_disabled():
                break
            page_num += 1
        
        await browser.close()
        return all_quotes

# Run and save to CSV
quotes = asyncio.run(scrape_quotes_page())
df = pd.DataFrame(quotes)
df.to_csv('quotes_scraped.csv', index=False)
print(f"Scraped {len(quotes)} quotes across {page_num} pages")
```

### Playwright with Proxy
```python
from playwright.sync_api import sync_playwright

def scrape_with_proxy():
    with sync_playwright() as p:
        browser = p.chromium.launch(
            headless=True,
            proxy={
                'server': 'http://proxy.example.com:8080',
                'username': 'proxy_user',  # optional
                'password': 'proxy_pass',  # optional
            }
        )
        page = browser.new_page()
        page.goto('https://httpbin.org/ip')
        ip_info = page.text_content('body')
        print(f"Connection through proxy: {ip_info}")
        browser.close()

scrape_with_proxy()
```

### Hybrid Search: Playwright + Firecrawl
```python
import requests
from playwright.sync_api import sync_playwright

def comprehensive_scrape(url, use_firecrawl=False):
    """Scrape a URL using best available method"""
    if use_firecrawl:
        # Use Firecrawl API for clean extraction
        FIRECRAWL_KEY = "your_key"
        resp = requests.post(
            "https://api.firecrawl.ai/v1/scrape",
            json={"url": url},
            headers={"Authorization": f"Bearer {FIRECRAWL_KEY}"}
        )
        data = resp.json()
        return data.get('data', {}).get('text', '')
    else:
        # Use Playwright for dynamic sites
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            page = browser.new_page()
            page.goto(url)
            page.wait_for_load_state('networkidle')
            # Extract main content
            content = page.locator('.main-content, article').inner_text()
            browser.close()
            return content

text = comprehensive_scrape('https://example.com/article')
print(f"Extracted {len(text)} characters")
```