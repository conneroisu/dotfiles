import { describe, test, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { UserTable } from '~/components/UserTable'

// Mock TanStack Table
vi.mock('@tanstack/react-table', () => ({
  createColumnHelper: () => ({
    accessor: vi.fn((accessor, config) => ({ ...config, accessorFn: accessor })),
  }),
  useReactTable: vi.fn(() => ({
    getHeaderGroups: () => [{
      id: 'header-group',
      headers: [
        { id: 'name', column: { columnDef: { header: 'Name' } }, getContext: vi.fn() },
        { id: 'email', column: { columnDef: { header: 'Email' } }, getContext: vi.fn() },
        { id: 'status', column: { columnDef: { header: 'Status' } }, getContext: vi.fn() },
        { id: 'createdAt', column: { columnDef: { header: 'Joined' } }, getContext: vi.fn() },
        { id: 'actions', column: { columnDef: { header: 'Actions' } }, getContext: vi.fn() },
      ]
    }],
    getRowModel: () => ({
      rows: [
        {
          id: 'row-1',
          getVisibleCells: () => [
            { id: 'cell-1', column: { columnDef: { cell: () => 'John Doe' } }, getContext: vi.fn() },
            { id: 'cell-2', column: { columnDef: { cell: () => 'john@example.com' } }, getContext: vi.fn() },
            { id: 'cell-3', column: { columnDef: { cell: () => 'Active' } }, getContext: vi.fn() },
            { id: 'cell-4', column: { columnDef: { cell: () => '2024-01-01' } }, getContext: vi.fn() },
            { id: 'cell-5', column: { columnDef: { cell: () => 'Actions' } }, getContext: vi.fn() },
          ]
        }
      ]
    }),
    getState: () => ({ sorting: [] }),
  })),
  flexRender: vi.fn((content) => {
    if (typeof content === 'function') {
      return content()
    }
    return content
  }),
}))

describe('UserTable', () => {
  const mockUsers = [
    {
      id: '1',
      name: 'John Doe',
      email: 'john@example.com',
      createdAt: new Date('2024-01-01'),
    },
    {
      id: '2',
      name: 'Jane Smith',
      email: 'jane@example.com',
      createdAt: new Date('2024-01-02'),
    },
  ]

  test('renders user table with headers', () => {
    render(<UserTable users={mockUsers} />)
    
    // Check table headers
    expect(screen.getByText('Name')).toBeInTheDocument()
    expect(screen.getByText('Email')).toBeInTheDocument()
    expect(screen.getByText('Status')).toBeInTheDocument()
    expect(screen.getByText('Joined')).toBeInTheDocument()
    expect(screen.getByText('Actions')).toBeInTheDocument()
  })

  test('renders user data', () => {
    render(<UserTable users={mockUsers} />)
    
    // Check user data is displayed
    expect(screen.getByText('John Doe')).toBeInTheDocument()
    expect(screen.getByText('john@example.com')).toBeInTheDocument()
  })

  test('renders empty state when no users', () => {
    render(<UserTable users={[]} />)
    
    // Should still show headers even with no data
    expect(screen.getByText('Name')).toBeInTheDocument()
    expect(screen.getByText('Email')).toBeInTheDocument()
  })

  test('renders table with correct structure', () => {
    const { container } = render(<UserTable users={mockUsers} />)
    
    const table = container.querySelector('table')
    expect(table).toBeInTheDocument()
    
    const thead = container.querySelector('thead')
    expect(thead).toBeInTheDocument()
    
    const tbody = container.querySelector('tbody')
    expect(tbody).toBeInTheDocument()
  })
})