---
name: java
description: Java development skill covering JDK/build tools (Maven, Gradle), Spring Boot (autoconfiguration, starters, embedded Tomcat), Jakarta EE basics, JDBC/JPA/Hibernate, records/sealed classes, streams/lambdas, concurrency (virtual threads), JUnit 5, Maven/Gradle lifecycle, JAR packaging, application properties, error handling, logging (SLF4J/Logback), testing (Mockito, Testcontainers), performance (JVM flags, GC), and security (OWASP, input validation). Use when building, extending, or debugging Java (especially Spring Boot) applications.
---

# Java Skill

## Purpose

Provides production-grade Java development capabilities: build tools (Maven/Gradle), Spring Boot, JPA/Hibernate, records/sealed classes and modern language features, streams/lambdas, concurrency including virtual threads, JUnit 5 testing with Mockito and Testcontainers, JVM performance tuning, and security hardening.

## When to Activate

- Scaffolding or building a Spring Boot application
- Authoring Maven or Gradle builds and managing dependencies
- Writing JPA/Hibernate entities and repositories
- Using Java 17+ features: records, sealed classes, streams, pattern matching
- Handling concurrency, including virtual threads (Project Loom)
- Writing unit/integration tests with JUnit 5, Mockito, Testcontainers
- Configuring application properties and profiles
- Implementing error handling and structured logging
- Tuning the JVM (flags, GC) and analyzing performance
- Hardening security (OWASP, input validation)

## Core Knowledge

### Build Tools

- **Maven**: `pom.xml`, lifecycle (`validate, compile, test, package, install`), `mvn spring-boot:run`, `mvn package`.
- **Gradle**: `build.gradle`/`build.gradle.kts`, `gradle bootRun`, `gradle build`.

### Spring Boot

- **Starters** bundle dependencies: `spring-boot-starter-web`, `-data-jpa`, `-security`, `-test`.
- **Autoconfiguration** wires beans from classpath; override via configuration classes and `application.properties`.
- **Embedded Tomcat** runs the app standalone (`mvn spring-boot:run` or `java -jar app.jar`).

### Language Modernity (17+)

```java
public record User(Long id, String name) {}

public sealed interface Shape permits Circle, Square {}

public static String classify(Object o) {
    return switch (o) {
        case String s -> "string: " + s;
        case Integer i -> "int: " + i;
        default -> "other";
    };
}
```

## Workflow

1. **Scaffold** — use Spring Initializr (start.spring.io) or `spring init`; select starters and build tool.
2. **Define build** — configure `pom.xml`/`build.gradle` with dependencies and compiler release target.
3. **Model data** — create JPA entities and Spring Data repositories.
4. **Add logic** — services with DI (`@Service`, constructor injection), controllers (`@RestController`).
5. **Configure** — `application.properties`/`application.yml` with profiles (dev/prod).
6. **Secure** — Spring Security, input validation (`@Valid`, Bean Validation), OAuth/JWT as needed.
7. **Test** — JUnit 5 unit tests with Mockito; integration with Testcontainers; `mvn test`.
8. **Package/run** — `mvn package` → `java -jar target/app.jar`; tune JVM flags for production.

## Tools

- **Maven / Gradle** — build and dependency management.
- **Spring Boot CLI / Initializr** — scaffolding.
- **JUnit 5, Mockito, Testcontainers** — testing.
- **SLF4J + Logback** — structured logging.
- **JFR / JMC, jcmd, jstack** — JVM profiling and diagnostics.
- **Hibernate** — JPA ORM.

## MCP Requirements

No official Java MCP server is required. **f4** (github.com/f4-dev/f4) is an optional community MCP server for Java projects — mention it but do not configure by default until verified.

## Best Practices

- Favor records for immutable data carriers and immutable value objects.
- Use constructor injection over field injection in Spring beans.
- Program to interfaces; depend on abstractions.
- Use streams sparingly — avoid complex pipelines that hurt readability.
- Prefer virtual threads for lightweight concurrency where appropriate.
- Use `logger.info/debug/error` via SLF4J; never `System.out`.
- Enable structured logging and request IDs in production.
- Use Bean Validation annotations on request DTOs.
- Pin dependency versions in build files; run the security/dependency audit plugin.
- Set JVM flags for production (`-Xms/-Xmx`, choose GC like G1/ZGC appropriately).

## Anti-patterns

- Using field injection without justification (breaks testability).
- Swallowing exceptions with empty catches — always log and propagate/handle.
- Logging sensitive data (passwords, tokens, PII).
- Exposing internal exceptions/stack traces in HTTP responses.
- Ignoring N+1 queries in JPA — tune fetch strategies and use `@EntityGraph`.
- Hardcoding config values instead of `application.properties`/env.
- Running without `@Transactional` where transactions are required.
- Disabling input validation or relying on client-side validation alone.
- Building fat JARs with unnecessary transitive dependencies (bloat/security).

## Verification

- `mvn clean verify` (or `gradle build`) passes — compile + tests.
- `mvn dependency:check` / Gradle `dependencyUpdates` show no known-vulnerable deps.
- App starts and responds (`curl localhost:8080/actuator/health` → UP).
- Logs show no uncaught exceptions or leaked stack traces.
- JUnit reports all tests green; integration tests with Testcontainers pass.
- Check with `jcmd`/JFR that memory/GC behave within expectations under load.
- Confirm profiles load correct config per environment.

## Examples

**Spring Boot REST controller with validation:**

```java
@RestController
@RequestMapping("/books")
public class BookController {

    private final BookService service;

    public BookController(BookService service) { this.service = service; }

    @GetMapping("/{id}")
    public BookDto get(@PathVariable Long id) {
        return service.getBook(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public BookDto create(@Valid @RequestBody CreateBookRequest request) {
        return service.create(request);
    }
}
```

**JPA entity + repository:**

```java
@Entity
public class Book {
    @Id @GeneratedValue
    private Long id;
    private String title;
    // getters/setters
}

public interface BookRepository extends JpaRepository<Book, Long> {}
```

**Record + service:**

```java
public record BookDto(Long id, String title) {}

@Service
public class BookService {
    private final BookRepository repo;
    public BookService(BookRepository repo) { this.repo = repo; }

    @Transactional(readOnly = true)
    public BookDto getBook(Long id) {
        return repo.findById(id)
            .map(b -> new BookDto(b.getId(), b.getTitle()))
            .orElseThrow(() -> new NotFoundException("Book " + id));
    }
}
```
