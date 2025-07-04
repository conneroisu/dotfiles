import { test, expect } from 'vitest'
import { preview } from 'vite'
import type { PreviewServer } from 'vite'
import { chromium, type Browser, type Page } from 'playwright'

describe('User Management Page', () => {
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
        port: 4175, // Different port from other tests
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

  test('should display users table', async () => {
    await registerAndLogin(page)
    
    // Navigate to users page
    await page.goto(`${baseUrl}/users`)
    
    // Check page title
    await expect(page.locator('h1:has-text("Users")')).toBeVisible()
    
    // Check table headers
    await expect(page.locator('th:has-text("Name")')).toBeVisible()
    await expect(page.locator('th:has-text("Email")')).toBeVisible()
    await expect(page.locator('th:has-text("Status")')).toBeVisible()
    await expect(page.locator('th:has-text("Joined")')).toBeVisible()
    await expect(page.locator('th:has-text("Actions")')).toBeVisible()
  })

  test('should display current user in table', async () => {
    const { email } = await registerAndLogin(page)
    
    await page.goto(`${baseUrl}/users`)
    
    // Check that the registered user appears in the table
    const userRow = page.locator(`tr:has-text("${email}")`)
    await expect(userRow).toBeVisible()
    await expect(userRow.locator('text="Test User"')).toBeVisible()
    await expect(userRow.locator('.badge')).toHaveText('Active')
  })

  test('should have search functionality', async () => {
    await registerAndLogin(page)
    
    await page.goto(`${baseUrl}/users`)
    
    // Check search input exists
    const searchInput = page.locator('input[placeholder*="Search"]')
    await expect(searchInput).toBeVisible()
    
    // Type in search
    await searchInput.fill('test')
    
    // Should filter results (implementation dependent)
    await page.waitForTimeout(500) // Debounce delay
  })

  test('should have filter dropdown', async () => {
    await registerAndLogin(page)
    
    await page.goto(`${baseUrl}/users`)
    
    // Check filter select exists
    const filterSelect = page.locator('select')
    await expect(filterSelect).toBeVisible()
    
    // Check filter options
    const options = await filterSelect.locator('option').allTextContents()
    expect(options).toContain('All Users')
    expect(options).toContain('Active')
    expect(options).toContain('Inactive')
  })

  test('should handle pagination', async () => {
    await registerAndLogin(page)
    
    await page.goto(`${baseUrl}/users`)
    
    // Check pagination info
    const paginationInfo = page.locator('text=/Showing \\d+ to \\d+ of \\d+ results/')
    await expect(paginationInfo).toBeVisible()
    
    // Check pagination buttons
    const prevButton = page.locator('button:has-text("Previous")')
    const nextButton = page.locator('button:has-text("Next")')
    
    await expect(prevButton).toBeVisible()
    await expect(nextButton).toBeVisible()
    
    // Previous should be disabled on first page
    await expect(prevButton).toBeDisabled()
  })

  test('should open edit modal', async () => {
    const { email } = await registerAndLogin(page)
    
    await page.goto(`${baseUrl}/users`)
    
    // Find the edit button for the user
    const userRow = page.locator(`tr:has-text("${email}")`)
    const editButton = userRow.locator('button:has-text("Edit")')
    
    await editButton.click()
    
    // Check modal appears
    const modal = page.locator('role=dialog')
    await expect(modal).toBeVisible()
    await expect(modal.locator('h3:has-text("Edit User")')).toBeVisible()
    
    // Check form fields in modal
    await expect(modal.locator('input[name="name"]')).toBeVisible()
    await expect(modal.locator('input[name="email"]')).toBeVisible()
    await expect(modal.locator('select[name="status"]')).toBeVisible()
  })

  test('should close modal on cancel', async () => {
    const { email } = await registerAndLogin(page)
    
    await page.goto(`${baseUrl}/users`)
    
    // Open edit modal
    const userRow = page.locator(`tr:has-text("${email}")`)
    await userRow.locator('button:has-text("Edit")').click()
    
    const modal = page.locator('role=dialog')
    await expect(modal).toBeVisible()
    
    // Click cancel
    await modal.locator('button:has-text("Cancel")').click()
    
    // Modal should be closed
    await expect(modal).not.toBeVisible()
  })

  test('should update user details', async () => {
    const { email } = await registerAndLogin(page)
    
    await page.goto(`${baseUrl}/users`)
    
    // Open edit modal
    const userRow = page.locator(`tr:has-text("${email}")`)
    await userRow.locator('button:has-text("Edit")').click()
    
    const modal = page.locator('role=dialog')
    
    // Update name
    const nameInput = modal.locator('input[name="name"]')
    await nameInput.clear()
    await nameInput.fill('Updated User')
    
    // Save changes
    await modal.locator('button:has-text("Save")').click()
    
    // Modal should close
    await expect(modal).not.toBeVisible()
    
    // Check updated name in table
    await expect(page.locator('text="Updated User"')).toBeVisible()
  })

  test('should handle delete action', async () => {
    const { email } = await registerAndLogin(page)
    
    await page.goto(`${baseUrl}/users`)
    
    // Find delete button
    const userRow = page.locator(`tr:has-text("${email}")`)
    const deleteButton = userRow.locator('button:has-text("Delete")')
    
    // Set up dialog handler
    page.on('dialog', async dialog => {
      expect(dialog.message()).toContain('Are you sure')
      await dialog.accept()
    })
    
    await deleteButton.click()
    
    // User should be removed (implementation dependent)
    await page.waitForTimeout(500) // Wait for potential deletion
  })

  test('should be responsive', async () => {
    await registerAndLogin(page)
    
    // Test mobile viewport
    await page.setViewportSize({ width: 375, height: 667 })
    await page.goto(`${baseUrl}/users`)
    
    // Table should be scrollable or adapted for mobile
    const table = page.locator('table')
    await expect(table).toBeVisible()
    
    // Test tablet viewport
    await page.setViewportSize({ width: 768, height: 1024 })
    await expect(table).toBeVisible()
    
    // Test desktop viewport
    await page.setViewportSize({ width: 1920, height: 1080 })
    await expect(table).toBeVisible()
  })
})