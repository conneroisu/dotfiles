/**
 * Utility functions for Claude Code hook system
 * 
 * Tiger Style implementation focused on:
 * - Safety: Input validation, assertions, bounded operations
 * - Performance: Efficient I/O, minimal allocations
 * - Developer Experience: Clear naming, simple interfaces
 */

import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { join } from 'path';
import type { LogEntry, LogLevel, HookResult } from './types.ts';

// Tiger Style: Fixed limits prevent unbounded resource usage
const MAX_LOG_ENTRIES_PER_FILE = 1000;
const MAX_LOG_ENTRY_SIZE_BYTES = 64 * 1024; // 64KB per entry
const MAX_COMMAND_EXECUTION_TIME_MS = 30 * 1000; // 30 seconds
const MAX_STDIN_SIZE_BYTES = 1024 * 1024; // 1MB

/**
 * Logger class following Tiger Style principles:
 * - Assertions validate all inputs and state
 * - Fixed limits prevent unbounded log growth
 * - Simple, predictable control flow
 */
export class Logger {
  private static readonly LOGS_DIRECTORY_NAME = 'logs';

  /**
   * Ensures log directory exists with proper error handling
   * Tiger Style: Fail-fast on filesystem errors
   */
  static ensureLogsDirectory(): void {
    try {
      if (!existsSync(this.LOGS_DIRECTORY_NAME)) {
        mkdirSync(this.LOGS_DIRECTORY_NAME, { recursive: true });
      }
    } catch (error) {
      // Tiger Style: Fail fast on programmer errors
      throw new Error(`Failed to create logs directory: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Appends entry to log file with bounded growth
   * Tiger Style: Input validation, fixed limits, simple control flow
   */
  static appendToLog(filename: string, data: unknown): void {
    // Tiger Style: Assert function arguments
    if (!filename || typeof filename !== 'string') {
      throw new Error('Filename must be a non-empty string');
    }

    // Tiger Style: Validate data size to prevent memory issues
    const serializedData = JSON.stringify(data);
    if (serializedData.length > MAX_LOG_ENTRY_SIZE_BYTES) {
      throw new Error(`Log entry too large: ${serializedData.length} bytes exceeds ${MAX_LOG_ENTRY_SIZE_BYTES} limit`);
    }

    this.ensureLogsDirectory();
    
    const logPath = join(this.LOGS_DIRECTORY_NAME, filename);
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
        Logger.error(`Failed to read existing log ${filename}`, { error });
        existingLogs = [];
      }
    }

    // Tiger Style: Bounded log growth prevents unbounded memory usage
    if (existingLogs.length >= MAX_LOG_ENTRIES_PER_FILE) {
      // Remove oldest entries to maintain fixed size
      existingLogs = existingLogs.slice(-MAX_LOG_ENTRIES_PER_FILE + 1);
    }

    existingLogs.push(entry);

    try {
      writeFileSync(logPath, JSON.stringify(existingLogs, null, 2));
    } catch (error) {
      // Tiger Style: Log errors but don't throw to prevent cascading failures
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

/**
 * Input reader with Tiger Style safety principles
 * Bounded operations and input validation prevent resource exhaustion
 */
export class InputReader {
  /**
   * Reads and parses JSON from stdin with safety limits
   * Tiger Style: Bounded input size, timeout protection, input validation
   */
  static async readStdinJson<T>(): Promise<T> {
    const chunks: Buffer[] = [];
    let totalSize = 0;
    
    // Tiger Style: Set up timeout protection
    const timeoutId = setTimeout(() => {
      throw new Error(`Stdin read timeout after ${MAX_COMMAND_EXECUTION_TIME_MS}ms`);
    }, MAX_COMMAND_EXECUTION_TIME_MS);

    try {
      for await (const chunk of process.stdin) {
        totalSize += chunk.length;
        
        // Tiger Style: Prevent memory exhaustion from large inputs
        if (totalSize > MAX_STDIN_SIZE_BYTES) {
          throw new Error(`Input too large: ${totalSize} bytes exceeds ${MAX_STDIN_SIZE_BYTES} limit`);
        }
        
        chunks.push(chunk);
      }
    } finally {
      clearTimeout(timeoutId);
    }
    
    const input = Buffer.concat(chunks).toString('utf-8');
    
    // Tiger Style: Validate input presence
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

  /**
   * Validates dangerous commands with Tiger Style safety
   * Tiger Style: Block actually dangerous operations, clear patterns
   */
  static validateDangerousCommands(toolName: string, toolInput: any): { allowed: boolean; reason?: string } {
    if (toolName !== 'Bash') {
      return { allowed: true };
    }

    const command = toolInput?.command || '';
    if (!command || typeof command !== 'string') {
      return { allowed: true };
    }

    // Tiger Style: Comprehensive dangerous command patterns with blocking enabled
    const dangerousPatterns = [
      { pattern: /rm\s+(-[rf]*[rf]+[^;]*|[^;]*-[rf]*[rf]+)/, description: 'recursive rm command' },
      { pattern: /rm\s+.*\*/, description: 'rm with wildcard' },
      { pattern: /rm\s+.*\/\*/, description: 'rm with directory wildcard' },
      { pattern: /rm\s+-rf?\s+\/(?!tmp\/|var\/tmp\/|home\/.*\/\.cache\/|home\/.*\/\.local\/tmp\/)/, description: 'rm targeting system directories' },
      { pattern: /sudo\s+rm/, description: 'sudo rm command' },
      { pattern: />\s*\/dev\/(?!null|zero|urandom)/, description: 'writing to system devices' },
      { pattern: /curl.*\|\s*sh/, description: 'piping remote content to shell' },
      { pattern: /wget.*\|\s*sh/, description: 'piping remote content to shell' },
      { pattern: /chmod\s+777/, description: 'overly permissive chmod' }
    ];

    for (const { pattern, description } of dangerousPatterns) {
      if (pattern.test(command)) {
        const reason = `Dangerous command blocked: ${description}. Command: ${command}`;
        Logger.error('Security violation: dangerous command blocked', { 
          command, 
          pattern: pattern.toString(),
          reason 
        });
        
        return { allowed: false, reason };
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

/**
 * Executes shell command with Tiger Style safety principles
 * Tiger Style: Bounded execution time, proper error handling, resource cleanup
 */
export async function executeShellCommand(
  command: string, 
  timeoutMs: number = MAX_COMMAND_EXECUTION_TIME_MS
): Promise<{ stdout: string; stderr: string; exitCode: number }> {
  // Tiger Style: Validate inputs
  if (!command || typeof command !== 'string') {
    throw new Error('Command must be a non-empty string');
  }

  // Tiger Style: Safer command parsing - use shell to handle complex commands properly
  const proc = Bun.spawn(['sh', '-c', command], {
    stdout: 'pipe',
    stderr: 'pipe'
  });

  // Tiger Style: Implement timeout protection
  const timeoutId = setTimeout(() => {
    proc.kill();
  }, timeoutMs);

  try {
    const stdout = await new Response(proc.stdout).text();
    const stderr = await new Response(proc.stderr).text();
    const exitCode = await proc.exited;

    return { stdout, stderr, exitCode };
  } finally {
    // Tiger Style: Always clean up resources
    clearTimeout(timeoutId);
  }
}