---
name: frontend
description: Use when building, modifying, or reviewing frontend applications — React components, Next.js pages, TypeScript UI code, design systems, responsive layouts, accessibility, performance optimization, UI animations (Framer Motion, GSAP, Three.js), or AI chat/streaming interfaces. Covers component architecture, state management, testing, and modern frontend tooling.
---

# Frontend Skill

Comprehensive frontend development covering React/Next.js, TypeScript, component architecture, design systems, responsive UI, accessibility, performance, animation, 3D graphics, AI chat UI, and testing.

## Purpose

Provides production-grade frontend patterns and workflows for modern web applications. Covers the full stack from component design through deployment, with emphasis on React 18+, Next.js 14+ App Router, TypeScript, Tailwind CSS, shadcn/ui, and AI-powered streaming interfaces.

## When to Activate

- Building or modifying React components (hooks, server components, client components)
- Creating Next.js pages, layouts, or API routes (App Router)
- Setting up TypeScript for frontend projects
- Designing component systems with shadcn/ui, Radix, or Headless UI
- Implementing responsive layouts with Tailwind CSS
- Adding accessibility (ARIA, keyboard navigation, focus management)
- Optimizing frontend performance (Core Web Vitals, code splitting, lazy loading)
- Adding animations with Framer Motion or GSAP
- Building 3D scenes with Three.js or React Three Fiber
- Creating AI chat UIs with streaming tokens, tool calls, citations
- Setting up frontend testing (Vitest, Playwright, Testing Library)

## Core Knowledge

### React & Next.js App Router

```tsx
// app/layout.tsx — Root layout (Server Component by default)
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-background font-sans antialiased">
        {children}
      </body>
    </html>
  );
}

// app/page.tsx — Server Component (default, no "use client")
import { Suspense } from 'react';
import { Dashboard } from '@/components/dashboard';

export default function HomePage() {
  return (
    <main>
      <Suspense fallback={<DashboardSkeleton />}>
        <Dashboard />
      </Suspense>
    </main>
  );
}

// components/counter.tsx — Client Component
'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/button';

export function Counter({ initial }: { initial: number }) {
  const [count, setCount] = useState(initial);
  return (
    <Button onClick={() => setCount(c => c + 1)}>
      Count: {count}
    </Button>
  );
}
```

### Component Architecture

```tsx
// components/ui/button.tsx — shadcn/ui pattern
import { Slot } from '@radix-ui/react-slot';
import { cva, type VariantProps } from 'class-variance-authority';
import { cn } from '@/lib/utils';

const buttonVariants = cva(
  'inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 disabled:pointer-events-none disabled:opacity-50',
  {
    variants: {
      variant: {
        default: 'bg-primary text-primary-foreground hover:bg-primary/90',
        destructive: 'bg-destructive text-destructive-foreground hover:bg-destructive/90',
        outline: 'border border-input bg-background hover:bg-accent hover:text-accent-foreground',
      },
      size: {
        default: 'h-10 px-4 py-2',
        sm: 'h-9 rounded-md px-3',
        lg: 'h-11 rounded-md px-8',
      },
    },
    defaultVariants: { variant: 'default', size: 'default' },
  }
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean;
}

export function Button({ className, variant, size, asChild = false, ...props }: ButtonProps) {
  const Comp = asChild ? Slot : 'button';
  return <Comp className={cn(buttonVariants({ variant, size, className }))} {...props} />;
}
```

### TypeScript Patterns

```tsx
// lib/types.ts — Shared types
export type ApiResponse<T> = {
  data: T;
  error: null;
} | {
  data: null;
  error: { code: string; message: string };
};

// lib/utils.ts — Utility with type safety
import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// hooks/use-debounce.ts — Generic custom hook
export function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState(value);
  useEffect(() => {
    const timer = setTimeout(() => setDebouncedValue(value), delay);
    return () => clearTimeout(timer);
  }, [value, delay]);
  return debouncedValue;
}
```

### Accessibility

```tsx
// Accessible dialog pattern
'use client';

import * as Dialog from '@radix-ui/react-dialog';

export function AccessibleDialog({ children, trigger }: {
  children: React.ReactNode;
  trigger: React.ReactNode;
}) {
  return (
    <Dialog.Root>
      <Dialog.Trigger asChild>{trigger}</Dialog.Trigger>
      <Dialog.Portal>
        <Dialog.Overlay className="fixed inset-0 bg-black/50 data-[state=open]:animate-in" />
        <Dialog.Content
          className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 p-6"
          role="dialog"
          aria-modal="true"
          aria-labelledby="dialog-title"
        >
          <Dialog.Title id="dialog-title" className="text-lg font-semibold">
            {children}
          </Dialog.Title>
          <Dialog.Close asChild>
            <button aria-label="Close" className="absolute right-4 top-4">×</button>
          </Dialog.Close>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}

// Skip link pattern
function SkipLink() {
  return (
    <a
      href="#main-content"
      className="sr-only focus:not-sr-only focus:absolute focus:z-50 focus:p-4 focus:bg-background"
    >
      Skip to main content
    </a>
  );
}
```

