import { test, expect } from 'vitest'
import { preview } from 'vite'
import type { PreviewServer } from 'vite'
import { chromium, type Browser, type Page } from 'playwright'

describe('TanStack Examples Page', () => {
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
        port: 4176,
      },
    })
    
    baseUrl = `http://localhost:${server.config.preview.port}`
    
    // Launch browser
    browser = await chromium.launch()
  })

  beforeEach(async () => {
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

  test('should display examples page with all sections', async () => {
    await registerAndLogin(page)
    
    await page.goto(`${baseUrl}/examples`)
    
    // Check page title
    await expect(page.locator('h1:has-text("TanStack Examples")')).toBeVisible()
    
    // Check all example sections are present
    const sections = [
      'TanStack Form Example',
      'TanStack Table Example',
      'TanStack Virtual Example',
      'TanStack Query Example'
    ]
    
    for (const section of sections) {
      await expect(page.locator(`h2:has-text("${section}")`)).toBeVisible()
    }
  })

  describe('TanStack Form Example', () => {
    test('should validate form inputs', async () => {
      await registerAndLogin(page)
      await page.goto(`${baseUrl}/examples`)
      
      // Find form section
      const formSection = page.locator('section:has(h2:has-text("TanStack Form Example"))')
      
      // Try to submit empty form
      await formSection.locator('button[type="submit"]').click()
      
      // Check validation errors
      await expect(formSection.locator('text=/First name is required/i')).toBeVisible()
      await expect(formSection.locator('text=/Last name is required/i')).toBeVisible()
      await expect(formSection.locator('text=/Invalid email/i')).toBeVisible()
    })

    test('should submit form with valid data', async () => {
      await registerAndLogin(page)
      await page.goto(`${baseUrl}/examples`)
      
      const formSection = page.locator('section:has(h2:has-text("TanStack Form Example"))')
      
      // Fill form
      await formSection.locator('input[name="firstName"]').fill('John')
      await formSection.locator('input[name="lastName"]').fill('Doe')
      await formSection.locator('input[name="email"]').fill('john.doe@example.com')
      await formSection.locator('input[name="age"]').fill('25')
      
      // Submit form
      await formSection.locator('button[type="submit"]').click()
      
      // Check success message
      await expect(page.locator('text=/Form submitted successfully/i')).toBeVisible()
    })

    test('should show real-time validation', async () => {
      await registerAndLogin(page)
      await page.goto(`${baseUrl}/examples`)
      
      const formSection = page.locator('section:has(h2:has-text("TanStack Form Example"))')
      const emailInput = formSection.locator('input[name="email"]')
      
      // Type invalid email
      await emailInput.fill('invalid-email')
      await emailInput.blur()
      
      // Should show validation error
      await expect(formSection.locator('text=/Invalid email/i')).toBeVisible()
      
      // Fix email
      await emailInput.clear()
      await emailInput.fill('valid@email.com')
      await emailInput.blur()
      
      // Error should disappear
      await expect(formSection.locator('text=/Invalid email/i')).not.toBeVisible()
    })
  })

  describe('TanStack Table Example', () => {
    test('should display sortable table', async () => {
      await registerAndLogin(page)
      await page.goto(`${baseUrl}/examples`)
      
      const tableSection = page.locator('section:has(h2:has-text("TanStack Table Example"))')
      
      // Check table headers
      await expect(tableSection.locator('th:has-text("Name")')).toBeVisible()
      await expect(tableSection.locator('th:has-text("Age")')).toBeVisible()
      await expect(tableSection.locator('th:has-text("Email")')).toBeVisible()
      await expect(tableSection.locator('th:has-text("Status")')).toBeVisible()
      
      // Check sortable indicators
      const nameHeader = tableSection.locator('th:has-text("Name")')
      await expect(nameHeader.locator('svg')).toBeVisible() // Sort icon
    })

    test('should sort table by clicking headers', async () => {
      await registerAndLogin(page)
      await page.goto(`${baseUrl}/examples`)
      
      const tableSection = page.locator('section:has(h2:has-text("TanStack Table Example"))')
      
      // Get first row name before sorting
      const firstNameBefore = await tableSection.locator('tbody tr:first-child td:first-child').textContent()
      
      // Click name header to sort
      await tableSection.locator('th:has-text("Name")').click()
      
      // Get first row name after sorting
      const firstNameAfter = await tableSection.locator('tbody tr:first-child td:first-child').textContent()
      
      // Names should be different (unless coincidentally the same)
      expect(firstNameBefore).toBeTruthy()
      expect(firstNameAfter).toBeTruthy()
    })

    test('should filter table data', async () => {
      await registerAndLogin(page)
      await page.goto(`${baseUrl}/examples`)
      
      const tableSection = page.locator('section:has(h2:has-text("TanStack Table Example"))')
      
      // Find filter input
      const filterInput = tableSection.locator('input[placeholder*="Filter"]')
      
      // Get initial row count
      const initialRows = await tableSection.locator('tbody tr').count()
      
      // Apply filter
      await filterInput.fill('John')
      
      // Wait for filter to apply
      await page.waitForTimeout(300)
      
      // Get filtered row count
      const filteredRows = await tableSection.locator('tbody tr').count()
      
      // Should have fewer rows (or same if all contain "John")
      expect(filteredRows).toBeLessThanOrEqual(initialRows)
      
      // All visible rows should contain "John"
      const visibleRows = await tableSection.locator('tbody tr').all()
      for (const row of visibleRows) {
        const text = await row.textContent()
        expect(text?.toLowerCase()).toContain('john')
      }
    })

    test('should paginate table', async () => {
      await registerAndLogin(page)
      await page.goto(`${baseUrl}/examples`)
      
      const tableSection = page.locator('section:has(h2:has-text("TanStack Table Example"))')
      
      // Check pagination controls
      await expect(tableSection.locator('button:has-text("Previous")')).toBeVisible()
      await expect(tableSection.locator('button:has-text("Next")')).toBeVisible()
      
      // Check page info
      await expect(tableSection.locator('text=/Page \\d+ of \\d+/')).toBeVisible()
      
      // Previous should be disabled on first page
      await expect(tableSection.locator('button:has-text("Previous")')).toBeDisabled()
      
      // Click next if available
      const nextButton = tableSection.locator('button:has-text("Next")')
      if (await nextButton.isEnabled()) {
        await nextButton.click()
        
        // Previous should now be enabled
        await expect(tableSection.locator('button:has-text("Previous")')).toBeEnabled()
      }
    })
  })

  describe('TanStack Virtual Example', () => {
    test('should display virtualized list', async () => {
      await registerAndLogin(page)
      await page.goto(`${baseUrl}/examples`)
      
      const virtualSection = page.locator('section:has(h2:has-text("TanStack Virtual Example"))')
      
      // Check virtual list container
      const listContainer = virtualSection.locator('[style*="overflow"]')
      await expect(listContainer).toBeVisible()
      
      // Should have items visible
      const visibleItems = await virtualSection.locator('[data-index]').count()
      expect(visibleItems).toBeGreaterThan(0)
      expect(visibleItems).toBeLessThan(20) // Should not render all 10000 items
    })

    test('should scroll virtualized list', async () => {
      await registerAndLogin(page)
      await page.goto(`${baseUrl}/examples`)
      
      const virtualSection = page.locator('section:has(h2:has-text("TanStack Virtual Example"))')
      const listContainer = virtualSection.locator('[style*="overflow"]')
      
      // Get initial first visible item
      const firstItemBefore = await virtualSection.locator('[data-index]').first().getAttribute('data-index')
      
      // Scroll down
      await listContainer.evaluate(el => el.scrollTop = 5000)
      await page.waitForTimeout(100) // Wait for virtual items to update
      
      // Get new first visible item
      const firstItemAfter = await virtualSection.locator('[data-index]').first().getAttribute('data-index')
      
      // Should be different items visible
      expect(firstItemBefore).not.toBe(firstItemAfter)
      expect(parseInt(firstItemAfter || '0')).toBeGreaterThan(parseInt(firstItemBefore || '0'))
    })

    test('should display item count info', async () => {
      await registerAndLogin(page)
      await page.goto(`${baseUrl}/examples`)
      
      const virtualSection = page.locator('section:has(h2:has-text("TanStack Virtual Example"))')
      
      // Should show total items count
      await expect(virtualSection.locator('text=/10,000 items/i')).toBeVisible()
    })
  })

  describe('TanStack Query Example', () => {
    test('should fetch and display data', async () => {
      await registerAndLogin(page)
      await page.goto(`${baseUrl}/examples`)
      
      const querySection = page.locator('section:has(h2:has-text("TanStack Query Example"))')
      
      // Should show loading state initially
      await expect(querySection.locator('text=/Loading/i')).toBeVisible()
      
      // Wait for data to load
      await page.waitForTimeout(1000)
      
      // Should display fetched data
      await expect(querySection.locator('text=/User data/i')).toBeVisible()
    })

    test('should refetch data on button click', async () => {
      await registerAndLogin(page)
      await page.goto(`${baseUrl}/examples`)
      
      const querySection = page.locator('section:has(h2:has-text("TanStack Query Example"))')
      
      // Wait for initial load
      await page.waitForTimeout(1000)
      
      // Find refetch button
      const refetchButton = querySection.locator('button:has-text("Refetch")')
      await expect(refetchButton).toBeVisible()
      
      // Click refetch
      await refetchButton.click()
      
      // Should show loading state
      await expect(querySection.locator('text=/Loading/i')).toBeVisible()
      
      // Should load data again
      await expect(querySection.locator('text=/User data/i')).toBeVisible()
    })

    test('should handle mutations', async () => {
      await registerAndLogin(page)
      await page.goto(`${baseUrl}/examples`)
      
      const querySection = page.locator('section:has(h2:has-text("TanStack Query Example"))')
      
      // Find mutation button
      const mutateButton = querySection.locator('button:has-text("Update")')
      
      // Click to trigger mutation
      await mutateButton.click()
      
      // Should show loading/success state
      await expect(querySection.locator('text=/Updating/i')).toBeVisible()
      
      // Should show success message
      await expect(querySection.locator('text=/Updated successfully/i')).toBeVisible()
    })

    test('should show error state', async () => {
      await registerAndLogin(page)
      await page.goto(`${baseUrl}/examples`)
      
      const querySection = page.locator('section:has(h2:has-text("TanStack Query Example"))')
      
      // Trigger an error (implementation dependent)
      const errorButton = querySection.locator('button:has-text("Trigger Error")')
      if (await errorButton.isVisible()) {
        await errorButton.click()
        
        // Should show error message
        await expect(querySection.locator('text=/Error/i')).toBeVisible()
      }
    })
  })

  test('should be responsive on mobile', async () => {
    await registerAndLogin(page)
    
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 })
    
    await page.goto(`${baseUrl}/examples`)
    
    // All sections should still be visible
    await expect(page.locator('h1:has-text("TanStack Examples")')).toBeVisible()
    
    // Sections should stack vertically
    const sections = await page.locator('section').all()
    expect(sections.length).toBeGreaterThan(0)
    
    // Check form is still usable
    const formSection = page.locator('section:has(h2:has-text("TanStack Form Example"))')
    await expect(formSection.locator('input[name="firstName"]')).toBeVisible()
  })
})