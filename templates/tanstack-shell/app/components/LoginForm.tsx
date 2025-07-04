import { useForm } from '@tanstack/react-form'
import { zodValidator } from '@tanstack/zod-adapter'
import { useRouter } from '@tanstack/react-router'
import { login } from '~/lib/auth'
import { loginSchema } from '~/lib/schema'

interface LoginFormProps {
  redirectTo?: string
  onSuccess?: () => void
}

export function LoginForm({ redirectTo, onSuccess }: LoginFormProps) {
  const router = useRouter()

  const form = useForm({
    defaultValues: {
      email: '',
      password: '',
    },
    onSubmit: async ({ value }) => {
      try {
        await login({ data: value })
        router.invalidate()
        
        if (onSuccess) {
          onSuccess()
        } else {
          const targetPath = redirectTo || '/dashboard'
          await router.navigate({ to: targetPath })
        }
      } catch (error) {
        // Form will handle the error display
        throw error
      }
    },
    validators: {
      onChange: loginSchema,
    },
  })

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault()
        e.stopPropagation()
        form.handleSubmit()
      }}
      className="space-y-6"
    >
      <form.Field
        name="email"
        validators={{
          onChange: zodValidator(loginSchema.shape.email),
        }}
        children={(field) => (
          <div className="form-group">
            <label htmlFor={field.name} className="form-label">
              Email address
            </label>
            <input
              id={field.name}
              name={field.name}
              value={field.state.value}
              onBlur={field.handleBlur}
              onChange={(e) => field.handleChange(e.target.value)}
              type="email"
              autoComplete="email"
              required
              className={`input ${
                field.state.meta.errors.length > 0
                  ? 'border-red-300 focus:border-red-500 focus:ring-red-500'
                  : ''
              }`}
              placeholder="Enter your email"
              disabled={form.state.isSubmitting}
            />
            {field.state.meta.errors.length > 0 && (
              <p className="form-error">{field.state.meta.errors[0]}</p>
            )}
          </div>
        )}
      />

      <form.Field
        name="password"
        validators={{
          onChange: zodValidator(loginSchema.shape.password),
        }}
        children={(field) => (
          <div className="form-group">
            <label htmlFor={field.name} className="form-label">
              Password
            </label>
            <input
              id={field.name}
              name={field.name}
              value={field.state.value}
              onBlur={field.handleBlur}
              onChange={(e) => field.handleChange(e.target.value)}
              type="password"
              autoComplete="current-password"
              required
              className={`input ${
                field.state.meta.errors.length > 0
                  ? 'border-red-300 focus:border-red-500 focus:ring-red-500'
                  : ''
              }`}
              placeholder="Enter your password"
              disabled={form.state.isSubmitting}
            />
            {field.state.meta.errors.length > 0 && (
              <p className="form-error">{field.state.meta.errors[0]}</p>
            )}
          </div>
        )}
      />

      <div className="flex items-center justify-between">
        <div className="flex items-center">
          <input
            id="remember-me"
            name="remember-me"
            type="checkbox"
            className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
          />
          <label htmlFor="remember-me" className="ml-2 block text-sm text-gray-900">
            Remember me
          </label>
        </div>

        <div className="text-sm">
          <a
            href="#"
            className="font-medium text-primary-600 hover:text-primary-500"
          >
            Forgot your password?
          </a>
        </div>
      </div>

      {form.state.submissionAttempts > 0 && form.state.errors.length > 0 && (
        <div className="rounded-md bg-red-50 border border-red-200 p-4">
          <p className="text-sm text-red-700">
            {form.state.errors[0]}
          </p>
        </div>
      )}

      <div>
        <button
          type="submit"
          disabled={form.state.isSubmitting}
          className="btn btn-primary w-full flex justify-center items-center"
        >
          {form.state.isSubmitting && <div className="spinner mr-2" />}
          {form.state.isSubmitting ? 'Signing in...' : 'Sign in'}
        </button>
      </div>
    </form>
  )
}