### Performance

```tsx
// next.config.ts — Performance configuration
const config = {
  images: {
    formats: ['image/avif', 'image/webp'],
    deviceSizes: [640, 768, 1024, 1280, 1536],
  },
  experimental: { optimizePackageImports: ['@radix-ui/react-icons', 'lucide-react'] },
};

// Lazy loading components
import dynamic from 'next/dynamic';
const HeavyChart = dynamic(() => import('@/components/heavy-chart'), {
  loading: () => <ChartSkeleton />,
  ssr: false,
});

// Memoized expensive computations
const sortedItems = useMemo(() => items.sort(compareFn), [items, sortKey]);
```

### Animation — Framer Motion

```tsx
'use client';
import { motion, AnimatePresence } from 'framer-motion';

export function FadeInList({ items }: { items: string[] }) {
  return (
    <AnimatePresence>
      {items.map((item, i) => (
        <motion.div
          key={item}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, x: -100 }}
          transition={{ delay: i * 0.05, duration: 0.3 }}
          layout
        >
          {item}
        </motion.div>
      ))}
    </AnimatePresence>
  );
}

// Page transition wrapper
export function PageTransition({ children }: { children: React.ReactNode }) {
  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.98 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 0.98 }}
      transition={{ duration: 0.2 }}
    >
      {children}
    </motion.div>
  );
}
```

### Animation — GSAP

```tsx
// gsap-scroll-animation.ts
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';

gsap.registerPlugin(ScrollTrigger);

export function initScrollAnimations(container: HTMLElement) {
  gsap.utils.toArray<HTMLElement>('.fade-up', container).forEach((el) => {
    gsap.from(el, {
      y: 40,
      opacity: 0,
      duration: 0.8,
      ease: 'power3.out',
      scrollTrigger: { trigger: el, start: 'top 85%', toggleActions: 'play none none none' },
    });
  });
}
```

### 3D — React Three Fiber

```tsx
'use client';
import { Canvas, useFrame } from '@react-three/fiber';
import { OrbitControls, Float } from '@react-three/drei';
import { useRef } from 'react';

function RotatingBox() {
  const ref = useRef<THREE.Mesh>(null!);
  useFrame((_, delta) => { ref.current.rotation.y += delta; });
  return (
    <Float speed={2} rotationIntensity={0.5}>
      <mesh ref={ref}>
        <boxGeometry args={[1, 1, 1]} />
        <meshStandardMaterial color="#6366f1" />
      </mesh>
    </Float>
  );
}

export function Scene() {
  return (
    <Canvas camera={{ position: [0, 0, 5] }}>
      <ambientLight intensity={0.5} />
      <pointLight position={[10, 10, 10]} />
      <RotatingBox />
      <OrbitControls />
    </Canvas>
  );
}
```

### AI Chat UI — Streaming with Vercel AI SDK

```tsx
'use client';
import { useChat } from 'ai/react';

export function ChatInterface() {
  const { messages, input, handleInputChange, handleSubmit, isLoading } = useChat({
    api: '/api/chat',
    onResponse: (response) => { /* stream callback */ },
  });

  return (
    <div className="flex flex-col h-screen">
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((msg) => (
          <div key={msg.id} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
            <div className={`max-w-[70%] rounded-lg px-4 py-2 ${
              msg.role === 'user' ? 'bg-primary text-primary-foreground' : 'bg-muted'
            }`}>
              {/* Render tool invocations */}
              {msg.toolInvocations?.map((tool) => (
                <div key={tool.toolCallId} className="mt-2 p-2 bg-background/50 rounded text-xs">
                  <span className="font-mono">{tool.toolName}</span>
                  <pre className="overflow-auto">{JSON.stringify(tool.args)}</pre>
                </div>
              ))}
              {/* Render text parts */}
              {msg.content && <p className="whitespace-pre-wrap">{msg.content}</p>}
              {/* Render citations */}
              {msg.annotations?.map((ann, i) => (
                <span key={i} className="text-xs text-muted-foreground ml-2">[{ann}]</span>
              ))}
            </div>
          </div>
        ))}
      </div>

      <form onSubmit={handleSubmit} className="border-t p-4 flex gap-2">
        <input
          value={input}
          onChange={handleInputChange}
          placeholder="Type a message..."
          disabled={isLoading}
          className="flex-1 rounded-md border bg-background px-3 py-2 text-sm"
        />
        <button type="submit" disabled={isLoading || !input.trim()}>
          {isLoading ? 'Thinking...' : 'Send'}
        </button>
      </form>
    </div>
  );
}

// app/api/chat/route.ts — Server-side streaming endpoint
import { openai } from '@ai-sdk/openai';
import { streamText } from 'ai';

export async function POST(req: Request) {
  const { messages } = await req.json();
  const result = streamText({
    model: openai('gpt-4o'),
    messages,
    system: 'You are a helpful assistant.',
    tools: {
      getWeather: {
        description: 'Get current weather',
        parameters: { type: 'object', properties: { city: { type: 'string' } } },
        execute: async ({ city }) => ({ temp: 22, condition: 'sunny', city }),
      },
    },
    maxSteps: 3,
  });
  return result.toDataStreamResponse();
}
```

