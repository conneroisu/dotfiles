import Database from 'better-sqlite3'
import { drizzle } from 'drizzle-orm/better-sqlite3'
import { migrate } from 'drizzle-orm/better-sqlite3/migrator'
import * as schema from './schema'

const dbPath = process.env.DATABASE_URL?.replace('file:', '') || './db.sqlite'
const sqlite = new Database(dbPath)

// Enable WAL mode for better performance
sqlite.pragma('journal_mode = WAL')

export const db = drizzle(sqlite, { schema })

// Run migrations if needed
try {
  migrate(db, { migrationsFolder: './drizzle' })
} catch (error) {
  console.warn('Migration warning:', error)
}

export type DB = typeof db