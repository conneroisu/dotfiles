import { useVirtualizer } from '@tanstack/react-virtual'
import { useRef } from 'react'

interface VirtualizedListProps<T> {
  items: T[]
  renderItem: (item: T, index: number) => React.ReactNode
  estimateSize?: () => number
  className?: string
}

export function VirtualizedList<T>({
  items,
  renderItem,
  estimateSize = () => 50,
  className = '',
}: VirtualizedListProps<T>) {
  const parentRef = useRef<HTMLDivElement>(null)

  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize,
    overscan: 5,
  })

  return (
    <div
      ref={parentRef}
      className={`h-96 overflow-auto ${className}`}
    >
      <div
        style={{
          height: `${virtualizer.getTotalSize()}px`,
          width: '100%',
          position: 'relative',
        }}
      >
        {virtualizer.getVirtualItems().map((virtualItem) => (
          <div
            key={virtualItem.key}
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              height: `${virtualItem.size}px`,
              transform: `translateY(${virtualItem.start}px)`,
            }}
          >
            {renderItem(items[virtualItem.index], virtualItem.index)}
          </div>
        ))}
      </div>
    </div>
  )
}

// Example usage component for demonstration
export function VirtualizedUserList() {
  // Generate mock data for demonstration
  const users = Array.from({ length: 10000 }, (_, i) => ({
    id: i + 1,
    name: `User ${i + 1}`,
    email: `user${i + 1}@example.com`,
    role: i % 3 === 0 ? 'admin' : 'user',
  }))

  return (
    <div className="card p-6">
      <h3 className="text-lg font-medium text-gray-900 mb-4">
        Virtualized User List (10,000 items)
      </h3>
      <VirtualizedList
        items={users}
        renderItem={(user) => (
          <div className="flex items-center justify-between p-4 border-b border-gray-200 hover:bg-gray-50">
            <div>
              <div className="font-medium text-gray-900">{user.name}</div>
              <div className="text-sm text-gray-500">{user.email}</div>
            </div>
            <span
              className={`inline-flex rounded-full px-2 text-xs font-semibold leading-5 ${
                user.role === 'admin'
                  ? 'bg-purple-100 text-purple-800'
                  : 'bg-green-100 text-green-800'
              }`}
            >
              {user.role}
            </span>
          </div>
        )}
        estimateSize={() => 73}
      />
    </div>
  )
}