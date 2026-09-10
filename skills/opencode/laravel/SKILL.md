---
name: laravel
description: Laravel/PHP framework development skill covering artisan commands (make, migrate, tinker), Eloquent ORM, migrations/seeders, Blade templating, routing/controllers/middleware, validation, auth (Sanctum/Breeze/Jetstream), queues (Horizon), events/listeners, testing (Pest/PHPUnit), API resources, caching (Redis), Livewire/Inertia basics, and Laravel Sail (Docker). Use when building, extending, or debugging Laravel applications.
---

# Laravel Skill

## Purpose

Provides production-grade Laravel development capabilities: artisan workflows, Eloquent ORM, Blade templating, routing/controllers/middleware, validation, authentication (Sanctum, Breeze, Jetstream), queues and Horizon, events/listeners, testing with Pest/PHPUnit, API resources, caching, and Livewire/Inertia.

## When to Activate

- Scaffolding or structuring a Laravel application
- Creating models, controllers, migrations, or seeders with artisan
- Interacting with Eloquent ORM (queries, relationships, accessors/mutators)
- Writing Blade templates or components
- Defining routes, controllers, and middleware
- Implementing authentication or API tokens (Sanctum) or auth scaffolding (Breeze/Jetstream)
- Setting up queues, jobs, and Horizon
- Using events and listeners
- Writing tests with Pest or PHPUnit
- Building with Livewire or Inertia
- Running the app locally with Laravel Sail (Docker)

## Core Knowledge

### Application Structure (`app/`)

- `app/Http/Controllers` — HTTP controllers
- `app/Models` — Eloquent models
- `app/Http/Middleware` — request middleware
- `app/Providers` — service providers and event registration
- `app/Observers`, `app/Listeners`, `app/Jobs`, `app/Events` — domain logic
- `routes/web.php` and `routes/api.php` — route definitions

### Eloquent Relationships

```php
class Post extends Model { public function user() { return $this->belongsTo(User::class); } }
class User extends Model { public function posts() { return $this->hasMany(Post::class); } }
```

## Workflow

1. **Scaffold** — `composer create-project laravel/laravel app` (or `laravel new app --jet`).
2. **Model + migration** — `php artisan make:model Post -m`; edit the migration, then `php artisan migrate`.
3. **Controller + route** — `php artisan make:controller PostController -r`; wire routes in `routes/web.php`.
4. **Add data** — create a seeder and `php artisan db:seed`; use factories for tests.
5. **Build UI** — Blade views/components; add Livewire or Inertia for reactivity.
6. **Authenticate** — Sanctum for SPA/API tokens, Breeze/Jetstream for auth scaffolding (Fortify).
7. **Async work** — push jobs to queues; run Horizon, `php artisan queue:work`.
8. **Test** — PHPUnit/Pest; run `php artisan test`.
9. **Deploy** — optimize config/routes/views, run migrations, cache config.

## Tools

- **artisan**: `php artisan make:model`, `make:controller`, `migrate`, `tinker`, `db:seed`, `route:list`, `queue:work`, `horizon`, `cache:clear`, `config:cache`, `optimize`.
- **Laravel Sail**: `./vendor/bin/sail up -d`, `sail artisan`, `sail composer`, `sail mysql` (Docker-based).
- Composer, npm/Vite (for frontend build), Telescope (debugging).

## MCP Requirements

No standard official Laravel MCP server is required. (Optional community MCP servers exist — evaluate separately; do not configure by default.)

## Best Practices

- Follow PSR-4 autoloading and Laravel directory conventions.
- Use Eloquent with eager loading (`with()`) to avoid N+1 queries.
- Use Form Requests for validation instead of validating inline.
- Use route model binding and resource controllers.
- Store app secrets in `.env`; never commit them.
- Use queues for slow/3rd-party work; set `QUEUE_CONNECTION=database` or Redis.
- Use `php artisan route:cache`, `config:cache`, `view:cache` in production.
- Write feature tests with factories and `RefreshDatabase`.
- Use type hints, return types, and PHP 8 features (readonly, enums, match).
- Use dependency injection and service containers rather than static facades where clarity benefits.

## Anti-patterns

- Running `php artisan` in production against non-migrated/dirty databases without backups.
- Deep Eloquent `where()` on unindexed columns causing slow queries.
- Using raw DB queries everywhere instead of the query builder/Eloquent (still use `DB::raw` carefully).
- Committing `.env` with credentials.
- Putting business logic in controllers instead of services/actions.
- Using `env()` outside config files (should read config() only).
- Ignoring the N+1 problem in Blade loops.
- Disabling CSRF or doing insecure mass assignment against `$fillable`.

## Verification

- `php artisan migrate` completes without errors.
- `php artisan test` (or `phpunit/pest`) passes.
- `php artisan route:list` shows expected routes.
- `php -l` passes on all changed files (or use Pint style/lint).
- `php artisan config:cache && php artisan route:cache && php artisan view:cache` succeed in production.
- Confirm queue worker processes jobs (`php artisan queue:work`) without failures.
- Check `storage/logs/laravel.log` for errors during manual testing.

## Examples

**Model + relationship:**

```php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Book extends Model
{
    protected $fillable = ['title', 'author_id'];

    public function author(): HasMany
    {
        return $this->belongsTo(Author::class);
    }
}
```

**Controller with validation:**

```php
namespace App\Http\Controllers;

use App\Http\Requests\StoreBookRequest;
use App\Models\Book;
use Illuminate\Http\RedirectResponse;

class BookController extends Controller
{
    public function store(StoreBookRequest $request): RedirectResponse
    {
        $book = Book::create($request->validated());
        return redirect()->route('books.show', $book);
    }
}
```

**Form Request:**

```php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreBookRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'title'  => ['required', 'string', 'max:255'],
            'author_id' => ['required', 'exists:authors,id'],
        ];
    }
}
```

**Queue job:**

```php
class ProcessBook implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(public Book $book) {}

    public function handle(): void
    {
        // long-running work
    }
}
```
