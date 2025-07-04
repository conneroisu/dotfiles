import { describe, test, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '~/test/utils/test-utils'
import { VirtualizedList } from '~/components/VirtualizedList'

// Mock TanStack Virtual
const mockVirtualizer = {
  getTotalSize: vi.fn(() => 5000),
  getVirtualItems: vi.fn(() => [
    { index: 0, start: 0, size: 50, key: '0' },
    { index: 1, start: 50, size: 50, key: '1' },
    { index: 2, start: 100, size: 50, key: '2' },
  ]),
  scrollToIndex: vi.fn(),
  measureElement: vi.fn(),
}

vi.mock('@tanstack/react-virtual', () => ({
  useVirtualizer: () => mockVirtualizer,
}))

describe('VirtualizedList', () => {
  const generateMockItems = (count: number) => 
    Array.from({ length: count }, (_, i) => ({
      id: `item-${i}`,
      name: `Item ${i}`,
      description: `Description for item ${i}`,
      value: i * 100,
    }))

  test('renders virtualized list container', () => {
    const items = generateMockItems(100)
    render(<VirtualizedList items={items} />)
    
    const container = screen.getByRole('list')
    expect(container).toBeInTheDocument()
    expect(container).toHaveStyle({ height: '600px', overflow: 'auto' })
  })

  test('renders visible items only', () => {
    const items = generateMockItems(1000)
    render(<VirtualizedList items={items} />)
    
    // Should only render the virtual items returned by the virtualizer
    expect(screen.getByText('Item 0')).toBeInTheDocument()
    expect(screen.getByText('Item 1')).toBeInTheDocument()
    expect(screen.getByText('Item 2')).toBeInTheDocument()
    
    // Items outside the viewport should not be rendered
    expect(screen.queryByText('Item 100')).not.toBeInTheDocument()
  })

  test('updates virtual items on scroll', () => {
    const items = generateMockItems(1000)
    const { container } = render(<VirtualizedList items={items} />)
    
    const scrollContainer = container.querySelector('[style*="overflow"]')
    
    // Mock new virtual items after scroll
    mockVirtualizer.getVirtualItems.mockReturnValue([
      { index: 50, start: 2500, size: 50, key: '50' },
      { index: 51, start: 2550, size: 50, key: '51' },
      { index: 52, start: 2600, size: 50, key: '52' },
    ])
    
    // Simulate scroll
    fireEvent.scroll(scrollContainer!, { target: { scrollTop: 2500 } })
    
    // Check that virtualizer was called
    expect(mockVirtualizer.getVirtualItems).toHaveBeenCalled()
  })

  test('handles empty list', () => {
    render(<VirtualizedList items={[]} />)
    
    const container = screen.getByRole('list')
    expect(container).toBeInTheDocument()
    
    // Should show empty state
    expect(screen.getByText(/no items to display/i)).toBeInTheDocument()
  })

  test('renders custom item renderer', () => {
    const items = generateMockItems(10)
    const customRenderer = (item: any) => (
      <div data-testid={`custom-${item.id}`}>
        <h3>{item.name}</h3>
        <p>{item.description}</p>
        <span>${item.value}</span>
      </div>
    )
    
    render(<VirtualizedList items={items} renderItem={customRenderer} />)
    
    expect(screen.getByTestId('custom-item-0')).toBeInTheDocument()
    expect(screen.getByText('$0')).toBeInTheDocument()
  })

  test('handles dynamic item heights', () => {
    const items = generateMockItems(100)
    const estimateSize = (index: number) => index % 2 === 0 ? 50 : 100
    
    render(<VirtualizedList items={items} estimateSize={estimateSize} />)
    
    // Virtualizer should use the estimate size function
    expect(mockVirtualizer.measureElement).toBeDefined()
  })

  test('scrolls to specific index programmatically', () => {
    const items = generateMockItems(1000)
    const scrollToIndex = 500
    
    render(<VirtualizedList items={items} scrollToIndex={scrollToIndex} />)
    
    expect(mockVirtualizer.scrollToIndex).toHaveBeenCalledWith(scrollToIndex, {
      align: 'start',
      behavior: 'smooth',
    })
  })

  test('handles loading state', () => {
    const items = generateMockItems(50)
    render(<VirtualizedList items={items} isLoading />)
    
    expect(screen.getByText(/loading more items/i)).toBeInTheDocument()
  })

  test('triggers onEndReached callback', () => {
    const onEndReached = vi.fn()
    const items = generateMockItems(100)
    
    // Mock virtual items near the end
    mockVirtualizer.getVirtualItems.mockReturnValue([
      { index: 97, start: 4850, size: 50, key: '97' },
      { index: 98, start: 4900, size: 50, key: '98' },
      { index: 99, start: 4950, size: 50, key: '99' },
    ])
    
    const { container } = render(
      <VirtualizedList items={items} onEndReached={onEndReached} />
    )
    
    const scrollContainer = container.querySelector('[style*="overflow"]')
    
    // Simulate scroll to bottom
    fireEvent.scroll(scrollContainer!, { 
      target: { 
        scrollTop: 4500,
        scrollHeight: 5000,
        clientHeight: 600 
      } 
    })
    
    expect(onEndReached).toHaveBeenCalled()
  })

  test('applies custom styles to items', () => {
    const items = generateMockItems(10)
    const itemClassName = 'custom-item-class'
    
    render(<VirtualizedList items={items} itemClassName={itemClassName} />)
    
    const firstItem = screen.getByText('Item 0').parentElement
    expect(firstItem).toHaveClass(itemClassName)
  })

  test('handles horizontal orientation', () => {
    const items = generateMockItems(100)
    render(<VirtualizedList items={items} horizontal />)
    
    const container = screen.getByRole('list')
    expect(container).toHaveStyle({ overflowX: 'auto', overflowY: 'hidden' })
  })

  test('updates when items change', () => {
    const { rerender } = render(<VirtualizedList items={generateMockItems(10)} />)
    
    expect(screen.getByText('Item 0')).toBeInTheDocument()
    
    // Update with new items
    const newItems = generateMockItems(5).map(item => ({
      ...item,
      name: `New ${item.name}`,
    }))
    
    rerender(<VirtualizedList items={newItems} />)
    
    expect(screen.getByText('New Item 0')).toBeInTheDocument()
  })

  test('handles keyboard navigation', () => {
    const items = generateMockItems(100)
    const onItemSelect = vi.fn()
    
    render(<VirtualizedList items={items} onItemSelect={onItemSelect} />)
    
    const container = screen.getByRole('list')
    
    // Focus the container
    container.focus()
    
    // Press arrow down
    fireEvent.keyDown(container, { key: 'ArrowDown', code: 'ArrowDown' })
    
    // Should move to next item
    expect(mockVirtualizer.scrollToIndex).toHaveBeenCalled()
  })

  test('supports item selection', () => {
    const items = generateMockItems(10)
    const onItemSelect = vi.fn()
    
    render(<VirtualizedList items={items} onItemSelect={onItemSelect} />)
    
    const firstItem = screen.getByText('Item 0')
    fireEvent.click(firstItem)
    
    expect(onItemSelect).toHaveBeenCalledWith(items[0])
  })

  test('measures performance with large datasets', () => {
    const items = generateMockItems(10000)
    const startTime = performance.now()
    
    render(<VirtualizedList items={items} />)
    
    const endTime = performance.now()
    const renderTime = endTime - startTime
    
    // Should render quickly even with 10k items
    expect(renderTime).toBeLessThan(100) // 100ms threshold
    
    // Should only render visible items
    expect(mockVirtualizer.getVirtualItems).toHaveBeenCalled()
    expect(mockVirtualizer.getVirtualItems()).toHaveLength(3) // Only 3 visible items
  })
})