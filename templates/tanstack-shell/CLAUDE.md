# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this TanStack Start application.

## Project Overview

This is a modern full-stack web application built with **TanStack Start**, featuring a complete authentication system, dashboard, and integration of all TanStack first-party packages. The application demonstrates best practices for type-safe, full-stack React development.

## Technology Stack

### Core Framework
- **TanStack Start** - Full-stack React framework with SSR and server functions
- **TanStack Router** - Type-safe file-based routing with protected routes
- **React 18** - UI library with modern hooks and patterns
- **TypeScript** - Full type safety throughout the application
- **Vite** - Fast development and build tooling

### TanStack Ecosystem
- **TanStack Query** - Server state management with caching and synchronization
- **TanStack Table** - Headless table components with sorting and filtering
- **TanStack Form** - Type-safe form handling with validation
- **TanStack Virtual** - High-performance virtualized lists
- **TanStack Zod Adapter** - Zod integration for validation

### Styling & UI
- **Tailwind CSS v4** - Utility-first CSS framework
- **Custom Components** - Reusable UI components with consistent styling
- **Responsive Design** - Mobile-first responsive layouts

### Database & Auth
- **SQLite** - Lightweight database with better-sqlite3
- **Drizzle ORM** - Type-safe database operations with migrations
- **JWT Authentication** - Secure session management with HTTP-only cookies
- **bcryptjs** - Password hashing and verification

### Development Tools
- **ESLint** - Code linting with TypeScript rules
- **Prettier** - Code formatting
- **Jest** - Unit testing framework
- **Drizzle Kit** - Database migration and studio tools

## Project Structure

```
app/
├── components/          # Reusable React components
│   ├── LoginForm.tsx    # TanStack Form login implementation
│   ├── RegisterForm.tsx # TanStack Form registration
│   ├── UserTable.tsx    # TanStack Table implementation
│   └── VirtualizedList.tsx # TanStack Virtual implementation
├── lib/                 # Core utilities and configurations
│   ├── auth.ts          # Authentication server functions
│   ├── db.ts            # Database connection and migrations
│   └── schema.ts        # Drizzle ORM schema definitions
├── routes/              # File-based routing (TanStack Router)
│   ├── __root.tsx       # Root layout with navigation
│   ├── index.tsx        # Public home page
│   ├── login.tsx        # Login page
│   ├── register.tsx     # Registration page
│   ├── logout.tsx       # Logout handler
│   ├── _authenticated.tsx # Protected route layout
│   └── _authenticated/  # Protected routes
│       ├── dashboard.tsx # Main dashboard
│       ├── users.tsx    # User management page
│       └── examples.tsx # TanStack examples showcase
└── styles/
    └── app.css          # Global styles with Tailwind
```

## Common Commands

All commands should be run in the Nix development environment:

### Development
```bash
nix develop              # Enter development shell
npm run dev              # Start development server (localhost:3000)
npm run build            # Build for production
npm run start            # Start production server
```

### Code Quality
```bash
npm run lint             # Run ESLint
npm run lint:fix         # Fix ESLint issues
npm run format           # Format code with Prettier
npm run type-check       # Check TypeScript types
```

### Database
```bash
npm run db:generate      # Generate migration files
npm run db:migrate       # Apply migrations
npm run db:studio        # Open Drizzle Studio (database UI)
```

### Testing
```bash
npm run test             # Run Jest tests
npm run test:watch       # Run tests in watch mode
```

### Nix Operations
```bash
nix build                # Build the application package
nix run                  # Run the built application
nix run .#tanstack-auth-db migrate  # Run database migrations
nix run .#tanstack-auth-db studio   # Start Drizzle Studio
```

## Key Features

### Authentication System
- **User Registration** - Email/password with validation
- **Login/Logout** - JWT-based session management
- **Protected Routes** - Automatic redirect for unauthenticated users
- **Password Security** - bcrypt hashing with secure defaults
- **Session Management** - HTTP-only cookies with proper expiration

