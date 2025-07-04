import { useForm } from '@tanstack/react-form'
import { zodValidator } from '@tanstack/zod-adapter'
import { useRouter } from '@tanstack/react-router'
import { register } from '~/lib/auth'
import { registerSchema } from '~/lib/schema'

interface RegisterFormProps {
  onSuccess?: () => void
}

export function RegisterForm({ onSuccess }: RegisterFormProps) {
  const router = useRouter()

  const form = useForm({
    defaultValues: {
      name: '',
      email: '',
      password: '',
      confirmPassword: '',
    },
    onSubmit: async ({ value }) => {
      try {
        await register({ data: value })
        router.invalidate()
        if (onSuccess) {
          onSuccess()
        } else {
          await router.navigate({ to: '/dashboard' })
        }
      } catch (error) {
        // Form will handle the error display
        throw error
      }
    },
    validators: {
      onChange: registerSchema,
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
        name="name"
        validators={{
          onChange: zodValidator(registerSchema.shape.name),
        }}
        children={(field) => (
          <div className="form-group">
            <label htmlFor={field.name} className="form-label">
              Full name
            </label>
            <input
              id={field.name}
              name={field.name}
              value={field.state.value}
              onBlur={field.handleBlur}
              onChange={(e) => field.handleChange(e.target.value)}
              type="text"
              autoComplete="name"
              required
              className={`input ${
                field.state.meta.errors.length > 0
                  ? 'border-red-300 focus:border-red-500 focus:ring-red-500'
                  : ''
              }`}
              placeholder="Enter your full name"
              disabled={form.state.isSubmitting}
            />
            {field.state.meta.errors.length > 0 && (
              <p className="form-error">{field.state.meta.errors[0]}</p>
            )}
          </div>
        )}
      />

      <form.Field
        name="email"
        validators={{
          onChange: zodValidator(registerSchema.shape.email),
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
          onChange: zodValidator(registerSchema.shape.password),
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
              autoComplete="new-password"
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

      <form.Field
        name="confirmPassword"
        validators={{
          onChange: zodValidator(registerSchema.shape.confirmPassword),
        }}
        children={(field) => (
          <div className="form-group">
            <label htmlFor={field.name} className="form-label">
              Confirm password
            </label>
            <input
              id={field.name}
              name={field.name}
              value={field.state.value}
              onBlur={field.handleBlur}
              onChange={(e) => field.handleChange(e.target.value)}
              type="password"
              autoComplete="new-password"
              required
              className={`input ${
                field.state.meta.errors.length > 0
                  ? 'border-red-300 focus:border-red-500 focus:ring-red-500'
                  : ''
              }`}
              placeholder="Confirm your password"
              disabled={form.state.isSubmitting}
            />
            {field.state.meta.errors.length > 0 && (
              <p className="form-error">{field.state.meta.errors[0]}</p>
            )}
          </div>
        )}
      />

      <div className="flex items-center">
        <input
          id="terms"
          name="terms"
          type="checkbox"
          required
          className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
          disabled={form.state.isSubmitting}
        />
        <label htmlFor="terms" className="ml-2 block text-sm text-gray-900">
          I agree to the{' '}
          <a href="#" className="text-primary-600 hover:text-primary-500">
            Terms of Service
          </a>{' '}
          and{' '}
          <a href="#" className="text-primary-600 hover:text-primary-500">
            Privacy Policy
          </a>
        </label>
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
          {form.state.isSubmitting ? 'Creating account...' : 'Create account'}
        </button>
      </div>
    </form>
  )
}