## Workflow

### 1. Scaffold a Next.js Project
```bash
npx create-next-app@latest my-app --typescript --tailwind --eslint --app --src-dir
cd my-app && npm install
```

### 2. Add shadcn/ui Components
```bash
npx shadcn@latest init    # Set up components.json, cn(), CSS variables
npx shadcn@latest add button card dialog input label
```

### 3. Project Structure
```
src/
├── app/
│   ├── layout.tsx          # Root layout
│   ├── page.tsx            # Home page (Server Component)
│   └── api/chat/route.ts   # API route
├── components/
│   ├── ui/                 # shadcn/ui primitives
│   └── [feature]/          # Feature-specific components
├── hooks/                  # Custom React hooks
├── lib/
│   ├── utils.ts            # cn() and helpers
│   └── types.ts            # Shared TypeScript types
└── styles/
    └── globals.css         # Tailwind directives
```

### 4. Add Animations
```bash
npm install framer-motion gsap @react-three/fiber @react-three/drei three
npm install -D @types/three
```

### 5. Add Chat/Streaming
```bash
npm install ai @ai-sdk/openai    # Vercel AI SDK
# Add streaming provider in layout: import { ChatProvider } from '@/components/chat-provider'
```

## Tools

### Package Installation
```bash
# Core
npm install react react-dom next typescript

# UI
npm install tailwindcss @tailwindcss/postcss postcss
npx shadcn@latest init

# Animation
npm install framer-motion gsap

# 3D
npm install three @react-three/fiber @react-three/drei
npm install -D @types/three

# AI Chat
npm install ai @ai-sdk/openai @ai-sdk/anthropic

# Testing
npm install -D vitest @testing-library/react @testing-library/jest-dom jsdom
npm install -D @playwright/test

# Type checking
npm install -D @types/react @types/react-dom
```

### Command-Line Utilities
```bash
# Dev server
npm run dev          # http://localhost:3000

# Build
npm run build

# Type check
npx tsc --noEmit

# Lint
npm run lint

# Unit tests
npx vitest run

# E2E tests
npx playwright test
npx playwright show-report

# Add shadcn/ui component
npx shadcn@latest add [component-name]
```

## MCP Requirements

- **GitHub**: For repository management and PR creation
- **Context7**: For fetching up-to-date docs on React, Next.js, Tailwind, shadcn
- **webfetch**: For pulling reference patterns from documentation sites

## Best Practices

1. **Server Components by default**: Only add `'use client'` when the component needs hooks, event handlers, or browser APIs. RSC reduces bundle size.
2. **Co-locate components**: Put feature components near their route (`app/dashboard/components/`). Put shared primitives in `components/ui/`.
3. **Type everything**: Use `React.FC` sparingly; prefer explicit prop types. Use `type` over `interface` unless extending.
4. **Accessibility first**: Use Radix/Headless UI for unstyled accessible primitives. Test with `axe-core`. Add `aria-*` attributes for custom components.
5. **Tailwind over inline styles**: Use `cn()` for conditional classes. Keep variant logic in `cva` for complex components.
6. **Progressive enhancement**: Forms should work without JS. Use `action` prop on forms in Server Components.
7. **Performance**: Use `next/image` for all images. Use `next/font` for fonts. Avoid client-side data fetching in layout; use Server Components.
8. **Animation**: Use Framer Motion for React component animations. Use GSAP for scroll-based and timeline animations. Use React Three Fiber for 3D.

## Anti-patterns

- ❌ Adding `'use client'` at the top of files that don't need it (defeats RSC)
- ❌ Creating deep prop drilling instead of using Context or composition
- ❌ Using `any` type — use `unknown` and narrow, or define proper types
- ❌ Inline styles for complex layouts — use Tailwind classes
- ❌ Missing `key` prop in lists (causes re-render bugs)
- ❌ Fetching data in `useEffect` when Server Components can do it
- ❌ Using CSS `!important` — adjust specificity via Tailwind config instead
- ❌ Accessibility as an afterthought — add ARIA and keyboard nav from the start
- ❌ Over-optimizing with memo/wrap — React is fast; measure before optimizing
- ❌ Storing chat messages in component state — use `useChat` from Vercel AI SDK

