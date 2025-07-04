import { createFileRoute, redirect } from '@tanstack/react-router'
import { logout } from '~/lib/auth'

export const Route = createFileRoute('/logout')({
  beforeLoad: async () => {
    await logout()
    throw redirect({ to: '/' })
  },
})