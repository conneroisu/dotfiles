import { describe, test, expect } from 'vitest'

describe('Example Test Suite', () => {
  test('basic arithmetic', () => {
    expect(2 + 2).toBe(4)
  })

  test('string operations', () => {
    const str = 'Hello, Vitest!'
    expect(str).toContain('Vitest')
    expect(str.length).toBe(14)
  })

  test('array operations', () => {
    const arr = [1, 2, 3, 4, 5]
    expect(arr).toHaveLength(5)
    expect(arr).toContain(3)
  })

  test('object comparison', () => {
    const obj = { name: 'Test', value: 42 }
    expect(obj).toEqual({ name: 'Test', value: 42 })
    expect(obj).toHaveProperty('name', 'Test')
  })

  test('async operations', async () => {
    const promise = Promise.resolve('success')
    await expect(promise).resolves.toBe('success')
  })
})