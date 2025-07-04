/// <reference types="vite/client" />
import {
  HeadContent,
  Link,
  Outlet,
  Scripts,
  createRootRoute,
} from '@tanstack/react-router'
import { TanStackRouterDevtools } from '@tanstack/react-router-devtools'
import * as React from 'react'
import { getCurrentUser } from '~/lib/auth'
import appCss from '~/styles/app.css?url'

export const Route = createRootRoute({
  beforeLoad: async () => {
    const user = await getCurrentUser()
    return { user }
  },
  head: () => ({
    meta: [
      {
        charSet: 'utf-8',
      },
      {
        name: 'viewport',
        content: 'width=device-width, initial-scale=1',
      },
      {
        title: 'TanStack Auth App',
      },
      {
        name: 'description',
        content: 'A TanStack Start application with authentication and dashboard',
      },
    ],
    links: [
      { rel: 'stylesheet', href: appCss },
      { rel: 'icon', href: '/favicon.ico' },
    ],
  }),
  errorComponent: (props) => {
    return (
      <RootDocument>
        <div className="min-h-screen flex items-center justify-center bg-gray-50">
          <div className="card p-8 max-w-md w-full">
            <h1 className="text-xl font-semibold text-red-600 mb-4">Something went wrong</h1>
            <p className="text-gray-600 mb-4">
              {props.error?.message || 'An unexpected error occurred'}
            </p>
            <button
              onClick={() => window.location.reload()}
              className="btn btn-primary w-full"
            >
              Reload page
            </button>
          </div>
        </div>
      </RootDocument>
    )
  },
  notFoundComponent: () => (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="card p-8 max-w-md w-full text-center">
        <h1 className="text-2xl font-bold text-gray-900 mb-4">404 - Page Not Found</h1>
        <p className="text-gray-600 mb-6">The page you're looking for doesn't exist.</p>
        <Link to="/" className="btn btn-primary">
          Go Home
        </Link>
      </div>
    </div>
  ),
  component: RootComponent,
})

function RootComponent() {
  return (
    <RootDocument>
      <Outlet />
    </RootDocument>
  )
}

function RootDocument({ children }: { children: React.ReactNode }) {
  const { user } = Route.useRouteContext()

  return (
    <html lang="en">
      <head>
        <HeadContent />
      </head>
      <body>
        <div className="min-h-screen bg-gray-50">
          <nav className="bg-white border-b border-gray-200">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
              <div className="flex justify-between items-center h-16">
                <div className="flex items-center space-x-4">
                  <Link 
                    to="/" 
                    className="text-xl font-bold text-primary-600"
                  >
                    TanStack Auth
                  </Link>
                  
                  {user && (
                    <div className="hidden sm:flex items-center space-x-1">
                      <Link
                        to="/dashboard"
                        className="nav-link"
                        activeProps={{ className: 'nav-link active' }}
                      >
                        Dashboard
                      </Link>
                      <Link
                        to="/users"
                        className="nav-link"
                        activeProps={{ className: 'nav-link active' }}
                      >
                        Users
                      </Link>
                      <Link
                        to="/examples"
                        className="nav-link"
                        activeProps={{ className: 'nav-link active' }}
                      >
                        Examples
                      </Link>
                    </div>
                  )}
                </div>

                <div className="flex items-center space-x-4">
                  {user ? (
                    <div className="flex items-center space-x-3">
                      <span className="text-sm text-gray-700">
                        Welcome, {user.name}
                      </span>
                      <Link
                        to="/logout"
                        className="btn btn-outline text-sm"
                      >
                        Logout
                      </Link>
                    </div>
                  ) : (
                    <div className="flex items-center space-x-2">
                      <Link
                        to="/login"
                        className="nav-link"
                        activeProps={{ className: 'nav-link active' }}
                      >
                        Login
                      </Link>
                      <Link
                        to="/register"
                        className="btn btn-primary text-sm"
                      >
                        Sign Up
                      </Link>
                    </div>
                  )}
                </div>
              </div>
            </div>
          </nav>

          <main>
            {children}
          </main>
        </div>
        
        <TanStackRouterDevtools position="bottom-right" />
        <Scripts />
      </body>
    </html>
  )
}