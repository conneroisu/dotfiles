import { createFileRoute } from '@tanstack/react-router'
import { UserTable, getAllUsers } from '~/components/UserTable'

export const Route = createFileRoute('/_authenticated/users')({
  loader: async () => {
    return getAllUsers()
  },
  component: UsersPage,
})

function UsersPage() {
  const users = Route.useLoaderData()

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">Users</h1>
        <p className="text-gray-600">
          Manage and view all application users
        </p>
      </div>

      <UserTable data={users} />
    </div>
  )
}