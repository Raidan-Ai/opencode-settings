---
name: wordpress
description: WordPress development skill covering wp-cli (core, plugins, themes, db), theme development (template hierarchy, functions.php, hooks: actions/filters), plugin development (add_action/add_filter, shortcodes, custom post types, REST API), child themes, PHP version compatibility, security (nonces, escaping, sanitization), performance (caching, object cache, query optimization), deployment (wp-config, uploads, DB sync), and Gutenberg blocks. Use when building, customizing, or maintaining WordPress sites, themes, or plugins.
---

# WordPress Skill

## Purpose

Provides production-grade WordPress development capabilities: theme and plugin development, wp-cli management, the hooks (action/filter) system, custom post types and taxonomies, the REST API, child themes, security hardening, performance optimization, and deployment/sync workflows.

## When to Activate

- Building or modifying WordPress themes or child themes
- Writing or extending WordPress plugins
- Using wp-cli to manage core, plugins, themes, or the database
- Registering custom post types, taxonomies, or meta fields
- Exposing or consuming the WordPress REST API
- Hardening a WordPress site (nonces, escaping, sanitization, roles)
- Optimizing WordPress performance (caching, queries, object cache)
- Deploying or syncing WordPress between environments
- Building Gutenberg blocks

## Core Knowledge

### Hooks: Actions vs. Filters

- **Actions** (`do_action`, `add_action`): run code at specific points; no return value.
- **Filters** (`apply_filters`, `add_filter`): modify data passed through; return the modified value.

```php
// Action: run code when the theme loads
add_action( 'after_setup_theme', function () {
    add_theme_support( 'post-thumbnails' );
}, 0 );

// Filter: modify the excerpt length
add_filter( 'excerpt_length', function ( $length ) {
    return 20;
} );
```

### Template Hierarchy

WordPress resolves the most specific template first:

```
single-{post-type}-{slug}.php → single-{post-type}.php → single.php → singular.php → index.php
archive-{taxonomy}.php → archive-{post-type}.php → archive.php → index.php
```

### Loop Pattern

```php
if ( have_posts() ) :
    while ( have_posts() ) : the_post();
        the_title( '<h2>', '</h2>' );
        the_content();
    endwhile;
endif;
```

## Workflow

1. **Set up local dev** — use a local environment, then configure wp-config.php with unique salts and debug constants.
2. **Theme development** — create `style.css` (theme header), `functions.php`, and template files; use child themes for production override.
3. **Plugin development** — register with a plugin header; hook into WordPress with `register_activation_hook`, `add_action`, `add_filter`.
4. **Extend data** — register custom post types via `register_post_type()` and taxonomies via `register_taxonomy()`.
5. **Expose data** — register REST routes with `register_rest_route()` and secure them.
6. **Harden** — validate/sanitize/escape all I/O; use nonces for forms and AJAX.
7. **Optimize** — enable object cache, cache queries, avoid N+1, enqueue assets properly.
8. **Deploy** — migrate files and database; run `wp-cli db` and `search-replace` carefully.

## Tools

- **wp-cli**: `wp core install`, `wp plugin install`, `wp theme activate`, `wp db export`, `wp option get`, `wp post list`, `wp search-replace`.

```bash
wp core download --version=6.4
wp core config --dbname=db --dbuser=user --dbpass=pass
wp core install --url=example.com --title="Site" --admin_user=admin --admin_password=pass --admin_email=you@example.com
wp plugin install woocommerce --activate
```

- Composer for dependency management; npm/webpack for building blocks.

## MCP Requirements

No official WordPress MCP server is required or configured. Use **wp-cli** as the primary operational interface. (Optional community MCP servers exist but are not officially maintained — verify before adopting.)

## Best Practices

- Always escape output: `esc_html()`, `esc_url()`, `esc_attr()`, `esc_textarea()`.
- Always sanitize input: `sanitize_text_field()`, `sanitize_email()`, `absint()`.
- Use nonces: `wp_nonce_field()` + `check_admin_referer()` / `check_ajax_referer()`.
- Use `wp_enqueue_script`/`wp_enqueue_style` with proper dependencies and versioning; avoid outputting raw JS/CSS.
- Use `WP_Query` with `'no_found_rows' => true` and `'posts_per_page'` when pagination is not needed.
- Register asset handles only where needed to avoid conflicts.
- Follow PHP coding standards (WordPress Coding Standards: tabs, Yoda conditions, `return` defaults).
- Prefix all functions, classes, and option keys with a unique project prefix to avoid collisions.
- Use a child theme for any production overrides of a parent theme.

## Anti-patterns

- Echoing unescaped user input (XSS vector).
- Inserting data without sanitization (SQLi via `$wpdb` — always use `$wpdb->prepare()`).
- Adding jQuery directly or registering duplicate scripts.
- Calling `query_posts()` — use `WP_Query` or `pre_get_posts`.
- Hardcoding site URLs or paths that break on migration.
- Using `file_get_contents()` on remote URLs (use the HTTP API: `wp_remote_get`).
- Performing DB `search-replace` without a full backup and dry-run first.

## Verification

- Run `wp core check-update`, `wp plugin list --status=active`, `wp theme list`.
- Check PHP lint: `php -l` on each changed file.
- Enable `WP_DEBUG`/`WP_DEBUG_LOG` and confirm no notices/warnings.
- Test with `phpcs` against WordPress Coding Standards if available.
- Confirm REST endpoints return expected JSON and enforce capability checks.
- On deploy, verify uploads permissions and `wp-content` writes.

## Examples

**Custom post type:**

```php
add_action( 'init', function () {
    register_post_type( 'book', [
        'public'   => true,
        'label'    => 'Books',
        'supports' => [ 'title', 'editor', 'thumbnail' ],
        'has_archive' => true,
        'rewrite'  => [ 'slug' => 'books' ],
    ] );
} );
```

**Shortcode:**

```php
add_shortcode( 'book_list', function ( $atts ) {
    $atts = shortcode_atts( [ 'count' => 5 ], $atts, 'book_list' );
    $q = new WP_Query( [ 'post_type' => 'book', 'posts_per_page' => absint( $atts['count'] ) ] );
    if ( ! $q->have_posts() ) {
        return '<p>No books found.</p>';
    }
    $out = '<ul>';
    while ( $q->have_posts() ) {
        $q->the_post();
        $out .= '<li><a href="' . esc_url( get_permalink() ) . '">' . esc_html( get_the_title() ) . '</a></li>';
    }
    wp_reset_postdata();
    return $out . '</ul>';
} );
```

**REST route:**

```php
add_action( 'rest_api_init', function () {
    register_rest_route( 'myplugin/v1', '/books', [
        'methods'  => 'GET',
        'callback' => function () {
            $posts = get_posts( [ 'post_type' => 'book', 'numberposts' => 10 ] );
            return array_map( function ( $p ) {
                return [ 'title' => get_the_title( $p ), 'link' => get_permalink( $p ) ];
            }, $posts );
        },
        'permission_callback' => '__return_true',
    ] );
} );
```
