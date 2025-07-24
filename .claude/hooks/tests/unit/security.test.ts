import { test, expect, describe, beforeEach } from 'bun:test';
import { SecurityValidator } from '../../utils.ts';
import { ConfigManager } from '../../config.ts';

describe('SecurityValidator', () => {
  beforeEach(() => {
    // Reset configuration for each test
    ConfigManager.getInstance().reload();
  });

  describe('validateEnvFileAccess', () => {
    test('should block access to .env files', () => {
      const result = SecurityValidator.validateEnvFileAccess('Read', { file_path: '.env' });
      expect(result.allowed).toBe(false);
      expect(result.reason).toContain('Access to .env files is blocked');
    });

    test('should block access to .env.local files', () => {
      const result = SecurityValidator.validateEnvFileAccess('Edit', { file_path: '.env.local' });
      expect(result.allowed).toBe(false);
    });

    test('should allow access to .env.example files', () => {
      const result = SecurityValidator.validateEnvFileAccess('Read', { file_path: '.env.example' });
      expect(result.allowed).toBe(true);
    });

    test('should allow access to .env.template files', () => {
      const result = SecurityValidator.validateEnvFileAccess('Read', { file_path: '.env.template' });
      expect(result.allowed).toBe(true);
    });

    test('should allow access to non-env files', () => {
      const result = SecurityValidator.validateEnvFileAccess('Read', { file_path: 'config.json' });
      expect(result.allowed).toBe(true);
    });

    test('should allow non-file tools', () => {
      const result = SecurityValidator.validateEnvFileAccess('Bash', { command: 'ls -la' });
      expect(result.allowed).toBe(true);
    });

    test('should allow .env files when protection is disabled', () => {
      process.env.CLAUDE_HOOKS_PROTECT_ENV = 'false';
      ConfigManager.getInstance().reload();
      
      const result = SecurityValidator.validateEnvFileAccess('Read', { file_path: '.env' });
      expect(result.allowed).toBe(true);
      
      delete process.env.CLAUDE_HOOKS_PROTECT_ENV;
    });
  });

  describe('validateDangerousCommands', () => {
    test('should log but allow rm -rf commands when blocking is disabled (default)', () => {
      const result = SecurityValidator.validateDangerousCommands('Bash', { command: 'rm -rf /tmp/test' });
      expect(result.allowed).toBe(true); // Default behavior: only logging, not blocking
    });

    test('should block dangerous rm commands when blocking is enabled', () => {
      process.env.CLAUDE_HOOKS_BLOCK_DANGEROUS = 'true';
      ConfigManager.getInstance().reload();
      
      const result = SecurityValidator.validateDangerousCommands('Bash', { command: 'rm -rf /tmp/test' });
      expect(result.allowed).toBe(false);
      expect(result.reason).toContain('Dangerous command blocked for security');
      
      delete process.env.CLAUDE_HOOKS_BLOCK_DANGEROUS;
    });

    test('should block sudo rm commands when blocking is enabled', () => {
      process.env.CLAUDE_HOOKS_BLOCK_DANGEROUS = 'true';
      ConfigManager.getInstance().reload();
      
      const result = SecurityValidator.validateDangerousCommands('Bash', { command: 'sudo rm -rf /' });
      expect(result.allowed).toBe(false);
      expect(result.reason).toContain('Dangerous command blocked for security');
      
      delete process.env.CLAUDE_HOOKS_BLOCK_DANGEROUS;
    });

    test('should allow safe commands', () => {
      const result = SecurityValidator.validateDangerousCommands('Bash', { command: 'ls -la' });
      expect(result.allowed).toBe(true);
    });

    test('should allow non-bash tools', () => {
      const result = SecurityValidator.validateDangerousCommands('Read', { file_path: 'test.txt' });
      expect(result.allowed).toBe(true);
    });
  });
});