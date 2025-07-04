import { describe, test, expect, vi } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { RegisterForm } from '~/components/RegisterForm'

// Mock the router
vi.mock('@tanstack/react-router', () => ({
  useRouter: () => ({
    navigate: vi.fn(),
  }),
  useNavigate: () => vi.fn(),
}))

// Mock the server function
vi.mock('@tanstack/react-start', () => ({
  createServerFn: () => ({
    handler: vi.fn(),
  }),
}))

describe('RegisterForm', () => {
  test('renders register form with all fields', () => {
    render(<RegisterForm />)
    
    expect(screen.getByLabelText(/full name/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/email address/i)).toBeInTheDocument()
    expect(screen.getByLabelText('Password')).toBeInTheDocument()
    expect(screen.getByLabelText(/confirm password/i)).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /create account/i })).toBeInTheDocument()
  })

  test('shows validation errors for empty fields', async () => {
    const user = userEvent.setup()
    render(<RegisterForm />)
    
    const submitButton = screen.getByRole('button', { name: /create account/i })
    await user.click(submitButton)
    
    await waitFor(() => {
      expect(screen.getByText(/name must be at least 2 characters/i)).toBeInTheDocument()
      expect(screen.getByText(/invalid email/i)).toBeInTheDocument()
      expect(screen.getAllByText(/password must be at least 8 characters/i)).toHaveLength(2)
    })
  })

  test('validates name length', async () => {
    const user = userEvent.setup()
    render(<RegisterForm />)
    
    const nameInput = screen.getByLabelText(/full name/i)
    await user.type(nameInput, 'A')
    
    const submitButton = screen.getByRole('button', { name: /create account/i })
    await user.click(submitButton)
    
    await waitFor(() => {
      expect(screen.getByText(/name must be at least 2 characters/i)).toBeInTheDocument()
    })
  })

  test('validates password confirmation match', async () => {
    const user = userEvent.setup()
    render(<RegisterForm />)
    
    const passwordInput = screen.getByLabelText('Password')
    const confirmPasswordInput = screen.getByLabelText(/confirm password/i)
    
    await user.type(passwordInput, 'password123')
    await user.type(confirmPasswordInput, 'different123')
    
    const submitButton = screen.getByRole('button', { name: /create account/i })
    await user.click(submitButton)
    
    await waitFor(() => {
      expect(screen.getByText(/passwords do not match/i)).toBeInTheDocument()
    })
  })

  test('submits form with valid data', async () => {
    const user = userEvent.setup()
    render(<RegisterForm />)
    
    const nameInput = screen.getByLabelText(/full name/i)
    const emailInput = screen.getByLabelText(/email address/i)
    const passwordInput = screen.getByLabelText('Password')
    const confirmPasswordInput = screen.getByLabelText(/confirm password/i)
    
    await user.type(nameInput, 'Test User')
    await user.type(emailInput, 'test@example.com')
    await user.type(passwordInput, 'password123')
    await user.type(confirmPasswordInput, 'password123')
    
    const submitButton = screen.getByRole('button', { name: /create account/i })
    await user.click(submitButton)
    
    // Form should be submitted without validation errors
    await waitFor(() => {
      expect(screen.queryByText(/name must be at least 2 characters/i)).not.toBeInTheDocument()
      expect(screen.queryByText(/invalid email/i)).not.toBeInTheDocument()
      expect(screen.queryByText(/passwords do not match/i)).not.toBeInTheDocument()
    })
  })

  test('shows password strength indicator', async () => {
    const user = userEvent.setup()
    render(<RegisterForm />)
    
    const passwordInput = screen.getByLabelText('Password')
    
    // Weak password
    await user.type(passwordInput, 'weak')
    expect(screen.getByText(/too short/i)).toBeInTheDocument()
    
    // Medium password
    await user.clear(passwordInput)
    await user.type(passwordInput, 'medium123')
    expect(screen.queryByText(/too short/i)).not.toBeInTheDocument()
    
    // Strong password
    await user.clear(passwordInput)
    await user.type(passwordInput, 'Strong123!@#')
    expect(screen.queryByText(/too short/i)).not.toBeInTheDocument()
  })

  test('disables submit button while submitting', async () => {
    const user = userEvent.setup()
    render(<RegisterForm />)
    
    const nameInput = screen.getByLabelText(/full name/i)
    const emailInput = screen.getByLabelText(/email address/i)
    const passwordInput = screen.getByLabelText('Password')
    const confirmPasswordInput = screen.getByLabelText(/confirm password/i)
    
    await user.type(nameInput, 'Test User')
    await user.type(emailInput, 'test@example.com')
    await user.type(passwordInput, 'password123')
    await user.type(confirmPasswordInput, 'password123')
    
    const submitButton = screen.getByRole('button', { name: /create account/i })
    
    // Initially enabled
    expect(submitButton).not.toBeDisabled()
    
    await user.click(submitButton)
    
    // Should show loading state
    await waitFor(() => {
      expect(screen.getByRole('button', { name: /creating account/i })).toBeDisabled()
    })
  })

  test('shows login link', () => {
    render(<RegisterForm />)
    
    const loginLink = screen.getByText(/already have an account/i).parentElement
    expect(loginLink).toBeInTheDocument()
    expect(loginLink?.querySelector('a')).toHaveTextContent(/sign in/i)
  })
})