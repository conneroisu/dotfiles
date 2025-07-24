/**
 * Utility functions for Claude Code hook system
 * Provides logging, file operations, and error handling
 */

import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { join } from 'path';
import type { LogEntry, LogLevel, HookResult } from './types.ts';

export class Logger {
  private static logsDir = 'logs';

  static ensureLogsDirectory(): void {
    if (!existsSync(this.logsDir)) {
      mkdirSync(this.logsDir, { recursive: true });
    }
  }

  static appendToLog(filename: string, data: unknown): void {
    this.ensureLogsDirectory();
    
    const logPath = join(this.logsDir, filename);
    const entry: LogEntry = {
      timestamp: new Date().toISOString(),
      data
    };

    let existingLogs: LogEntry[] = [];
    
    if (existsSync(logPath)) {
      try {
        const content = readFileSync(logPath, 'utf-8');
        existingLogs = content ? JSON.parse(content) : [];
      } catch (error) {
        console.error(`Failed to read existing log ${filename}:`, error);
        existingLogs = [];
      }
    }

    existingLogs.push(entry);

    try {
      writeFileSync(logPath, JSON.stringify(existingLogs, null, 2));
    } catch (error) {
      console.error(`Failed to write log ${filename}:`, error);
    }
  }

  static log(level: LogLevel, message: string, data?: unknown): void {
    const timestamp = new Date().toISOString();
    const logEntry = { level, message, timestamp, ...(data && { data }) };
    
    console.error(JSON.stringify(logEntry));
  }

  static info(message: string, data?: unknown): void {
    this.log('info', message, data);
  }

  static warn(message: string, data?: unknown): void {
    this.log('warn', message, data);
  }

  static error(message: string, data?: unknown): void {
    this.log('error', message, data);
  }

  static debug(message: string, data?: unknown): void {
    this.log('debug', message, data);
  }
}

export class InputReader {
  static async readStdinJson<T>(): Promise<T> {
    const chunks: Buffer[] = [];
    
    for await (const chunk of process.stdin) {
      chunks.push(chunk);
    }
    
    const input = Buffer.concat(chunks).toString('utf-8');
    
    if (!input.trim()) {
      throw new Error('No input received from stdin');
    }

    try {
      return JSON.parse(input) as T;
    } catch (error) {
      throw new Error(`Invalid JSON input: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }
}

export class SecurityValidator {
  private static ENV_PATTERNS = [
    /\.env$/,
    /\.env\./,
    /\.env_.*/,
    /.*\.env$/
  ];

  private static ENV_EXCLUSIONS = [
    /\.env\.sample$/,
    /\.env\.example$/,
    /\.env\.template$/
  ];

  static validateEnvFileAccess(toolName: string, toolInput: any): { allowed: boolean; reason?: string } {
    if (!['Read', 'Edit', 'MultiEdit', 'Write'].includes(toolName)) {
      return { allowed: true };
    }

    const filePath = toolInput?.file_path || toolInput?.notebook_path || '';
    
    if (!filePath || typeof filePath !== 'string') {
      return { allowed: true };
    }

    const isEnvFile = this.ENV_PATTERNS.some(pattern => pattern.test(filePath));
    const isExcluded = this.ENV_EXCLUSIONS.some(pattern => pattern.test(filePath));

    if (isEnvFile && !isExcluded) {
      return {
        allowed: false,
        reason: `Access to .env files is blocked for security. File: ${filePath}`
      };
    }

    return { allowed: true };
  }

  static validateDangerousCommands(toolName: string, toolInput: any): { allowed: boolean; reason?: string } {
    if (toolName !== 'Bash') {
      return { allowed: true };
    }

    const command = toolInput?.command || '';
    if (!command || typeof command !== 'string') {
      return { allowed: true };
    }

    // Comprehensive dangerous rm command patterns (currently informational only)
    const dangerousPatterns = [
      /rm\s+(-[rf]*[rf]+[^;]*|[^;]*-[rf]*[rf]+)/,
      /rm\s+.*\*/,
      /rm\s+.*\/\*/,
      /rm\s+-rf?\s+\/(?!tmp|var\/tmp)/,
      /sudo\s+rm/
    ];

    for (const pattern of dangerousPatterns) {
      if (pattern.test(command)) {
        Logger.warn('Potentially dangerous rm command detected', { command, pattern: pattern.toString() });
        // Currently only logging, not blocking
        break;
      }
    }

    return { allowed: true };
  }
}

export function createHookResult(success: boolean, message?: string, blocked = false): HookResult {
  return {
    success,
    message,
    blocked,
    exit_code: blocked ? 2 : (success ? 0 : 1)
  };
}

export function handleError(error: unknown, context: string): HookResult {
  const message = error instanceof Error ? error.message : 'Unknown error';
  Logger.error(`Error in ${context}`, { error: message });
  return createHookResult(false, `${context}: ${message}`);
}

export async function executeShellCommand(command: string): Promise<{ stdout: string; stderr: string; exitCode: number }> {
  const proc = Bun.spawn(command.split(' '), {
    stdout: 'pipe',
    stderr: 'pipe'
  });

  const stdout = await new Response(proc.stdout).text();
  const stderr = await new Response(proc.stderr).text();
  const exitCode = await proc.exited;

  return { stdout, stderr, exitCode };
}