import { test, expect } from 'vitest'
import { preview } from 'vite'
import type { PreviewServer } from 'vite'
import { chromium, type Browser, type Page } from 'playwright'

describe('Authentication Flow', () => {
  let server: PreviewServer
  let browser: Browser
  let page: Page
  let baseUrl: string

  beforeAll(async () => {
    // Start preview server
    server = await preview({
      preview: {
        port: 4173,
      },
    })
    
    baseUrl = `http://localhost:${server.config.preview.port}`
    
    // Launch browser
    browser = await chromium.launch()
  })

  beforeEach(async () => {
    // Create new page for each test
    page = await browser.newPage()
  })

  afterEach(async () => {
    await page.close()
  })

  afterAll(async () => {
    await browser.close()
    await new Promise<void>((resolve, reject) => {
      server.httpServer.close((err) => (err ? reject(err) : resolve()))
    })
  })

  test('should display login page', async () => {
    await page.goto(`${baseUrl}/login`)
    
    // Check page title
    await expect(page).toHaveTitle(/Login/)
    
    // Check form elements exist
    const emailInput = page.locator('input[name="email"]')
    const passwordInput = page.locator('input[name="password"]')
    const submitButton = page.locator('button[type="submit"]')
    
    await expect(emailInput).toBeVisible()
    await expect(passwordInput).toBeVisible()
    await expect(submitButton).toBeVisible()
    await expect(submitButton).toHaveText(/Sign in/i)
  })

  test('should show validation errors for empty form', async () => {
    await page.goto(`${baseUrl}/login`)
    
    // Click submit without filling form
    await page.click('button[type="submit"]')
    
    // Check for validation messages
    const errorMessages = page.locator('.text-red-500')
    await expect(errorMessages).toHaveCount(2) // Email and password errors
  })

  test('should navigate to register page', async () => {
    await page.goto(`${baseUrl}/login`)
    
    // Click register link
    await page.click('text="Sign up"')
    
    // Wait for navigation
    await page.waitForURL(/\/register/)
    
    // Check we're on register page
    await expect(page).toHaveTitle(/Register/)
  })

  test('should display register page', async () => {
    await page.goto(`${baseUrl}/register`)
    
    // Check form elements
    const nameInput = page.locator('input[name="name"]')
    const emailInput = page.locator('input[name="email"]')
    const passwordInput = page.locator('input[name="password"]')
    const confirmPasswordInput = page.locator('input[name="confirmPassword"]')
    const submitButton = page.locator('button[type="submit"]')
    
    await expect(nameInput).toBeVisible()
    await expect(emailInput).toBeVisible()
    await expect(passwordInput).toBeVisible()
    await expect(confirmPasswordInput).toBeVisible()
    await expect(submitButton).toHaveText(/Create account/i)
  })

  test('should validate password confirmation', async () => {
    await page.goto(`${baseUrl}/register`)
    
    // Fill form with mismatched passwords
    await page.fill('input[name="name"]', 'Test User')
    await page.fill('input[name="email"]', 'test@example.com')
    await page.fill('input[name="password"]', 'password123')
    await page.fill('input[name="confirmPassword"]', 'different123')
    
    // Submit form
    await page.click('button[type="submit"]')
    
    // Check for error message
    const errorMessage = page.locator('text="Passwords do not match"')
    await expect(errorMessage).toBeVisible()
  })

  test('should handle successful registration flow', async () => {
    await page.goto(`${baseUrl}/register`)
    
    // Fill registration form
    const timestamp = Date.now()
    await page.fill('input[name="name"]', 'Test User')
    await page.fill('input[name="email"]', `test${timestamp}@example.com`)
    await page.fill('input[name="password"]', 'TestPassword123!')
    await page.fill('input[name="confirmPassword"]', 'TestPassword123!')
    
    // Submit form
    await page.click('button[type="submit"]')
    
    // Should redirect to dashboard after successful registration
    await page.waitForURL(/\/dashboard/, { timeout: 10000 })
    await expect(page).toHaveURL(/\/dashboard/)
  })

  test('should handle login with registered user', async () => {
    // First register a user
    await page.goto(`${baseUrl}/register`)
    const timestamp = Date.now()
    const email = `test${timestamp}@example.com`
    const password = 'TestPassword123!'
    
    await page.fill('input[name="name"]', 'Test User')
    await page.fill('input[name="email"]', email)
    await page.fill('input[name="password"]', password)
    await page.fill('input[name="confirmPassword"]', password)
    await page.click('button[type="submit"]')
    
    // Wait for registration to complete
    await page.waitForURL(/\/dashboard/)
    
    // Logout
    await page.goto(`${baseUrl}/logout`)
    
    // Now login with the same credentials
    await page.goto(`${baseUrl}/login`)
    await page.fill('input[name="email"]', email)
    await page.fill('input[name="password"]', password)
    await page.click('button[type="submit"]')
    
    // Should redirect to dashboard
    await page.waitForURL(/\/dashboard/, { timeout: 10000 })
    await expect(page).toHaveURL(/\/dashboard/)
  })

  test('should protect authenticated routes', async () => {
    // Try to access dashboard without authentication
    await page.goto(`${baseUrl}/dashboard`)
    
    // Should redirect to login
    await page.waitForURL(/\/login/)
    await expect(page).toHaveURL(/\/login/)
  })

  test('should handle logout', async () => {
    // First login
    await page.goto(`${baseUrl}/register`)
    const timestamp = Date.now()
    await page.fill('input[name="name"]', 'Test User')
    await page.fill('input[name="email"]', `test${timestamp}@example.com`)
    await page.fill('input[name="password"]', 'TestPassword123!')
    await page.fill('input[name="confirmPassword"]', 'TestPassword123!')
    await page.click('button[type="submit"]')
    
    // Wait for dashboard
    await page.waitForURL(/\/dashboard/)
    
    // Click logout button
    const logoutButton = page.locator('button:has-text("Logout")')
    await logoutButton.click()
    
    // Should redirect to home
    await page.waitForURL(/^\/$|\/login/)
    
    // Try to access dashboard again
    await page.goto(`${baseUrl}/dashboard`)
    
    // Should redirect to login
    await page.waitForURL(/\/login/)
  })
})