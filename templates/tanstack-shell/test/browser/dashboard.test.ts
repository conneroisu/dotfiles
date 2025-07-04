import { test, expect } from 'vitest'
import { preview } from 'vite'
import type { PreviewServer } from 'vite'
import { chromium, type Browser, type Page } from 'playwright'

describe('Dashboard Functionality', () => {
  let server: PreviewServer
  let browser: Browser
  let page: Page
  let baseUrl: string


  // Helper to register and login
  async function registerAndLogin(page: Page) {
    const timestamp = Date.now()
    const email = `test${timestamp}@example.com`
    const password = 'TestPassword123!'
    
    await page.goto(`${baseUrl}/register`)
    await page.fill('input[name="name"]', 'Test User')
    await page.fill('input[name="email"]', email)
    await page.fill('input[name="password"]', password)
    await page.fill('input[name="confirmPassword"]', password)
    await page.click('button[type="submit"]')
    await page.waitForURL(/\/dashboard/)
    
    return { email, password }
  }

  beforeAll(async () => {
    // Start preview server
    server = await preview({
      preview: {
        port: 4174, // Different port from auth tests
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

  test('should display dashboard with user greeting', async () => {
    // Register and login
    await registerAndLogin(page)
    
    // Check for user greeting
    const greeting = page.locator('h1:has-text("Welcome back")')
    await expect(greeting).toBeVisible()
    await expect(greeting).toContainText('Test User')
  })

  test('should display dashboard statistics', async () => {
    await registerAndLogin(page)
    
    // Check for stat cards
    const statCards = page.locator('.stat-card')
    await expect(statCards).toHaveCount(4)
    
    // Check specific stats
    await expect(page.locator('text="Total Users"')).toBeVisible()
    await expect(page.locator('text="New This Week"')).toBeVisible()
    await expect(page.locator('text="Active Today"')).toBeVisible()
    await expect(page.locator('text="Conversion Rate"')).toBeVisible()
  })

  test('should display recent activity section', async () => {
    await registerAndLogin(page)
    
    // Check for recent activity section
    const recentActivitySection = page.locator('h3:has-text("Recent Activity")')
    await expect(recentActivitySection).toBeVisible()
    
    // Check for activity items
    const activityItems = page.locator('.flex.items-center.space-x-4')
    const count = await activityItems.count()
    expect(count).toBeGreaterThan(0)
  })

  test('should display quick actions', async () => {
    await registerAndLogin(page)
    
    // Check for quick actions section
    const quickActionsSection = page.locator('h3:has-text("Quick Actions")')
    await expect(quickActionsSection).toBeVisible()
    
    // Check for action buttons
    const actionButtons = [
      'Add User',
      'View Reports',
      'Settings',
      'Help'
    ]
    
    for (const buttonText of actionButtons) {
      const button = page.locator(`button:has-text("${buttonText}")`)
      await expect(button).toBeVisible()
    }
  })

  test('should navigate to users page', async () => {
    await registerAndLogin(page)
    
    // Click on Users link in navigation
    await page.click('a:has-text("Users")')
    
    // Wait for navigation
    await page.waitForURL(/\/users/)
    
    // Check we're on users page
    await expect(page.locator('h1:has-text("Users")')).toBeVisible()
  })

  test('should navigate to examples page', async () => {
    await registerAndLogin(page)
    
    // Click on Examples link in navigation
    await page.click('a:has-text("Examples")')
    
    // Wait for navigation
    await page.waitForURL(/\/examples/)
    
    // Check we're on examples page
    await expect(page.locator('h1:has-text("TanStack Examples")')).toBeVisible()
  })

  test('should handle navigation between protected routes', async () => {
    await registerAndLogin(page)
    
    // Navigate to users
    await page.click('a:has-text("Users")')
    await page.waitForURL(/\/users/)
    await expect(page.locator('h1:has-text("Users")')).toBeVisible()
    
    // Navigate to examples
    await page.click('a:has-text("Examples")')
    await page.waitForURL(/\/examples/)
    await expect(page.locator('h1:has-text("TanStack Examples")')).toBeVisible()
    
    // Navigate back to dashboard
    await page.click('a:has-text("Dashboard")')
    await page.waitForURL(/\/dashboard/)
    await expect(page.locator('h1:has-text("Welcome back")')).toBeVisible()
  })

  test('should maintain authentication across navigation', async () => {
    const { email } = await registerAndLogin(page)
    
    // Navigate through multiple pages
    await page.click('a:has-text("Users")')
    await page.waitForURL(/\/users/)
    
    await page.click('a:has-text("Examples")')
    await page.waitForURL(/\/examples/)
    
    // User should still be logged in
    const userEmail = page.locator(`text="${email}"`)
    await expect(userEmail).toBeVisible()
  })

  test('should refresh dashboard data on page reload', async () => {
    await registerAndLogin(page)
    
    // Get initial stat value
    const _totalUsersStatBefore = await page.locator('.stat-card:has-text("Total Users") .stat-value').textContent()
    
    // Reload page
    await page.reload()
    
    // Check stats are still displayed
    const totalUsersStatAfter = await page.locator('.stat-card:has-text("Total Users") .stat-value').textContent()
    expect(totalUsersStatAfter).toBeTruthy()
  })

  test('should handle responsive layout', async () => {
    await registerAndLogin(page)
    
    // Test mobile viewport
    await page.setViewportSize({ width: 375, height: 667 })
    
    // Stats should stack vertically on mobile
    const statCards = page.locator('.stat-card')
    await expect(statCards).toHaveCount(4)
    
    // Test tablet viewport
    await page.setViewportSize({ width: 768, height: 1024 })
    
    // Test desktop viewport
    await page.setViewportSize({ width: 1920, height: 1080 })
    
    // All elements should remain visible
    await expect(page.locator('h1:has-text("Welcome back")')).toBeVisible()
  })
})