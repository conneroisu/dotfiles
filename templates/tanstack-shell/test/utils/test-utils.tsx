import { ReactElement } from 'react'
import { render, RenderOptions } from '@testing-library/react'
import { RouterProvider, createMemoryHistory, createRootRoute, createRoute, createRouter } from '@tanstack/react-router'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'

// Create a custom render function that includes providers
export function renderWithProviders(
  ui: ReactElement,
  {
    route = '/',
    ...renderOptions
  }: RenderOptions & { route?: string } = {}
) {
  // Create query client for each test
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false },
    },
  })

  // Create memory history
  const memoryHistory = createMemoryHistory({
    initialEntries: [route],
  })

  // Create root route
  const rootRoute = createRootRoute()

  // Create test route
  const testRoute = createRoute({
    getParentRoute: () => rootRoute,
    path: '/',
    component: () => ui,
  })

  // Create router
  const router = createRouter({
    routeTree: rootRoute.addChildren([testRoute]),
    history: memoryHistory,
  })

  function Wrapper({ children }: { children: React.ReactNode }) {
    return (
      <QueryClientProvider client={queryClient}>
        <RouterProvider router={router}>
          {children}
        </RouterProvider>
      </QueryClientProvider>
    )
  }

  return {
    ...render(ui, { wrapper: Wrapper, ...renderOptions }),
    router,
    queryClient,
  }
}

// Re-export everything from testing library
export * from '@testing-library/react'
export { renderWithProviders as render }