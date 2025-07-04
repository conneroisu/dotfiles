import { createFileRoute } from '@tanstack/react-router'
import { VirtualizedUserList } from '~/components/VirtualizedList'

export const Route = createFileRoute('/_authenticated/examples')({
  component: ExamplesPage,
})

function ExamplesPage() {
  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">TanStack Examples</h1>
        <p className="text-gray-600">
          Demonstrations of TanStack first-party packages in action
        </p>
      </div>

      <div className="space-y-8">
        {/* TanStack Virtual Example */}
        <div>
          <h2 className="text-xl font-semibold text-gray-900 mb-4">
            TanStack Virtual
          </h2>
          <p className="text-gray-600 mb-4">
            Efficiently render large lists with virtualization. This example shows 10,000 items
            with smooth scrolling performance.
          </p>
          <VirtualizedUserList />
        </div>

        {/* TanStack Table Example */}
        <div>
          <h2 className="text-xl font-semibold text-gray-900 mb-4">
            TanStack Table
          </h2>
          <p className="text-gray-600 mb-4">
            The user table on the Users page demonstrates TanStack Table with sorting, filtering,
            and custom cell rendering capabilities.
          </p>
          <div className="card p-6">
            <p className="text-sm text-gray-500">
              ✨ Check out the <strong>Users</strong> page to see TanStack Table in action!
            </p>
          </div>
        </div>

        {/* TanStack Form Example */}
        <div>
          <h2 className="text-xl font-semibold text-gray-900 mb-4">
            TanStack Form
          </h2>
          <p className="text-gray-600 mb-4">
            Type-safe form handling with validation. See the login and registration forms
            for real-world examples.
          </p>
          <div className="card p-6">
            <p className="text-sm text-gray-500">
              ✨ The <strong>Login</strong> and <strong>Register</strong> pages showcase TanStack Form
              with Zod validation!
            </p>
          </div>
        </div>

        {/* TanStack Query Example */}
        <div>
          <h2 className="text-xl font-semibold text-gray-900 mb-4">
            TanStack Query
          </h2>
          <p className="text-gray-600 mb-4">
            Server state management with caching, background updates, and optimistic updates.
            Currently integrated with TanStack Start's server functions.
          </p>
          <div className="card p-6">
            <p className="text-sm text-gray-500">
              ✨ All data fetching in this app uses TanStack Query for optimal performance!
            </p>
          </div>
        </div>

        {/* TanStack Router Example */}
        <div>
          <h2 className="text-xl font-semibold text-gray-900 mb-4">
            TanStack Router
          </h2>
          <p className="text-gray-600 mb-4">
            Type-safe routing with search params, loaders, and protected routes.
            This entire application is built on TanStack Router.
          </p>
          <div className="card p-6">
            <div className="space-y-2 text-sm">
              <p><strong>Protected Routes:</strong> Authentication required pages</p>
              <p><strong>Search Params:</strong> Type-safe URL parameters</p>
              <p><strong>Loaders:</strong> Data fetching before route rendering</p>
              <p><strong>File-based Routing:</strong> Automatic route generation</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}