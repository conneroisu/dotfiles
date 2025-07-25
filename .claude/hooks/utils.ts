/**
 * Utility functions for Claude Code hook system
 * Provides logging, file operations, and error handling
 */

import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { join, dirname } from 'path';
import type { LogEntry, LogLevel, HookResult } from './types.ts';
import { getConfig } from './config.ts';

/**
 * Performance monitoring utilities
 */
export interface PerformanceMetrics {
  hookType: string;
  startTime: number;
  endTime: number;
  duration: number;
  memoryUsage: NodeJS.MemoryUsage;
  success: boolean;
  errorMessage?: string;
}

export class PerformanceMonitor {
  private static metrics: PerformanceMetrics[] = [];
  private static readonly MAX_METRICS = 100; // Keep last 100 executions

  static startTiming(hookType: string): number {
    return Date.now();
  }

  static endTiming(
    hookType: string,
    startTime: number,
    success: boolean,
    errorMessage?: string
  ): PerformanceMetrics {
    const endTime = Date.now();
    const metrics: PerformanceMetrics = {
      hookType,
      startTime,
      endTime,
      duration: endTime - startTime,
      memoryUsage: process.memoryUsage(),
      success,
      errorMessage,
    };

    // Store metrics if monitoring is enabled
    const config = getConfig();
    if (config.execution.enablePerformanceMonitoring) {
      this.metrics.push(metrics);

      // Keep only recent metrics
      if (this.metrics.length > this.MAX_METRICS) {
        this.metrics = this.metrics.slice(-this.MAX_METRICS);
      }

      // Log performance warnings
      this.checkPerformanceThresholds(metrics);
    }

    return metrics;
  }

  static getMetrics(): PerformanceMetrics[] {
    return [...this.metrics];
  }

  static getAverageMetrics(hookType?: string): Record<string, unknown> {
    const filteredMetrics = hookType
      ? this.metrics.filter((m) => m.hookType === hookType)
      : this.metrics;

    if (filteredMetrics.length === 0) {
      return { message: 'No metrics available' };
    }

    const avgDuration =
      filteredMetrics.reduce((sum, m) => sum + m.duration, 0) / filteredMetrics.length;
    const successRate = filteredMetrics.filter((m) => m.success).length / filteredMetrics.length;
    const avgMemory =
      filteredMetrics.reduce((sum, m) => sum + m.memoryUsage.heapUsed, 0) / filteredMetrics.length;

    return {
      hookType: hookType || 'all',
      totalExecutions: filteredMetrics.length,
      averageDuration: Math.round(avgDuration),
      successRate: Math.round(successRate * 100),
      averageMemoryUsage: Math.round(avgMemory / 1024 / 1024), // MB
      recentExecutions: filteredMetrics.slice(-5).map((m) => ({
        duration: m.duration,
        success: m.success,
        timestamp: new Date(m.startTime).toISOString(),
      })),
    };
  }

  private static checkPerformanceThresholds(metrics: PerformanceMetrics): void {
    const config = getConfig();
    const thresholds = {
      stop: config.execution.timeouts.linting * 0.8, // 80% of linting timeout
      general: config.execution.timeouts.general * 0.8,
      ai: config.execution.timeouts.aiCompletion * 0.8,
      tts: config.execution.timeouts.tts * 0.8,
    };

    const threshold = thresholds[metrics.hookType as keyof typeof thresholds] || thresholds.general;

    if (metrics.duration > threshold) {
      Logger.warn('Hook execution approaching timeout threshold', {
        hookType: metrics.hookType,
        duration: metrics.duration,
        threshold,
        memoryUsage: `${Math.round(metrics.memoryUsage.heapUsed / 1024 / 1024)}MB`,
      });
    }

    // Memory usage warning (>100MB)
    if (metrics.memoryUsage.heapUsed > 100 * 1024 * 1024) {
      Logger.warn('High memory usage detected', {
        hookType: metrics.hookType,
        memoryUsage: `${Math.round(metrics.memoryUsage.heapUsed / 1024 / 1024)}MB`,
        rss: `${Math.round(metrics.memoryUsage.rss / 1024 / 1024)}MB`,
      });
    }
  }

  static clearMetrics(): void {
    this.metrics = [];
  }
}

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
      data,
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
    const logEntry = data ? { level, message, timestamp, data } : { level, message, timestamp };

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
    const maxInputSize = 1048576; // 1MB limit to prevent DoS

    for await (const chunk of process.stdin) {
      totalSize += chunk.length;
      if (totalSize > maxInputSize) {
        throw new Error(
          `Input too large: ${totalSize} bytes exceeds limit of ${maxInputSize} bytes`
        );
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
      throw new Error(
        `Invalid JSON input: ${error instanceof Error ? error.message : 'Unknown error'}`
      );
    }
  }
}

export class SecurityValidator {
  private static ENV_PATTERNS = [/\.env$/, /\.env\./, /\.env_.*/, /.*\.env$/];

  private static ENV_EXCLUSIONS = [/\.env\.sample$/, /\.env\.example$/, /\.env\.template$/];

