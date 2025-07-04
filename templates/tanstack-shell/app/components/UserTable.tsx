import {
  createColumnHelper,
  flexRender,
  getCoreRowModel,
  useReactTable,
} from '@tanstack/react-table'
import { createServerFn } from '@tanstack/react-start'
import { db } from '~/lib/db'
import { users, type User } from '~/lib/schema'

const getAllUsers = createServerFn({ method: 'GET' })
  .handler(async () => {
    const allUsers = await db.select().from(users)
    return allUsers.map(user => ({
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      createdAt: user.createdAt,
    }))
  })

const columnHelper = createColumnHelper<Pick<User, 'id' | 'name' | 'email' | 'role' | 'createdAt'>>()

const columns = [
  columnHelper.accessor('id', {
    header: 'ID',
    cell: info => info.getValue(),
  }),
  columnHelper.accessor('name', {
    header: 'Name',
    cell: info => (
      <div className="font-medium text-gray-900">
        {info.getValue()}
      </div>
    ),
  }),
  columnHelper.accessor('email', {
    header: 'Email',
    cell: info => (
      <div className="text-gray-600">
        {info.getValue()}
      </div>
    ),
  }),
  columnHelper.accessor('role', {
    header: 'Role',
    cell: info => (
      <span className={`inline-flex rounded-full px-2 text-xs font-semibold leading-5 ${
        info.getValue() === 'admin' 
          ? 'bg-purple-100 text-purple-800' 
          : 'bg-green-100 text-green-800'
      }`}>
        {info.getValue()}
      </span>
    ),
  }),
  columnHelper.accessor('createdAt', {
    header: 'Created',
    cell: info => (
      <div className="text-sm text-gray-500">
        {new Date(info.getValue()).toLocaleDateString()}
      </div>
    ),
  }),
]

interface UserTableProps {
  data: Awaited<ReturnType<typeof getAllUsers>>
}

export function UserTable({ data }: UserTableProps) {
  const table = useReactTable({
    data,
    columns,
    getCoreRowModel: getCoreRowModel(),
  })

  return (
    <div className="card overflow-hidden">
      <div className="px-6 py-4 border-b border-gray-200">
        <h3 className="text-lg font-medium text-gray-900">Users</h3>
        <p className="text-sm text-gray-500">Manage application users</p>
      </div>
      
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            {table.getHeaderGroups().map(headerGroup => (
              <tr key={headerGroup.id}>
                {headerGroup.headers.map(header => (
                  <th
                    key={header.id}
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                  >
                    {header.isPlaceholder
                      ? null
                      : flexRender(
                          header.column.columnDef.header,
                          header.getContext()
                        )}
                  </th>
                ))}
              </tr>
            ))}
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {table.getRowModel().rows.map(row => (
              <tr key={row.id} className="hover:bg-gray-50">
                {row.getVisibleCells().map(cell => (
                  <td key={cell.id} className="px-6 py-4 whitespace-nowrap">
                    {flexRender(cell.column.columnDef.cell, cell.getContext())}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      
      {data.length === 0 && (
        <div className="text-center py-12">
          <p className="text-gray-500">No users found</p>
        </div>
      )}
    </div>
  )
}

export { getAllUsers }