# TanStack Start Auth Template

A modern, full-stack web application template built with TanStack Start, featuring authentication, dashboard, and beautiful UI components.

## Features

- 🚀 **TanStack Start** - Type-safe, full-stack React framework
- 🔐 **Authentication** - JWT-based auth with secure session management
- 📊 **Dashboard** - Beautiful, responsive dashboard UI
- 🎨 **Tailwind CSS** - Modern styling with custom components
- 🗄️ **Database** - SQLite with Drizzle ORM
- 🔧 **TypeScript** - Full type safety throughout
- ⚡ **Vite** - Fast development and build tooling
- 🧪 **Testing** - Jest setup for unit testing

### TanStack First-Party Packages

- 📋 **TanStack Table** - Headless table with sorting, filtering, and pagination
- 📝 **TanStack Form** - Type-safe forms with validation and error handling
- 🚀 **TanStack Virtual** - Virtualized lists for high-performance rendering
- 🔄 **TanStack Query** - Server state management with caching and synchronization
- 🧭 **TanStack Router** - Type-safe routing with search params and loaders

## Quick Start

### Using Nix (Recommended)

```bash
# Enter the development shell
nix develop

# Install dependencies
npm install

# Start development server
npm run dev
```

### Using Node.js

```bash
# Install dependencies
npm install

# Start development server
npm run dev
```

The application will be available at `http://localhost:3000`.

## Building and Running

### Build the Application

```bash
# Build the Nix package
nix build

# Run the built application
./result/bin/tanstack-auth-app

# Or run directly
nix run
```

### Database Management

```bash
# Run database migrations
./result/bin/tanstack-auth-db migrate

# Start Drizzle Studio (database UI)
./result/bin/tanstack-auth-db studio

# Or use nix run
nix run .#tanstack-auth-db migrate
nix run .#tanstack-auth-db studio
```

## Project Structure

```
├── app/
│   ├── components/         # React components
│   ├── lib/               # Utilities and database
│   │   ├── auth.ts        # Authentication logic
│   │   ├── db.ts          # Database connection
│   │   └── schema.ts      # Database schema
│   ├── routes/            # File-based routing
│   │   ├── __root.tsx     # Root layout
│   │   ├── index.tsx      # Home page
│   │   ├── login.tsx      # Login page
│   │   ├── register.tsx   # Registration page
│   │   ├── logout.tsx     # Logout handler
│   │   ├── _authenticated.tsx  # Auth layout
│   │   └── _authenticated/
│   │       └── dashboard.tsx   # Dashboard page
│   └── styles/
│       └── app.css        # Global styles
├── drizzle/               # Database migrations
├── flake.nix             # Nix development environment
├── package.json          # Dependencies and scripts
├── vite.config.ts        # Vite configuration
└── tailwind.config.js    # Tailwind configuration
```

## Authentication

The application uses JWT-based authentication with:

- **Secure password hashing** using bcryptjs
- **Session management** with HTTP-only cookies
- **Protected routes** using TanStack Router's `beforeLoad`
- **User registration and login** with validation

### Auth Flow

1. Users can register with email/password
2. Login creates a JWT token stored in HTTP-only cookie
3. Protected routes check authentication in `beforeLoad`
4. Logout clears the session and redirects

## Database

Uses SQLite with Drizzle ORM for type-safe database operations:

- **Users table** - Store user accounts
- **Sessions table** - Manage user sessions
- **Migrations** - Version-controlled schema changes

### Database Commands

```bash
# Generate migration files
npm run db:generate

# Apply migrations
npm run db:migrate

# Open Drizzle Studio
npm run db:studio
```

## Development

### Available Scripts

```bash
npm run dev          # Start development server
npm run build        # Build for production
npm run start        # Start production server
npm run lint         # Run ESLint
npm run lint:fix     # Fix linting issues
npm run format       # Format code with Prettier
npm run type-check   # Check TypeScript types
npm run test         # Run tests
```

### Environment Variables

Create a `.env` file in the root directory:

```env
NODE_ENV=development
PORT=3000
DATABASE_URL=file:./dev.db
SESSION_SECRET=your-super-secret-session-key-change-this-in-production
CORS_ORIGIN=http://localhost:3000
```

## Building for Production

```bash
# Build the application
npm run build

# Start production server
npm run start
```

The built application will be in the `.output` directory.

## Deployment

The application can be deployed to various platforms:

### Vercel

```bash
# Configure for Vercel in vite.config.ts
plugins: [tanstackStart({ target: 'vercel' })]

# Deploy with Vercel CLI
vercel deploy
```

### Netlify

```bash
# Configure for Netlify in vite.config.ts
plugins: [tanstackStart({ target: 'netlify' })]

# Deploy with Netlify CLI
netlify deploy
```

### Node.js Server

```bash
npm run build
node .output/server/index.mjs
```

## Customization

### Styling

The application uses Tailwind CSS with custom component classes defined in `app/styles/app.css`. Key classes include:

- `.btn`, `.btn-primary`, `.btn-secondary` - Button styles
- `.card` - Card container
- `.input` - Form input styles
- `.nav-link` - Navigation link styles

### Adding New Routes

Create new route files in the `app/routes/` directory. TanStack Start uses file-based routing:

- `app/routes/about.tsx` → `/about`
- `app/routes/blog/index.tsx` → `/blog`
- `app/routes/blog/$slug.tsx` → `/blog/[slug]`

### Database Schema

Modify `app/lib/schema.ts` to add new tables or columns, then generate and apply migrations:

```bash
npm run db:generate
npm run db:migrate
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see the [LICENSE](LICENSE) file for details.