import { describe, test, expect, vi, beforeEach } from 'vitest'
import { hashPassword, verifyPassword, createSession, validateSession } from '~/lib/auth'
import bcrypt from 'bcryptjs'
import { SignJWT, jwtVerify } from 'jose'

// Mock bcryptjs
vi.mock('bcryptjs', () => ({
  default: {
    hash: vi.fn(),
    compare: vi.fn(),
  },
}))

// Mock jose
vi.mock('jose', () => ({
  SignJWT: vi.fn(() => ({
    setProtectedHeader: vi.fn().mockReturnThis(),
    setIssuedAt: vi.fn().mockReturnThis(),
    setExpirationTime: vi.fn().mockReturnThis(),
    setSubject: vi.fn().mockReturnThis(),
    sign: vi.fn().mockResolvedValue('mocked-jwt-token'),
  })),
  jwtVerify: vi.fn(),
}))

describe('Auth Functions', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('hashPassword', () => {
    test('hashes password with bcrypt', async () => {
      const password = 'testPassword123'
      const hashedPassword = 'hashed-password'
      
      vi.mocked(bcrypt.hash).mockResolvedValue(hashedPassword)
      
      const result = await hashPassword(password)
      
      expect(bcrypt.hash).toHaveBeenCalledWith(password, 10)
      expect(result).toBe(hashedPassword)
    })

    test('uses correct salt rounds', async () => {
      const password = 'testPassword123'
      
      await hashPassword(password)
      
      expect(bcrypt.hash).toHaveBeenCalledWith(password, 10)
    })
  })

  describe('verifyPassword', () => {
    test('returns true for matching password', async () => {
      const password = 'testPassword123'
      const hashedPassword = 'hashed-password'
      
      vi.mocked(bcrypt.compare).mockResolvedValue(true)
      
      const result = await verifyPassword(password, hashedPassword)
      
      expect(bcrypt.compare).toHaveBeenCalledWith(password, hashedPassword)
      expect(result).toBe(true)
    })

    test('returns false for non-matching password', async () => {
      const password = 'testPassword123'
      const hashedPassword = 'hashed-password'
      
      vi.mocked(bcrypt.compare).mockResolvedValue(false)
      
      const result = await verifyPassword(password, hashedPassword)
      
      expect(bcrypt.compare).toHaveBeenCalledWith(password, hashedPassword)
      expect(result).toBe(false)
    })
  })

  describe('createSession', () => {
    test('creates JWT token with user id', async () => {
      const userId = 'user-123'
      
      const result = await createSession(userId)
      
      expect(result).toBe('mocked-jwt-token')
      expect(SignJWT).toHaveBeenCalled()
    })

    test('sets correct token expiration', async () => {
      const userId = 'user-123'
      const mockSignJWT = {
        setProtectedHeader: vi.fn().mockReturnThis(),
        setIssuedAt: vi.fn().mockReturnThis(),
        setExpirationTime: vi.fn().mockReturnThis(),
        setSubject: vi.fn().mockReturnThis(),
        sign: vi.fn().mockResolvedValue('mocked-jwt-token'),
      }
      
      vi.mocked(SignJWT).mockImplementation(() => mockSignJWT as any)
      
      await createSession(userId)
      
      expect(mockSignJWT.setExpirationTime).toHaveBeenCalledWith('7d')
      expect(mockSignJWT.setSubject).toHaveBeenCalledWith(userId)
    })
  })

  describe('validateSession', () => {
    test('returns user id for valid token', async () => {
      const token = 'valid-jwt-token'
      const userId = 'user-123'
      
      vi.mocked(jwtVerify).mockResolvedValue({
        payload: { sub: userId },
        protectedHeader: {},
      })
      
      const result = await validateSession(token)
      
      expect(jwtVerify).toHaveBeenCalled()
      expect(result).toBe(userId)
    })

    test('returns null for invalid token', async () => {
      const token = 'invalid-jwt-token'
      
      vi.mocked(jwtVerify).mockRejectedValue(new Error('Invalid token'))
      
      const result = await validateSession(token)
      
      expect(result).toBe(null)
    })

    test('returns null for expired token', async () => {
      const token = 'expired-jwt-token'
      
      vi.mocked(jwtVerify).mockRejectedValue(new Error('Token expired'))
      
      const result = await validateSession(token)
      
      expect(result).toBe(null)
    })
  })
})