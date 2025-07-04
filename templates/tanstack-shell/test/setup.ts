// Global test setup
import { expect, afterEach, beforeEach, vi } from 'vitest'
import { cleanup } from '@testing-library/react'
import * as matchers from '@testing-library/jest-dom/matchers'

// Extend Vitest's expect with jest-dom matchers
expect.extend(matchers)

// Mock environment variables
process.env.NODE_ENV = 'test'
process.env.SESSION_SECRET = 'test-secret-key-for-testing'
process.env.DATABASE_URL = ':memory:'

// Global test utilities
globalThis.fetch = vi.fn()

// Mock window.matchMedia
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(), // deprecated
    removeListener: vi.fn(), // deprecated
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
})

// Setup console mocking
beforeEach(() => {
  vi.clearAllMocks()
})

// Cleanup after each test
afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})