## Verification

### Type Checking
```bash
npx tsc --noEmit
```

### Linting
```bash
npm run lint
```

### Unit Tests (Vitest)
```bash
# vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
export default defineConfig({
  plugins: [react()],
  test: { environment: 'jsdom', globals: true, setupFiles: './vitest.setup.ts' },
});

# Run tests
npx vitest run

# Watch mode
npx vitest
```

### E2E Tests (Playwright)
```bash
# playwright.config.ts
import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: './e2e',
  webServer: { command: 'npm run dev', port: 3000, reuseExistingServer: true },
});

# Run
npx playwright test
```

### Sample Unit Test
```tsx
// __tests__/button.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { Button } from '@/components/ui/button';

describe('Button', () => {
  it('renders with text', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByRole('button', { name: 'Click me' })).toBeInTheDocument();
  });

  it('calls onClick', () => {
    const onClick = vi.fn();
    render(<Button onClick={onClick}>Click</Button>);
    fireEvent.click(screen.getByRole('button'));
    expect(onClick).toHaveBeenCalledOnce();
  });

  it('is disabled when disabled prop is set', () => {
    render(<Button disabled>Disabled</Button>);
    expect(screen.getByRole('button')).toBeDisabled();
  });
});
```

## Examples

### Full-Stack Chat Page with Streaming

```tsx
// app/chat/page.tsx
import { ChatInterface } from '@/components/chat-interface';

export default function ChatPage() {
  return (
    <main className="h-screen flex flex-col">
      <header className="border-b p-4">
        <h1 className="text-xl font-bold">AI Assistant</h1>
      </header>
      <ChatInterface />
    </main>
  );
}

// components/chat-interface.tsx (complete)
'use client';
import { useChat } from 'ai/react';
import { useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Bot, User, Loader2 } from 'lucide-react';

export function ChatInterface() {
  const { messages, input, handleInputChange, handleSubmit, isLoading } = useChat({
    maxSteps: 5,
  });
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight, behavior: 'smooth' });
  }, [messages]);

  return (
    <div className="flex-1 flex flex-col min-h-0">
      {/* Messages */}
      <div ref={scrollRef} className="flex-1 overflow-y-auto p-4 space-y-4">
        <AnimatePresence initial={false}>
          {messages.map((msg) => (
            <motion.div
              key={msg.id}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className={`flex gap-3 ${msg.role === 'user' ? 'justify-end' : ''}`}
            >
              {msg.role === 'assistant' && (
                <div className="flex-shrink-0 w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center">
                  <Bot className="w-4 h-4" />
                </div>
              )}
              <div className={`max-w-[75%] rounded-xl px-4 py-2 ${
                msg.role === 'user' ? 'bg-primary text-primary-foreground' : 'bg-muted'
              }`}>
                {/* Tool calls */}
                {msg.toolInvocations?.map((tool) => (
                  <div key={tool.toolCallId} className="mb-2 p-2 rounded bg-background/50 border text-xs">
                    <span className="font-medium">Tool: {tool.toolName}</span>
                    {'result' in tool && (
                      <pre className="mt-1 overflow-auto">{JSON.stringify(tool.result, null, 2)}</pre>
                    )}
                  </div>
                ))}
                {msg.content && (
                  <p className="whitespace-pre-wrap text-sm">{msg.content}</p>
                )}
              </div>
              {msg.role === 'user' && (
                <div className="flex-shrink-0 w-8 h-8 rounded-full bg-primary flex items-center justify-center">
                  <User className="w-4 h-4 text-primary-foreground" />
                </div>
              )}
            </motion.div>
          ))}
        </AnimatePresence>
        {isLoading && (
          <div className="flex items-center gap-2 text-muted-foreground text-sm">
            <Loader2 className="w-4 h-4 animate-spin" />
            Thinking...
          </div>
        )}
      </div>

      {/* Input */}
      <form onSubmit={handleSubmit} className="border-t p-4 flex gap-2">
        <input
          value={input}
          onChange={handleInputChange}
          placeholder="Ask me anything..."
          disabled={isLoading}
          className="flex-1 rounded-xl border bg-background px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-primary disabled:opacity-50"
        />
        <button
          type="submit"
          disabled={isLoading || !input.trim()}
          className="rounded-xl bg-primary px-6 py-3 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50 transition-colors"
        >
          Send
        </button>
      </form>
    </div>
  );
}
```
