/**
 * Utility functions for Claude Code hook system
 * Provides logging, file operations, and error handling
 */

import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { join, dirname } from 'path';
import type { LogEntry, LogLevel, HookResult } from './types.ts';
import { ConfigManager } from './config.ts';

export class Logger {
  private static logsDir = join(dirname(import.meta.path), 'logs');

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
    let totalSize = 0;
    const config = ConfigManager.getInstance().getSecurityConfig();
    const maxInputSize = config.maxInputSize; // Configurable limit to prevent DoS
    
    for await (const chunk of process.stdin) {
      totalSize += chunk.length;
      if (totalSize > maxInputSize) {
        throw new Error(`Input too large: ${totalSize} bytes exceeds limit of ${maxInputSize} bytes`);
      }
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

  static validateEnvFileAccess(toolName: string, toolInput: Record<string, unknown>): { allowed: boolean; reason?: string } {
    if (!['Read', 'Edit', 'MultiEdit', 'Write'].includes(toolName)) {
      return { allowed: true };
    }

    const config = ConfigManager.getInstance().getSecurityConfig();
    
    // Skip validation if env file protection is disabled
    if (!config.enableEnvFileProtection) {
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

  static validateDangerousCommands(toolName: string, toolInput: Record<string, unknown>): { allowed: boolean; reason?: string } {
    if (toolName !== 'Bash') {
      return { allowed: true };
    }

    const command = toolInput?.command || '';
    if (!command || typeof command !== 'string') {
      return { allowed: true };
    }

    const config = ConfigManager.getInstance().getSecurityConfig();
    
    // Comprehensive dangerous rm command patterns
    const dangerousPatterns = [
      /rm\s+(-[rf]*[rf]+[^;]*|[^;]*-[rf]*[rf]+)/,
      /rm\s+.*\*/,
      /rm\s+.*\/\*/,
      /rm\s+-rf?\s+\/(?!tmp|var\/tmp)/,
      /sudo\s+rm/
    ];

    for (const pattern of dangerousPatterns) {
      if (pattern.test(command)) {
        const message = `Potentially dangerous rm command detected: ${command}`;
        Logger.warn(message, { command, pattern: pattern.toString() });
        
        if (config.blockDangerousCommands) {
          return {
            allowed: false,
            reason: `Dangerous command blocked for security: ${command}`
          };
        }
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

export async function executeShellCommand(
  command: string, 
  options: { timeout?: number; maxOutputSize?: number } = {}
): Promise<{ stdout: string; stderr: string; exitCode: number }> {
  const { timeout = 30000, maxOutputSize = 1048576 } = options; // 30s timeout, 1MB output limit
  
  // Validate command before execution
  const validation = validateCommandString(command);
  if (!validation.valid) {
    Logger.error('Command validation failed', { command, reason: validation.reason });
    throw new Error(`Command validation failed: ${validation.reason}`);
  }

  // Use shell mode for complex commands with pipes, but be careful about injection
  const proc = Bun.spawn(['sh', '-c', command], {
    stdout: 'pipe',
    stderr: 'pipe'
  });

  // Set up timeout
  const timeoutPromise = new Promise<never>((_, reject) => {
    setTimeout(() => {
      proc.kill();
      reject(new Error(`Command timed out after ${timeout}ms`));
    }, timeout);
  });

  try {
    // Race between command completion and timeout
    const [stdout, stderr, exitCode] = await Promise.race([
      Promise.all([
        limitResponseSize(new Response(proc.stdout).text(), maxOutputSize),
        limitResponseSize(new Response(proc.stderr).text(), maxOutputSize),
        proc.exited
      ]),
      timeoutPromise
    ]);

    return { stdout, stderr, exitCode };
  } catch (error) {
    proc.kill(); // Ensure process is cleaned up
    throw error;
  }
}

async function limitResponseSize(responsePromise: Promise<string>, maxSize: number): Promise<string> {
  const response = await responsePromise;
  if (response.length > maxSize) {
    Logger.warn('Command output truncated due to size limit', { 
      actualSize: response.length, 
      maxSize 
    });
    return response.substring(0, maxSize) + '\n... [output truncated]';
  }
  return response;
}

export async function executeShellCommandSafe(command: string, args: string[] = []): Promise<{ stdout: string; stderr: string; exitCode: number }> {
  // Safer version that executes command with separate arguments
  const proc = Bun.spawn([command, ...args], {
    stdout: 'pipe',
    stderr: 'pipe'
  });

  const stdout = await new Response(proc.stdout).text();
  const stderr = await new Response(proc.stderr).text();
  const exitCode = await proc.exited;

  return { stdout, stderr, exitCode };
}

export function escapeShellArg(arg: string): string {
  // Escape shell arguments to prevent injection
  return `'${arg.replace(/'/g, "'\\''")}'`;
}

export function validateCommandString(command: string): { valid: boolean; reason?: string } {
  // Basic validation for shell commands
  if (!command || typeof command !== 'string') {
    return { valid: false, reason: 'Command must be a non-empty string' };
  }

  if (command.length > 1000) {
    return { valid: false, reason: 'Command too long (max 1000 characters)' };
  }

  // Check for suspicious patterns
  const suspiciousPatterns = [
    /;\s*rm\s+-rf/,
    /&&\s*rm\s+-rf/,
    /\|\s*rm\s+-rf/,
    /`.*rm.*`/,
    /\$\(.*rm.*\)/
  ];

  for (const pattern of suspiciousPatterns) {
    if (pattern.test(command)) {
      return { valid: false, reason: `Potentially dangerous command pattern detected: ${pattern.toString()}` };
    }
  }

  return { valid: true };
}

export function validateFilePath(filePath: string): { valid: boolean; reason?: string } {
  // Basic validation for file paths
  if (!filePath || typeof filePath !== 'string') {
    return { valid: false, reason: 'File path must be a non-empty string' };
  }

  if (filePath.length > 500) {
    return { valid: false, reason: 'File path too long (max 500 characters)' };
  }

  // Check for path traversal attempts
  if (filePath.includes('../') || filePath.includes('..\\')) {
    return { valid: false, reason: 'Path traversal detected in file path' };
  }

  return { valid: true };
}