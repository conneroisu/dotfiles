import { describe, test, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '~/test/utils/test-utils'
import userEvent from '@testing-library/user-event'
import { LoginForm } from '~/components/LoginForm'

// Mock the login server function
const mockLogin = vi.fn()
vi.mock('~/lib/auth', () => ({
  login: {
    mutateAsync: (data: any) => mockLogin(data),
  },
}))

// Mock navigation
const mockNavigate = vi.fn()
vi.mock('@tanstack/react-router', () => ({
  ...vi.importActual('@tanstack/react-router'),
  useNavigate: () => mockNavigate,
}))

describe('LoginForm', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  test('renders login form with all fields', () => {
    render(<LoginForm />)
    
    expect(screen.getByLabelText(/email address/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/password/i)).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /sign in/i })).toBeInTheDocument()
  })

  test('shows validation errors for empty fields', async () => {
    const user = userEvent.setup()
    render(<LoginForm />)
    
    const submitButton = screen.getByRole('button', { name: /sign in/i })
    await user.click(submitButton)
    
    await waitFor(() => {
      expect(screen.getByText(/invalid email/i)).toBeInTheDocument()
      expect(screen.getByText(/password must be at least 8 characters/i)).toBeInTheDocument()
    })
  })

  test('validates email format', async () => {
    const user = userEvent.setup()
    render(<LoginForm />)
    
    const emailInput = screen.getByLabelText(/email address/i)
    await user.type(emailInput, 'invalid-email')
    
    const submitButton = screen.getByRole('button', { name: /sign in/i })
    await user.click(submitButton)
    
    await waitFor(() => {
      expect(screen.getByText(/invalid email/i)).toBeInTheDocument()
    })
  })

  test('validates password length', async () => {
    const user = userEvent.setup()
    render(<LoginForm />)
    
    const passwordInput = screen.getByLabelText(/password/i)
    await user.type(passwordInput, 'short')
    
    const submitButton = screen.getByRole('button', { name: /sign in/i })
    await user.click(submitButton)
    
    await waitFor(() => {
      expect(screen.getByText(/password must be at least 8 characters/i)).toBeInTheDocument()
    })
  })

  test('submits form with valid data and navigates on success', async () => {
    mockLogin.mockResolvedValueOnce({ success: true })
    const user = userEvent.setup()
    render(<LoginForm />)
    
    const emailInput = screen.getByLabelText(/email address/i)
    const passwordInput = screen.getByLabelText(/password/i)
    
    await user.type(emailInput, 'test@example.com')
    await user.type(passwordInput, 'password123')
    
    const submitButton = screen.getByRole('button', { name: /sign in/i })
    await user.click(submitButton)
    
    // Check that login was called with correct data
    await waitFor(() => {
      expect(mockLogin).toHaveBeenCalledWith({
        email: 'test@example.com',
        password: 'password123',
      })
      expect(mockNavigate).toHaveBeenCalledWith({ to: '/dashboard' })
    })
  })

  test('shows error message on login failure', async () => {
    mockLogin.mockRejectedValueOnce(new Error('Invalid credentials'))
    const user = userEvent.setup()
    render(<LoginForm />)
    
    const emailInput = screen.getByLabelText(/email address/i)
    const passwordInput = screen.getByLabelText(/password/i)
    
    await user.type(emailInput, 'test@example.com')
    await user.type(passwordInput, 'wrongpassword')
    
    const submitButton = screen.getByRole('button', { name: /sign in/i })
    await user.click(submitButton)
    
    await waitFor(() => {
      expect(screen.getByText(/invalid credentials/i)).toBeInTheDocument()
    })
  })

  test('disables submit button while submitting', async () => {
    // Make login take some time
    mockLogin.mockImplementationOnce(() => new Promise(resolve => setTimeout(resolve, 100)))
    
    const user = userEvent.setup()
    render(<LoginForm />)
    
    const emailInput = screen.getByLabelText(/email address/i)
    const passwordInput = screen.getByLabelText(/password/i)
    
    await user.type(emailInput, 'test@example.com')
    await user.type(passwordInput, 'password123')
    
    const submitButton = screen.getByRole('button', { name: /sign in/i })
    
    // Initially enabled
    expect(submitButton).not.toBeDisabled()
    
    await user.click(submitButton)
    
    // Should show loading state
    await waitFor(() => {
      expect(screen.getByRole('button', { name: /signing in/i })).toBeDisabled()
    })
  })

  test('clears password field on failed login', async () => {
    mockLogin.mockRejectedValueOnce(new Error('Invalid credentials'))
    const user = userEvent.setup()
    render(<LoginForm />)
    
    const emailInput = screen.getByLabelText(/email address/i)
    const passwordInput = screen.getByLabelText(/password/i) as HTMLInputElement
    
    await user.type(emailInput, 'test@example.com')
    await user.type(passwordInput, 'wrongpassword')
    
    const submitButton = screen.getByRole('button', { name: /sign in/i })
    await user.click(submitButton)
    
    await waitFor(() => {
      expect(passwordInput.value).toBe('')
    })
  })

  test('shows register link', () => {
    render(<LoginForm />)
    
    const registerLink = screen.getByText(/don't have an account/i).parentElement
    expect(registerLink).toBeInTheDocument()
    expect(registerLink?.querySelector('a')).toHaveTextContent(/sign up/i)
  })

  test('handles network errors gracefully', async () => {
    mockLogin.mockRejectedValueOnce(new Error('Network error'))
    const user = userEvent.setup()
    render(<LoginForm />)
    
    const emailInput = screen.getByLabelText(/email address/i)
    const passwordInput = screen.getByLabelText(/password/i)
    
    await user.type(emailInput, 'test@example.com')
    await user.type(passwordInput, 'password123')
    
    const submitButton = screen.getByRole('button', { name: /sign in/i })
    await user.click(submitButton)
    
    await waitFor(() => {
      expect(screen.getByText(/network error/i)).toBeInTheDocument()
    })
  })
})