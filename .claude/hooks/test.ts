/**
 * Basic test suite for Claude Code hooks system
 * Demonstrates testing approach using Bun's built-in test runner
 */

import { test, expect, describe } from 'bun:test';
import { Logger, SecurityValidator, InputReader, executeShellCommand } from './utils.ts';
import { existsSync, rmSync } from 'fs';

describe('Logger', () => {
  const testLogsDir = 'test-logs';
  
  test('should create logs directory', () => {
    // Clean up any existing test logs
    if (existsSync(testLogsDir)) {
      rmSync(testLogsDir, { recursive: true });
    }
    
    Logger.ensureLogsDirectory();
    expect(existsSync('logs')).toBe(true);
  });

  test('should reject invalid filename', () => {
    expect(() => {
      Logger.appendToLog('', { test: 'data' });
    }).toThrow('Filename must be a non-empty string');
  });

  test('should reject oversized log entries', () => {
    const largeData = 'x'.repeat(65 * 1024); // Exceeds 64KB limit
    
    expect(() => {
      Logger.appendToLog('test.json', { data: largeData });
    }).toThrow('Log entry too large');
  });
});

describe('SecurityValidator', () => {
  test('should block dangerous rm commands', () => {
    const result = SecurityValidator.validateDangerousCommands('Bash', {
      command: 'rm -rf /'
    });
    
    expect(result.allowed).toBe(false);
    expect(result.reason).toContain('Dangerous command blocked');
  });

  test('should allow safe commands', () => {
    const result = SecurityValidator.validateDangerousCommands('Bash', {
      command: 'ls -la'
    });
    
    expect(result.allowed).toBe(true);
  });

  test('should block .env file access', () => {
    const result = SecurityValidator.validateEnvFileAccess('Read', {
      file_path: '/path/to/.env'
    });
    
    expect(result.allowed).toBe(false);
    expect(result.reason).toContain('Access to .env files is blocked');
  });

  test('should allow .env.example access', () => {
    const result = SecurityValidator.validateEnvFileAccess('Read', {
      file_path: '/path/to/.env.example'  
    });
    
    expect(result.allowed).toBe(true);
  });
});

describe('executeShellCommand', () => {
  test('should execute simple commands', async () => {
    const result = await executeShellCommand('echo "hello world"');
    
    expect(result.exitCode).toBe(0);
    expect(result.stdout.trim()).toBe('hello world');
  });

  test('should handle command with timeout', async () => {
    const startTime = Date.now();
    
    try {
      await executeShellCommand('sleep 2', 500); // 500ms timeout
    } catch (error) {
      // Command should be killed by timeout
    }
    
    const elapsed = Date.now() - startTime;
    expect(elapsed).toBeLessThan(1000); // Should be killed before 1 second
  });

  test('should reject invalid commands', async () => {
    expect(() => executeShellCommand('')).toThrow('Command must be a non-empty string');
  });
});