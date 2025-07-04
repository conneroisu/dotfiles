import { createFileRoute, Link } from '@tanstack/react-router'

export const Route = createFileRoute('/')({
  component: HomePage,
})

function HomePage() {
  const { user } = Route.useRouteContext()

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <div className="text-center">
        <h1 className="text-4xl font-bold text-gray-900 sm:text-5xl md:text-6xl">
          Welcome to{' '}
          <span className="text-primary-600">TanStack Auth</span>
        </h1>
        <p className="mt-3 max-w-md mx-auto text-base text-gray-500 sm:text-lg md:mt-5 md:text-xl md:max-w-3xl">
          A modern full-stack application built with TanStack Start, featuring authentication, 
          dashboard, and beautiful UI components.
        </p>

        <div className="mt-5 max-w-md mx-auto sm:flex sm:justify-center md:mt-8">
          {user ? (
            <div className="space-y-4 sm:space-y-0 sm:space-x-4 sm:flex">
              <Link
                to="/dashboard"
                className="btn btn-primary w-full sm:w-auto"
              >
                Go to Dashboard
              </Link>
            </div>
          ) : (
            <div className="space-y-4 sm:space-y-0 sm:space-x-4 sm:flex">
              <Link
                to="/register"
                className="btn btn-primary w-full sm:w-auto"
              >
                Get Started
              </Link>
              <Link
                to="/login"
                className="btn btn-outline w-full sm:w-auto"
              >
                Sign In
              </Link>
            </div>
          )}
        </div>
      </div>

      <div className="mt-16">
        <div className="grid grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-3">
          <div className="card p-6">
            <div className="w-8 h-8 bg-primary-100 rounded-lg flex items-center justify-center mb-4">
              <svg className="w-5 h-5 text-primary-600" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M3 4a1 1 0 011-1h12a1 1 0 011 1v2a1 1 0 01-1 1H4a1 1 0 01-1-1V4zm0 4a1 1 0 011-1h12a1 1 0 011 1v2a1 1 0 01-1 1H4a1 1 0 01-1-1V8zm0 4a1 1 0 011-1h12a1 1 0 011 1v2a1 1 0 01-1 1H4a1 1 0 01-1-1v-2z" clipRule="evenodd" />
              </svg>
            </div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">
              TanStack Start
            </h3>
            <p className="text-gray-600">
              Built with the latest TanStack Start framework for type-safe, full-stack development.
            </p>
          </div>

          <div className="card p-6">
            <div className="w-8 h-8 bg-primary-100 rounded-lg flex items-center justify-center mb-4">
              <svg className="w-5 h-5 text-primary-600" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M18 8a6 6 0 01-7.743 5.743L10 14l-1 1-1 1H6v2H2v-4l4.257-4.257A6 6 0 1118 8zm-6-4a1 1 0 100 2 2 2 0 012 2 1 1 0 102 0 4 4 0 00-4-4z" clipRule="evenodd" />
              </svg>
            </div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">
              Secure Authentication
            </h3>
            <p className="text-gray-600">
              JWT-based authentication with secure session management and password hashing.
            </p>
          </div>

          <div className="card p-6">
            <div className="w-8 h-8 bg-primary-100 rounded-lg flex items-center justify-center mb-4">
              <svg className="w-5 h-5 text-primary-600" fill="currentColor" viewBox="0 0 20 20">
                <path d="M3 4a1 1 0 011-1h12a1 1 0 011 1v2a1 1 0 01-1 1H4a1 1 0 01-1-1V4zM3 10a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H4a1 1 0 01-1-1v-6zM14 9a1 1 0 00-1 1v6a1 1 0 001 1h2a1 1 0 001-1v-6a1 1 0 00-1-1h-2z" />
              </svg>
            </div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">
              Dashboard UI
            </h3>
            <p className="text-gray-600">
              Beautiful dashboard with responsive design and modern UI components.
            </p>
          </div>

          <div className="card p-6">
            <div className="w-8 h-8 bg-primary-100 rounded-lg flex items-center justify-center mb-4">
              <svg className="w-5 h-5 text-primary-600" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M12.316 3.051a1 1 0 01.633 1.265l-4 12a1 1 0 11-1.898-.632l4-12a1 1 0 011.265-.633zM5.707 6.293a1 1 0 010 1.414L3.414 10l2.293 2.293a1 1 0 11-1.414 1.414l-3-3a1 1 0 010-1.414l3-3a1 1 0 011.414 0zm8.586 0a1 1 0 011.414 0l3 3a1 1 0 010 1.414l-3 3a1 1 0 11-1.414-1.414L16.586 10l-2.293-2.293a1 1 0 010-1.414z" clipRule="evenodd" />
              </svg>
            </div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">
              TypeScript
            </h3>
            <p className="text-gray-600">
              Fully typed with TypeScript for better developer experience and fewer bugs.
            </p>
          </div>

          <div className="card p-6">
            <div className="w-8 h-8 bg-primary-100 rounded-lg flex items-center justify-center mb-4">
              <svg className="w-5 h-5 text-primary-600" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M3 3a1 1 0 000 2v8a2 2 0 002 2h2.586l-1.293 1.293a1 1 0 101.414 1.414L10 15.414l2.293 2.293a1 1 0 001.414-1.414L12.414 15H15a2 2 0 002-2V5a1 1 0 100-2H3zm11.707 4.707a1 1 0 00-1.414-1.414L10 9.586 8.707 8.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
              </svg>
            </div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">
              Database Ready
            </h3>
            <p className="text-gray-600">
              Configured with Drizzle ORM and SQLite for easy database management.
            </p>
          </div>

          <div className="card p-6">
            <div className="w-8 h-8 bg-primary-100 rounded-lg flex items-center justify-center mb-4">
              <svg className="w-5 h-5 text-primary-600" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M11.3 1.046A1 1 0 0112 2v5h4a1 1 0 01.82 1.573l-7 10A1 1 0 018 18v-5H4a1 1 0 01-.82-1.573l7-10a1 1 0 011.12-.38z" clipRule="evenodd" />
              </svg>
            </div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">
              Fast Development
            </h3>
            <p className="text-gray-600">
              Hot module replacement and fast builds with Vite for rapid development.
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}