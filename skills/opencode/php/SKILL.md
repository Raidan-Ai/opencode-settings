---
name: php
description: Modern PHP development skill covering PHP 8.x features (readonly, enums, match, attributes, named arguments), Composer (autoload, packages, scripts), PSR standards (PSR-4 autoloading, PSR-12 style), OOP (interfaces, traits, dependency injection), error handling and exceptions, PHPUnit testing, security (XSS, SQLi, CSRF, password_hash), performance (OPcache), PHP-FPM + nginx, and modern tooling (Pint, Rector). Use when writing, refactoring, or debugging modern PHP applications.
---

# PHP Skill

## Purpose

Provides production-grade modern PHP development capabilities: PHP 8.x language features, Composer dependency management, PSR standards, object-oriented design, robust error handling, testing with PHPUnit, security hardening, performance optimization with OPcache, and operation behind PHP-FPM/nginx.

## When to Activate

- Writing or refactoring modern PHP (8.x) code
- Managing autoloading, packages, and scripts with Composer
- Designing OOP with interfaces, traits, and dependency injection
- Handling exceptions and error logging
- Writing tests with PHPUnit
- Securing PHP apps against XSS, SQLi, and CSRF
- Optimizing performance and configuring OPcache
- Setting up or troubleshooting PHP-FPM behind nginx
- Running modern tooling like Pint and Rector

## Core Knowledge

### PHP 8.x Features

- **Readonly properties:** `public readonly string $name;`
- **Enums:** `enum Status: string { case Active = 'active'; }`
- **Match expression:** `$result = match($code) { 200 => 'ok', 404 => 'not found', default => 'other' };`
- **Attributes:** `#[Route('/path')]` for metadata.
- **Named arguments:** `htmlspecialchars(text: $input, double_encode: false)`.
- **Constructor promotion:** `function __construct(private int $id) {}`.
- **Nullsafe operator:** `$user?->profile?->bio`.

### Composer & PSR

- **PSR-4 autoloading** maps namespaces to directories in `composer.json` `autoload`/`autoload-dev`.
- **PSR-12** defines coding style (spaces, line length, strict types).
- `composer require vendor/pkg`, `composer install`, `composer dump-autoload --optimize`.

```json
{
    "autoload": {
        "psr-4": { "App\\": "src/" }
    }
}
```

## Workflow

1. **Init project** — `composer init`, set PSR-4 autoload, add strict_types.
2. **Design domain** — model with interfaces, traits, and DI containers.
3. **Implement** — write classes with constructors promoting dependencies; use enums/readonly for value objects.
4. **Handle errors** — throw typed exceptions; log with Monolog/PSR-3; never leak stack traces to users.
5. **Test** — add PHPUnit tests per class/unit; run `vendor/bin/phpunit`.
6. **Style/lint** — `vendor/bin/pint` (fix style), `vendor/bin/rector` (upgrade/refactor).
7. **Secure** — validate and sanitize all input; escape output; use `password_hash`/`password_verify`.
8. **Deploy** — configure OPcache, use Composer with `--no-dev --optimize-autoloader`, serve via PHP-FPM + nginx.

## Tools

- **Composer**: dependency manager, autoloader, scripts.
- **PHPUnit**: `vendor/bin/phpunit`.
- **Pint** (Laravel) / **PHP-CS-Fixer**: style fixing.
- **Rector**: automated refactoring and version upgrades.
- **Monolog**: PSR-3/PSR-4 logging.
- Xdebug for debugging and coverage.

## MCP Requirements

No official PHP MCP server is required. (Optional community MCP servers exist — evaluate separately; do not configure by default.)

## Best Practices

- Declare `declare(strict_types=1);` at the top of every file.
- Use type hints for parameters and returns; prefer `static`/`self` return types.
- Use enums over string-typed constants for closed sets.
- Use constructor promotion and readonly for immutable value objects.
- Follow PSR-12 style (use Pint/php-cs-fixer to enforce).
- Use namespaces matching the filesystem (PSR-4).
- Validate, sanitize, and escape all input/output boundaries.
- Use `password_hash()` with `PASSWORD_DEFAULT` for credentials.
- Use prepared statements / query builder for all SQL.
- Enable OPcache (`opcache.enable=1`, `opcache.validate_timestamps=0` in prod).

## Anti-patterns

- Using `mysql_*`/concatenated SQL (SQLi vector) — always prepared statements.
- Echoing unescaped `$_GET`/`$_POST`/`$_REQUEST` (XSS).
- Committing credentials or `.env`/config with secrets.
- Mixing global functions and global state; prefer DI.
- Using `var_dump`/`print_r`/`die()` left in committed code.
- Ignoring return types and treating `null` ambiguously.
- Disabling CSRF checks without a strong reason.
- Running Composer with dev dependencies in production.

## Verification

- `php -l path/to/file.php` passes on every changed file.
- `composer validate` passes.
- `vendor/bin/phpunit` passes.
- `vendor/bin/pint --test` (dry-run) reports no style issues.
- `php -m` shows required extensions; `opcache` enabled in production.
- Confirm error logs (Monolog / PHP error log) show no warnings during testing.
- Static analysis (`phpstan`) or at least PHPUnit coverage improvement over the changed units.

## Examples

**Enum + readonly value object:**

```php
declare(strict_types=1);

enum BookStatus: string {
    case Available = 'available';
    case Borrowed  = 'borrowed';
}

final readonly class Book
{
    public function __construct(
        public int $id,
        public string $title,
        public BookStatus $status,
    ) {}
}
```

**Dependency injection + exception handling:**

```php
declare(strict_types=1);

interface BookRepository { public function find(int $id): ?Book; }

final class BookService
{
    public function __construct(private BookRepository $repo) {}

    public function getBook(int $id): Book
    {
        $book = $this->repo->find($id);
        if ($book === null) {
            throw new \InvalidArgumentException("Book $id not found");
        }
        return $book;
    }
}
```

**PSR-12 style + security (escaping output):**

```php
declare(strict_types=1);

function renderTitle(string $raw): string
{
    return '<h1>' . htmlspecialchars($raw, ENT_QUOTES, 'UTF-8') . '</h1>';
}
```
