import { describe, test, expect, beforeAll, afterAll, beforeEach } from 'vitest'
import { db, runMigrations } from '~/lib/db'
import { users, sessions } from '~/lib/schema'
import { eq, and, gte, sql } from 'drizzle-orm'
import { hashPassword } from '~/lib/auth'
import Database from 'better-sqlite3'

describe('Database Operations', () => {
  let testDb: Database.Database

  beforeAll(async () => {
    // Create in-memory database for testing
    testDb = new Database(':memory:')
    
    // Run migrations
    await runMigrations(testDb)
  })

  afterAll(() => {
    testDb.close()
  })

  beforeEach(async () => {
    // Clear all data between tests
    await db.delete(sessions).execute()
    await db.delete(users).execute()
  })

  describe('User Operations', () => {
    test('creates a new user', async () => {
      const hashedPassword = await hashPassword('testpassword123')
      const userData = {
        name: 'Test User',
        email: 'test@example.com',
        password: hashedPassword,
      }

      const [newUser] = await db.insert(users).values(userData).returning()

      expect(newUser).toBeDefined()
      expect(newUser.id).toBeDefined()
      expect(newUser.name).toBe(userData.name)
      expect(newUser.email).toBe(userData.email)
      expect(newUser.password).toBe(hashedPassword)
      expect(newUser.createdAt).toBeInstanceOf(Date)
    })

    test('enforces unique email constraint', async () => {
      const userData = {
        name: 'Test User',
        email: 'duplicate@example.com',
        password: 'hashedpassword',
      }

      // First insert should succeed
      await db.insert(users).values(userData).execute()

      // Second insert with same email should fail
      await expect(
        db.insert(users).values({
          ...userData,
          name: 'Another User',
        }).execute()
      ).rejects.toThrow(/UNIQUE constraint failed/)
    })

    test('finds user by email', async () => {
      const userData = {
        name: 'Find Me',
        email: 'findme@example.com',
        password: 'hashedpassword',
      }

      await db.insert(users).values(userData).execute()

      const [foundUser] = await db
        .select()
        .from(users)
        .where(eq(users.email, userData.email))
        .execute()

      expect(foundUser).toBeDefined()
      expect(foundUser.email).toBe(userData.email)
      expect(foundUser.name).toBe(userData.name)
    })

    test('updates user information', async () => {
      const [user] = await db.insert(users).values({
        name: 'Original Name',
        email: 'update@example.com',
        password: 'hashedpassword',
      }).returning()

      const newName = 'Updated Name'
      const [updatedUser] = await db
        .update(users)
        .set({ name: newName })
        .where(eq(users.id, user.id))
        .returning()

      expect(updatedUser.name).toBe(newName)
      expect(updatedUser.email).toBe(user.email) // Email unchanged
    })

    test('deletes user', async () => {
      const [user] = await db.insert(users).values({
        name: 'Delete Me',
        email: 'delete@example.com',
        password: 'hashedpassword',
      }).returning()

      await db.delete(users).where(eq(users.id, user.id)).execute()

      const deletedUser = await db
        .select()
        .from(users)
        .where(eq(users.id, user.id))
        .execute()

      expect(deletedUser).toHaveLength(0)
    })

    test('counts total users', async () => {
      // Insert multiple users
      await db.insert(users).values([
        { name: 'User 1', email: 'user1@example.com', password: 'hash1' },
        { name: 'User 2', email: 'user2@example.com', password: 'hash2' },
        { name: 'User 3', email: 'user3@example.com', password: 'hash3' },
      ]).execute()

      const [result] = await db
        .select({ count: sql<number>`count(*)` })
        .from(users)
        .execute()

      expect(result.count).toBe(3)
    })

    test('paginates users', async () => {
      // Insert 10 users
      const usersData = Array.from({ length: 10 }, (_, i) => ({
        name: `User ${i}`,
        email: `user${i}@example.com`,
        password: 'hashedpassword',
      }))

      await db.insert(users).values(usersData).execute()

      // Get first page (5 items)
      const page1 = await db
        .select()
        .from(users)
        .orderBy(users.createdAt)
        .limit(5)
        .offset(0)
        .execute()

      expect(page1).toHaveLength(5)
      expect(page1[0].name).toBe('User 0')
      expect(page1[4].name).toBe('User 4')

      // Get second page
      const page2 = await db
        .select()
        .from(users)
        .orderBy(users.createdAt)
        .limit(5)
        .offset(5)
        .execute()

      expect(page2).toHaveLength(5)
      expect(page2[0].name).toBe('User 5')
      expect(page2[4].name).toBe('User 9')
    })

    test('searches users by name', async () => {
      await db.insert(users).values([
        { name: 'John Doe', email: 'john@example.com', password: 'hash1' },
        { name: 'Jane Smith', email: 'jane@example.com', password: 'hash2' },
        { name: 'John Smith', email: 'johnsmith@example.com', password: 'hash3' },
      ]).execute()

      const searchResults = await db
        .select()
        .from(users)
        .where(sql`${users.name} LIKE '%John%'`)
        .execute()

      expect(searchResults).toHaveLength(2)
      expect(searchResults.map(u => u.name)).toContain('John Doe')
      expect(searchResults.map(u => u.name)).toContain('John Smith')
    })
  })

  describe('Session Operations', () => {
    let testUser: typeof users.$inferSelect

    beforeEach(async () => {
      [testUser] = await db.insert(users).values({
        name: 'Session Test User',
        email: 'session@example.com',
        password: 'hashedpassword',
      }).returning()
    })

    test('creates a session', async () => {
      const sessionData = {
        userId: testUser.id,
        token: 'test-session-token',
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
      }

      const [session] = await db.insert(sessions).values(sessionData).returning()

      expect(session).toBeDefined()
      expect(session.id).toBeDefined()
      expect(session.userId).toBe(testUser.id)
      expect(session.token).toBe(sessionData.token)
      expect(session.expiresAt).toBeInstanceOf(Date)
    })

    test('finds session by token', async () => {
      const token = 'unique-session-token'
      await db.insert(sessions).values({
        userId: testUser.id,
        token,
        expiresAt: new Date(Date.now() + 1000000),
      }).execute()

      const [session] = await db
        .select()
        .from(sessions)
        .where(eq(sessions.token, token))
        .execute()

      expect(session).toBeDefined()
      expect(session.token).toBe(token)
    })

    test('validates session expiration', async () => {
      const now = new Date()
      
      // Create expired session
      await db.insert(sessions).values({
        userId: testUser.id,
        token: 'expired-token',
        expiresAt: new Date(now.getTime() - 1000), // 1 second ago
      }).execute()

      // Create valid session
      await db.insert(sessions).values({
        userId: testUser.id,
        token: 'valid-token',
        expiresAt: new Date(now.getTime() + 1000000), // Future
      }).execute()

      // Find only valid sessions
      const validSessions = await db
        .select()
        .from(sessions)
        .where(gte(sessions.expiresAt, now))
        .execute()

      expect(validSessions).toHaveLength(1)
      expect(validSessions[0].token).toBe('valid-token')
    })

    test('deletes expired sessions', async () => {
      const now = new Date()

      // Create multiple sessions
      await db.insert(sessions).values([
        {
          userId: testUser.id,
          token: 'expired-1',
          expiresAt: new Date(now.getTime() - 2000),
        },
        {
          userId: testUser.id,
          token: 'expired-2',
          expiresAt: new Date(now.getTime() - 1000),
        },
        {
          userId: testUser.id,
          token: 'valid-1',
          expiresAt: new Date(now.getTime() + 1000000),
        },
      ]).execute()

      // Delete expired sessions
      await db
        .delete(sessions)
        .where(sql`${sessions.expiresAt} < ${now}`)
        .execute()

      const remainingSessions = await db.select().from(sessions).execute()
      expect(remainingSessions).toHaveLength(1)
      expect(remainingSessions[0].token).toBe('valid-1')
    })

    test('gets user with active session', async () => {
      const token = 'active-session-token'
      await db.insert(sessions).values({
        userId: testUser.id,
        token,
        expiresAt: new Date(Date.now() + 1000000),
      }).execute()

      const [result] = await db
        .select({
          user: users,
          session: sessions,
        })
        .from(sessions)
        .innerJoin(users, eq(sessions.userId, users.id))
        .where(
          and(
            eq(sessions.token, token),
            gte(sessions.expiresAt, new Date())
          )
        )
        .execute()

      expect(result).toBeDefined()
      expect(result.user.email).toBe(testUser.email)
      expect(result.session.token).toBe(token)
    })

    test('updates session expiration', async () => {
      const [session] = await db.insert(sessions).values({
        userId: testUser.id,
        token: 'update-me',
        expiresAt: new Date(Date.now() + 1000000),
      }).returning()

      const newExpiration = new Date(Date.now() + 14 * 24 * 60 * 60 * 1000) // 14 days
      
      const [updated] = await db
        .update(sessions)
        .set({ expiresAt: newExpiration })
        .where(eq(sessions.id, session.id))
        .returning()

      expect(updated.expiresAt.getTime()).toBe(newExpiration.getTime())
    })
  })

  describe('Transactions', () => {
    test('creates user and session in transaction', async () => {
      const result = await db.transaction(async (tx) => {
        const [user] = await tx.insert(users).values({
          name: 'Transaction User',
          email: 'transaction@example.com',
          password: 'hashedpassword',
        }).returning()

        const [session] = await tx.insert(sessions).values({
          userId: user.id,
          token: 'transaction-token',
          expiresAt: new Date(Date.now() + 1000000),
        }).returning()

        return { user, session }
      })

      expect(result.user).toBeDefined()
      expect(result.session).toBeDefined()
      expect(result.session.userId).toBe(result.user.id)

      // Verify both were created
      const [foundUser] = await db
        .select()
        .from(users)
        .where(eq(users.id, result.user.id))
        .execute()
      
      const [foundSession] = await db
        .select()
        .from(sessions)
        .where(eq(sessions.id, result.session.id))
        .execute()

      expect(foundUser).toBeDefined()
      expect(foundSession).toBeDefined()
    })

    test('rolls back transaction on error', async () => {
      try {
        await db.transaction(async (tx) => {
          await tx.insert(users).values({
            name: 'Rollback User',
            email: 'rollback@example.com',
            password: 'hashedpassword',
          }).execute()

          // This should fail due to missing userId
          await tx.insert(sessions).values({
            userId: 'non-existent-id',
            token: 'fail-token',
            expiresAt: new Date(),
          }).execute()
        })
      } catch {
        // Transaction should have rolled back
      }

      // User should not exist
      const users = await db
        .select()
        .from(users)
        .where(eq(users.email, 'rollback@example.com'))
        .execute()

      expect(users).toHaveLength(0)
    })
  })
})