  static validateEnvFileAccess(
    toolName: string,
    toolInput: Record<string, unknown>
  ): { allowed: boolean; reason?: string } {
    if (!['Read', 'Edit', 'MultiEdit', 'Write'].includes(toolName)) {
      return { allowed: true };
    }

    const filePath = (
      toolInput && 'file_path' in toolInput
        ? toolInput['file_path']
        : toolInput && 'notebook_path' in toolInput
          ? toolInput['notebook_path']
          : ''
    ) as string;

    if (!filePath || typeof filePath !== 'string') {
      return { allowed: true };
    }

    const isEnvFile = this.ENV_PATTERNS.some((pattern) => pattern.test(filePath));
    const isExcluded = this.ENV_EXCLUSIONS.some((pattern) => pattern.test(filePath));

    if (isEnvFile && !isExcluded) {
      return {
        allowed: false,
        reason: `Access to .env files is blocked for security. File: ${filePath}`,
      };
    }

    return { allowed: true };
  }

  static validateDangerousCommands(
    toolName: string,
    toolInput: Record<string, unknown>
  ): { allowed: boolean; reason?: string } {
    if (toolName !== 'Bash') {
      return { allowed: true };
    }

    const command = (toolInput && 'command' in toolInput ? toolInput['command'] : '') as string;
    if (!command || typeof command !== 'string') {
      return { allowed: true };
    }

    // Comprehensive dangerous rm command patterns (currently informational only)
    const dangerousPatterns = [
      /rm\s+(-[rf]*[rf]+[^;]*|[^;]*-[rf]*[rf]+)/,
      /rm\s+.*\*/,
      /rm\s+.*\/\*/,
      /rm\s+-rf?\s+\/(?!tmp|var\/tmp)/,
      /sudo\s+rm/,
    ];

    for (const pattern of dangerousPatterns) {
      if (pattern.test(command)) {
        Logger.warn('Potentially dangerous rm command detected', {
          command,
          pattern: pattern.toString(),
        });
        // Currently only logging, not blocking
        break;
      }
    }

    return { allowed: true };
  }
}

export function createHookResult(
  success: boolean,
  message: string | undefined = undefined,
  blocked = false
): HookResult {
  return {
    success,
    message,
    blocked,
    exit_code: blocked ? 2 : success ? 0 : 1,
  };
}

/**
 * Enhanced hook result with performance metrics
 */
export function createHookResultWithMetrics(
  success: boolean,
  message: string | undefined = undefined,
  blocked = false,
  metrics?: PerformanceMetrics
): HookResult & { metrics?: PerformanceMetrics } {
  const result = createHookResult(success, message, blocked);
  return metrics ? { ...result, metrics } : result;
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
  const config = getConfig();
  const {
    timeout = config.execution.timeouts.general,
    maxOutputSize = config.security.maxOutputSize,
  } = options;

  // Validate command before execution
  const validation = validateCommandString(command);
  if (!validation.valid) {
    Logger.error('Command validation failed', { command, reason: validation.reason });
    throw new Error(`Command validation failed: ${validation.reason}`);
  }

  // Use shell mode for complex commands with pipes, but be careful about injection
  const proc = Bun.spawn(['sh', '-c', command], {
    stdout: 'pipe',
    stderr: 'pipe',
  });

  // Set up timeout
  const timeoutPromise = new Promise<never>((_, reject) => {
    setTimeout(() => {
      proc.kill();
      reject(new Error(`Command timed out after ${timeout / 1000}s`));
    }, timeout);
  });

  try {
    // Race between command completion and timeout
    const [stdout, stderr, exitCode] = await Promise.race([
      Promise.all([
        limitResponseSize(new Response(proc.stdout).text(), maxOutputSize),
        limitResponseSize(new Response(proc.stderr).text(), maxOutputSize),
        proc.exited,
      ]),
      timeoutPromise,
    ]);

    return { stdout, stderr, exitCode };
  } catch (error) {
    proc.kill(); // Ensure process is cleaned up
    throw error;
  }
}

async function limitResponseSize(
  responsePromise: Promise<string>,
  maxSize: number
): Promise<string> {
  const response = await responsePromise;
  if (response.length > maxSize) {
    Logger.warn('Command output truncated due to size limit', {
      actualSize: response.length,
      maxSize,
      truncatedBytes: response.length - maxSize,
    });
    return response.substring(0, maxSize) + '\n... [output truncated]';
  }
  return response;
}

export async function executeShellCommandSafe(
  command: string,
  args: string[] = []
): Promise<{ stdout: string; stderr: string; exitCode: number }> {
  // Safer version that executes command with separate arguments
  const proc = Bun.spawn([command, ...args], {
    stdout: 'pipe',
    stderr: 'pipe',
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

  // Check for suspicious patterns that could be harmful
  const suspiciousPatterns = [
    /;\s*rm\s+-rf/,
    /&&\s*rm\s+-rf/,
    /\|\s*rm\s+-rf/,
    /`.*rm.*`/,
    /\$\(.*rm.*\)/,
    /eval\s+.*["'`]/,
    />\s*\/dev\/sd[a-z]/,
  ];

  for (const pattern of suspiciousPatterns) {
    if (pattern.test(command)) {
      Logger.warn('Potentially dangerous command pattern detected', {
        command: command.substring(0, 100),
        pattern: pattern.toString(),
      });
      return { valid: false, reason: `Potentially dangerous command pattern detected` };
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
