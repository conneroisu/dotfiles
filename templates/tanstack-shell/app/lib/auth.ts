import { createServerFn } from '@tanstack/react-start'
import { eq } from 'drizzle-orm'
import bcrypt from 'bcryptjs'
import { SignJWT, jwtVerify } from 'jose'
import { zodValidator } from '@tanstack/zod-adapter'
import { db } from './db'
import { users, sessions, loginSchema, registerSchema, type User } from './schema'
import { getCookie, setCookie, deleteCookie } from 'vinxi/http'

const JWT_SECRET = new TextEncoder().encode(
  process.env.SESSION_SECRET || 'your-super-secret-session-key-change-this-in-production'
)

const SESSION_COOKIE_NAME = 'auth-session'
const SESSION_DURATION = 7 * 24 * 60 * 60 * 1000 // 7 days

// Auth helper functions
export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, 12)
}

export async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash)
}

export async function createSession(userId: number): Promise<string> {
  const sessionId = crypto.randomUUID()
  const expiresAt = new Date(Date.now() + SESSION_DURATION)

  await db.insert(sessions).values({
    id: sessionId,
    userId,
    expiresAt,
  })

  const token = await new SignJWT({ sessionId, userId })
    .setProtectedHeader({ alg: 'HS256' })
    .setExpirationTime(expiresAt)
    .setIssuedAt()
    .sign(JWT_SECRET)

  return token
}

export async function validateSession(token: string): Promise<User | null> {
  try {
    const { payload } = await jwtVerify(token, JWT_SECRET)
    const sessionId = payload.sessionId as string
    const userId = payload.userId as number

    // Check if session exists and is valid
    const session = await db.query.sessions.findFirst({
      where: eq(sessions.id, sessionId),
    })

    if (!session || session.expiresAt < new Date()) {
      return null
    }

    // Get user data
    const user = await db.query.users.findFirst({
      where: eq(users.id, userId),
    })

    return user || null
  } catch {
    return null
  }
}

export async function deleteSession(sessionId: string): Promise<void> {
  await db.delete(sessions).where(eq(sessions.id, sessionId))
}

// Server functions for authentication
export const login = createServerFn({ method: 'POST' })
  .validator(zodValidator(loginSchema))
  .handler(async ({ data }) => {
    const { email, password } = data

    // Find user by email
    const user = await db.query.users.findFirst({
      where: eq(users.email, email),
    })

    if (!user || !(await verifyPassword(password, user.passwordHash))) {
      throw new Error('Invalid email or password')
    }

    // Create session
    const token = await createSession(user.id)
    
    // Set session cookie
    setCookie(SESSION_COOKIE_NAME, token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      maxAge: SESSION_DURATION / 1000,
      path: '/',
    })

    return { success: true, user: { id: user.id, email: user.email, name: user.name, role: user.role } }
  })

export const register = createServerFn({ method: 'POST' })
  .validator(zodValidator(registerSchema))
  .handler(async ({ data }) => {
    const { email, password, name } = data

    // Check if user already exists
    const existingUser = await db.query.users.findFirst({
      where: eq(users.email, email),
    })

    if (existingUser) {
      throw new Error('User already exists with this email')
    }

    // Hash password and create user
    const passwordHash = await hashPassword(password)
    const [newUser] = await db.insert(users).values({
      email,
      passwordHash,
      name,
      role: 'user',
    }).returning()

    // Create session
    const token = await createSession(newUser.id)
    
    // Set session cookie
    setCookie(SESSION_COOKIE_NAME, token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      maxAge: SESSION_DURATION / 1000,
      path: '/',
    })

    return { success: true, user: { id: newUser.id, email: newUser.email, name: newUser.name, role: newUser.role } }
  })

export const logout = createServerFn({ method: 'POST' })
  .handler(async () => {
    const token = getCookie(SESSION_COOKIE_NAME)
    
    if (token) {
      try {
        const { payload } = await jwtVerify(token, JWT_SECRET)
        await deleteSession(payload.sessionId as string)
      } catch {
        // Invalid token, continue with logout
      }
    }

    deleteCookie(SESSION_COOKIE_NAME)
    return { success: true }
  })

export const getCurrentUser = createServerFn({ method: 'GET' })
  .handler(async () => {
    const token = getCookie(SESSION_COOKIE_NAME)
    
    if (!token) {
      return null
    }

    const user = await validateSession(token)
    return user ? { id: user.id, email: user.email, name: user.name, role: user.role } : null
  })