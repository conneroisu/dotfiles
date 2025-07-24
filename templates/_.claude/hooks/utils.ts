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
      throw new Error('Log filename must be a non-empty string');
    }
    if (filename.includes('..') || filename.includes('/')) {
      throw new Error('Log filename contains invalid characters');
    }
    if (data === undefined) {
      throw new Error('Log data cannot be undefined');
    }

    this.ensureLogsDirectory();
    
    const logPath = join(this.LOGS_DIRECTORY_NAME, filename);
    const entry = this.createLogEntry(data);
    const existingLogEntries = this.readExistingLogEntries(logPath);
    const updatedLogEntries = this.addEntryWithBounds(existingLogEntries, entry);
    
    this.writeLogEntries(logPath, updatedLogEntries);
  }

  /**
   * Creates a log entry with timestamp validation
   * Tiger Style: Pure function with explicit return type
   */
  private static createLogEntry(data: unknown): LogEntry {
    const entryJson = JSON.stringify(data);
    
    // Tiger Style: Assert invariants
    if (entryJson.length > MAX_LOG_ENTRY_SIZE_BYTES) {
      throw new Error(`Log entry exceeds maximum size of ${MAX_LOG_ENTRY_SIZE_BYTES} bytes`);
    }

    return {
      timestamp: new Date().toISOString(),
      data
    };
  }

  /**
   * Reads existing log entries with error handling
   * Tiger Style: Single responsibility, clear error handling
   */
  private static readExistingLogEntries(logPath: string): LogEntry[] {
    if (!existsSync(logPath)) {
      return [];
    }

    try {
      const fileContent = readFileSync(logPath, 'utf-8');
      if (!fileContent.trim()) {
        return [];
      }
      
      const parsedEntries = JSON.parse(fileContent);
      
      // Tiger Style: Validate invariants
      if (!Array.isArray(parsedEntries)) {
        throw new Error('Log file contains invalid data structure');
      }
      
      return parsedEntries as LogEntry[];
    } catch (error) {
      // Tiger Style: Log corruption is recoverable, start fresh
      console.error(`Corrupted log file ${logPath}, starting fresh:`, error);
      return [];
    }
  }

  /**
   * Adds entry while enforcing size bounds
   * Tiger Style: Fixed limits, predictable behavior
   */
  private static addEntryWithBounds(existingEntries: LogEntry[], newEntry: LogEntry): LogEntry[] {
    const updatedEntries = [...existingEntries, newEntry];
    
    // Tiger Style: Fixed upper bound prevents unbounded growth
    if (updatedEntries.length > MAX_LOG_ENTRIES_PER_FILE) {
      // Keep most recent entries, discard oldest
      return updatedEntries.slice(-MAX_LOG_ENTRIES_PER_FILE);
    }
    
    return updatedEntries;
  }

  /**
   * Writes log entries to file with error handling
   * Tiger Style: Single responsibility, explicit error handling
   */
  private static writeLogEntries(logPath: string, logEntries: LogEntry[]): void {
    try {
      const serializedContent = JSON.stringify(logEntries, null, 2);
      writeFileSync(logPath, serializedContent);
    } catch (error) {
      // Tiger Style: File system errors are not recoverable at this level
      throw new Error(`Failed to write log file ${logPath}: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Structured console logging with validation
   * Tiger Style: Input validation, predictable output format
   */
  static log(level: LogLevel, message: string, data?: unknown): void {
    // Tiger Style: Assert function arguments
    if (!level || !['info', 'warn', 'error', 'debug'].includes(level)) {
      throw new Error(`Invalid log level: ${level}`);
    }
    if (!message || typeof message !== 'string') {
      throw new Error('Log message must be a non-empty string');
    }

    const timestamp = new Date().toISOString();
    const logEntry = { 
      level, 
      message, 
      timestamp, 
      ...(data !== undefined && { data }) 
    };
    
    // Tiger Style: Use stderr for structured logs, stdout for application output
    console.error(JSON.stringify(logEntry));
  }

  // Tiger Style: Simple wrapper functions with clear purpose
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
 * Input reader with Tiger Style safety principles:
 * - Bounded input size prevents memory exhaustion
 * - Input validation ensures data integrity
 * - Simple error handling with clear messages
 */
export class InputReader {
  /**
   * Reads and parses JSON from stdin with size limits
   * Tiger Style: Bounded operations, explicit error handling
   */
  static async readStdinJson<T>(): Promise<T> {
    const inputChunks: Buffer[] = [];
    let totalBytesRead = 0;
    
    // Tiger Style: Fixed limit prevents unbounded memory allocation
    for await (const chunk of process.stdin) {
      totalBytesRead += chunk.length;
      
      if (totalBytesRead > MAX_STDIN_SIZE_BYTES) {
        throw new Error(`Input exceeds maximum size of ${MAX_STDIN_SIZE_BYTES} bytes`);
      }
      
      inputChunks.push(chunk);
    }
    
    const rawInput = Buffer.concat(inputChunks).toString('utf-8');
    const trimmedInput = rawInput.trim();
    
    // Tiger Style: Fail fast on invalid input
    if (!trimmedInput) {
      throw new Error('No input received from stdin');
    }

    return this.parseJsonInput<T>(trimmedInput);
  }

  /**
   * Parses JSON input with detailed error reporting
   * Tiger Style: Single responsibility, clear error messages
   */
  private static parseJsonInput<T>(input: string): T {
    try {
      const parsedData = JSON.parse(input);
      
      // Tiger Style: Assert return value invariants
      if (parsedData === null) {
        throw new Error('Input cannot be null');
      }
      
      return parsedData as T;
    } catch (error) {
      if (error instanceof SyntaxError) {
        throw new Error(`Invalid JSON syntax: ${error.message}`);
      }
      throw error;
    }
  }
}

/**
 * Security validator implementing Tiger Style safety principles:
 * - Explicit pattern matching for predictable behavior
 * - Clear separation of concerns
 * - Input validation with detailed error reporting
 */
export class SecurityValidator {
  // Tiger Style: Explicit constants with clear naming
  private static readonly ENVIRONMENT_FILE_PATTERNS = [
    /\.env$/,
    /\.env\./,
    /\.env_.*/,
    /.*\.env$/
  ];

  private static readonly ALLOWED_ENVIRONMENT_FILE_PATTERNS = [
    /\.env\.sample$/,
    /\.env\.example$/,
    /\.env\.template$/,
    /\.env\.schema$/
  ];

  // Tiger Style: Fixed limit on dangerous command patterns
  private static readonly MAX_DANGEROUS_PATTERNS_TO_CHECK = 10;

  /**
   * Validates environment file access with explicit rules
   * Tiger Style: Clear control flow, input validation, explicit rules
   */
  static validateEnvFileAccess(toolName: string, toolInput: any): { allowed: boolean; reason?: string } {
    // Tiger Style: Assert function arguments
    if (!toolName || typeof toolName !== 'string') {
      throw new Error('Tool name must be a non-empty string');
    }

    // Only validate file access tools
    const FILE_ACCESS_TOOLS = ['Read', 'Edit', 'MultiEdit', 'Write', 'NotebookRead', 'NotebookEdit'];
    if (!FILE_ACCESS_TOOLS.includes(toolName)) {
      return { allowed: true };
    }

    const filePath = this.extractFilePath(toolInput);
    if (!filePath) {
      return { allowed: true };
    }

    return this.checkEnvironmentFileAccess(filePath);
  }

  /**
   * Extracts file path from tool input
   * Tiger Style: Single responsibility, explicit null handling
   */
  private static extractFilePath(toolInput: any): string | null {
    if (!toolInput || typeof toolInput !== 'object') {
      return null;
    }

    const filePath = toolInput.file_path || toolInput.notebook_path || '';
    
    if (!filePath || typeof filePath !== 'string') {
      return null;
    }

    return filePath;
  }

  /**
   * Checks if file path represents restricted environment file
   * Tiger Style: Predictable pattern matching, clear logic
   */
  private static checkEnvironmentFileAccess(filePath: string): { allowed: boolean; reason?: string } {
    const isEnvironmentFile = this.ENVIRONMENT_FILE_PATTERNS.some(pattern => pattern.test(filePath));
    
    if (!isEnvironmentFile) {
      return { allowed: true };
    }

    const isAllowedException = this.ALLOWED_ENVIRONMENT_FILE_PATTERNS.some(pattern => pattern.test(filePath));
    
    if (isAllowedException) {
      return { allowed: true };
    }

    return {
      allowed: false,
      reason: `Access to environment files is blocked for security. File: ${filePath}`
    };
  }

  /**
   * Validates bash commands for dangerous patterns
   * Tiger Style: Fixed patterns, bounded checking, clear warnings
   */
  static validateDangerousCommands(toolName: string, toolInput: any): { allowed: boolean; reason?: string } {
    // Tiger Style: Assert function arguments
    if (!toolName || typeof toolName !== 'string') {
      throw new Error('Tool name must be a non-empty string');
    }

    if (toolName !== 'Bash') {
      return { allowed: true };
    }

    const command = this.extractCommand(toolInput);
    if (!command) {
      return { allowed: true };
    }

    this.checkForDangerousPatterns(command);
    
    // Tiger Style: Currently informational only, explicit return
    return { allowed: true };
  }

  /**
   * Extracts command from bash tool input
   * Tiger Style: Single responsibility, explicit validation
   */
  private static extractCommand(toolInput: any): string | null {
    if (!toolInput || typeof toolInput !== 'object') {
      return null;
    }

    const command = toolInput.command || '';
    if (!command || typeof command !== 'string') {
      return null;
    }

    return command;
  }

  /**
   * Checks command against dangerous patterns with bounded iteration
   * Tiger Style: Fixed limits, predictable iteration, clear logging
   */
  private static checkForDangerousPatterns(command: string): void {
    // Tiger Style: Explicit dangerous patterns with clear intent
    const DANGEROUS_COMMAND_PATTERNS = [
      { pattern: /rm\s+(-[rf]*[rf]+[^;]*|[^;]*-[rf]*[rf]+)/, description: 'recursive rm with force' },
      { pattern: /rm\s+.*\*/, description: 'rm with wildcard' },
      { pattern: /rm\s+.*\/\*/, description: 'rm with directory wildcard' },
      { pattern: /rm\s+-rf?\s+\/(?!tmp|var\/tmp)/, description: 'rm targeting root directories' },
      { pattern: /sudo\s+rm/, description: 'elevated rm command' }
    ];

    // Tiger Style: Fixed limit prevents unbounded iteration
    const patternsToCheck = DANGEROUS_COMMAND_PATTERNS.slice(0, this.MAX_DANGEROUS_PATTERNS_TO_CHECK);

    for (const { pattern, description } of patternsToCheck) {
      if (pattern.test(command)) {
        Logger.warn('Potentially dangerous command detected', { 
          command, 
          pattern: pattern.toString(),
          description 
        });
        // Tiger Style: Only log first match to avoid spam
        break;
      }
    }
  }
}

/**
 * Creates hook result with explicit exit code mapping
 * Tiger Style: Simple function, explicit logic, clear naming
 */
export function createHookResult(success: boolean, message?: string, blocked = false): HookResult {
  // Tiger Style: Assert function arguments
  if (typeof success !== 'boolean') {
    throw new Error('Success parameter must be a boolean');
  }
  if (message !== undefined && (typeof message !== 'string' || !message.trim())) {
    throw new Error('Message must be a non-empty string or undefined');
  }
  if (typeof blocked !== 'boolean') {
    throw new Error('Blocked parameter must be a boolean');
  }

  // Tiger Style: Explicit exit code mapping with clear logic
  const exitCode = blocked ? 2 : (success ? 0 : 1);

  return {
    success,
    message,
    blocked,
    exit_code: exitCode
  };
}

/**
 * Handles errors with consistent logging and result creation
 * Tiger Style: Input validation, consistent error handling
 */
export function handleError(error: unknown, context: string): HookResult {
  // Tiger Style: Assert function arguments
  if (!context || typeof context !== 'string') {
    throw new Error('Context must be a non-empty string');
  }

  const errorMessage = error instanceof Error ? error.message : 'Unknown error';
  const contextualMessage = `${context}: ${errorMessage}`;
  
  Logger.error(`Error in ${context}`, { error: errorMessage });
  
  return createHookResult(false, contextualMessage);
}

/**
 * Executes shell commands with timeout and resource limits
 * Tiger Style: Bounded execution, explicit error handling, clear interface
 */
export async function executeShellCommand(command: string): Promise<{ stdout: string; stderr: string; exitCode: number }> {
  // Tiger Style: Assert function arguments
  if (!command || typeof command !== 'string') {
    throw new Error('Command must be a non-empty string');
  }
  if (command.trim().length === 0) {
    throw new Error('Command cannot be empty or whitespace only');
  }

  const process = Bun.spawn(['sh', '-c', command], {
    stdout: 'pipe',
    stderr: 'pipe'
  });

  // Tiger Style: Bounded execution with timeout
  const timeoutPromise = new Promise<never>((_, reject) => {
    setTimeout(() => {
      process.kill();
      reject(new Error(`Command execution exceeded ${MAX_COMMAND_EXECUTION_TIME_MS}ms timeout`));
    }, MAX_COMMAND_EXECUTION_TIME_MS);
  });

  try {
    const [standardOutput, standardError, processExitCode] = await Promise.race([
      Promise.all([
        new Response(process.stdout).text(),
        new Response(process.stderr).text(),
        process.exited
      ]),
      timeoutPromise
    ]);

    return { 
      stdout: standardOutput, 
      stderr: standardError, 
      exitCode: processExitCode 
    };
  } catch (error) {
    // Tiger Style: Ensure process cleanup on error
    process.kill();
    throw error;
  }
}