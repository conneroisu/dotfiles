import { test, expect, describe } from 'bun:test';
import { SecurityValidator } from '../../utils.ts';

describe('SecurityValidator', () => {
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
  });

  describe('validateDangerousCommands', () => {
    test('should log but allow rm -rf commands (current behavior)', () => {
      const result = SecurityValidator.validateDangerousCommands('Bash', { command: 'rm -rf /tmp/test' });
      expect(result.allowed).toBe(true); // Currently only logging, not blocking
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