### Dashboard & UI
- **Responsive Dashboard** - Modern card-based layout
- **User Management** - Table with sorting and pagination
- **Navigation** - Consistent header with authentication state
- **Examples Page** - Showcase of all TanStack packages
- **Form Validation** - Real-time validation with error handling

### Database
- **Type-Safe Schema** - Drizzle ORM with TypeScript types
- **Migrations** - Version-controlled database changes
- **Users Table** - Authentication and user data
- **Sessions Table** - Session management and cleanup

## Development Guidelines

### Adding New Routes
1. Create route files in `app/routes/` following the file-based routing convention
2. Use `createFileRoute()` for type-safe route definitions
3. Implement `beforeLoad` for authentication checks if needed
4. Add loaders for data fetching with proper error handling

Example:
```tsx
export const Route = createFileRoute('/new-page')({
  beforeLoad: ({ context }) => {
    // Add auth check if needed
    if (!context.user) {
      throw redirect({ to: '/login' })
    }
  },
  loader: async () => {
    // Fetch data using server functions
    return await fetchPageData()
  },
  component: NewPageComponent,
})
```

### Creating Components
1. Follow the existing component patterns in `app/components/`
2. Use TanStack packages where appropriate (Table, Form, Virtual)
3. Implement proper TypeScript types
4. Use Tailwind utility classes with custom component classes
5. Handle loading states and error conditions

### Database Operations
1. Define schema changes in `app/lib/schema.ts`
2. Generate migrations with `npm run db:generate`
3. Apply migrations with `npm run db:migrate`
4. Use server functions for database operations
5. Implement proper error handling and validation

### Authentication
1. Use server functions in `app/lib/auth.ts` for auth operations
2. Check authentication in route `beforeLoad` functions
3. Use `useRouteContext()` to access user data in components
4. Implement proper error handling for auth failures

## Environment Variables

```env
NODE_ENV=development|production
PORT=3000
DATABASE_URL=file:./data.db
SESSION_SECRET=your-secure-secret-key
CORS_ORIGIN=http://localhost:3000
```

## Debugging

### Common Issues
1. **Build Failures** - Check TypeScript errors with `npm run type-check`
2. **Database Issues** - Verify migrations with `npm run db:studio`
3. **Auth Problems** - Check session cookies and JWT validation
4. **Route Issues** - Verify file-based routing structure

### Development Tools
- **React DevTools** - Browser extension for React debugging
- **TanStack Router Devtools** - Built-in router debugging
- **Drizzle Studio** - Database inspection and management
- **Network Tab** - Monitor server function calls and API requests

## Deployment

### Production Build
```bash
npm run build           # Creates .output/ directory
npm run start           # Starts production server
```

### Nix Deployment
```bash
nix build               # Creates result/ symlink
./result/bin/tanstack-auth-app  # Run production binary
```

### Environment Setup
1. Set production environment variables
2. Configure secure session secret
3. Set up production database
4. Configure CORS origins
5. Set up HTTPS in production

## Best Practices

### Code Organization
- Keep components small and focused
- Use server functions for all database operations
- Implement proper error boundaries
- Follow consistent naming conventions

### Security
- Never expose sensitive data to the client
- Validate all user inputs with Zod schemas
- Use HTTP-only cookies for sessions
- Implement proper CORS configuration
- Hash passwords with bcrypt

### Performance
- Use TanStack Query for efficient data fetching
- Implement TanStack Virtual for large lists
- Optimize bundle size with proper imports
- Use React.memo() for expensive components

### Type Safety
- Define proper TypeScript interfaces
- Use Zod schemas for validation
- Implement proper error types
- Use TanStack Router's type-safe navigation

This application serves as a comprehensive example of modern full-stack React development with the TanStack ecosystem, providing a solid foundation for building production-ready web applications.