import { test, expect, describe } from 'bun:test';
import {
  validateCommandString,
  validateFilePath,
  escapeShellArg,
  createHookResult,
} from '../../utils.ts';

describe('Utility Functions', () => {
  describe('validateCommandString', () => {
    test('should validate safe commands', () => {
      const result = validateCommandString('ls -la');
      expect(result.valid).toBe(true);
    });

    test('should reject empty commands', () => {
      const result = validateCommandString('');
      expect(result.valid).toBe(false);
      expect(result.reason).toContain('non-empty string');
    });

    test('should reject overly long commands', () => {
      const longCommand = 'a'.repeat(1001);
      const result = validateCommandString(longCommand);
      expect(result.valid).toBe(false);
      expect(result.reason).toContain('too long');
    });

    test('should reject dangerous command patterns', () => {
      const dangerousCommands = [
        '; rm -rf /',
        '&& rm -rf /',
        '| rm -rf /',
        '`rm -rf /`',
        '$(rm -rf /)',
      ];

      dangerousCommands.forEach((cmd) => {
        const result = validateCommandString(cmd);
        expect(result.valid).toBe(false);
        expect(result.reason).toContain('dangerous command pattern');
      });
    });
  });

  describe('validateFilePath', () => {
    test('should validate safe file paths', () => {
      const result = validateFilePath('/home/user/file.txt');
      expect(result.valid).toBe(true);
    });

    test('should reject empty paths', () => {
      const result = validateFilePath('');
      expect(result.valid).toBe(false);
    });

    test('should reject path traversal attempts', () => {
      const result = validateFilePath('../../../etc/passwd');
      expect(result.valid).toBe(false);
      expect(result.reason).toContain('Path traversal detected');
    });

    test('should reject overly long paths', () => {
      const longPath = '/'.repeat(501);
      const result = validateFilePath(longPath);
      expect(result.valid).toBe(false);
      expect(result.reason).toContain('too long');
    });
  });

  describe('escapeShellArg', () => {
    test('should properly escape shell arguments', () => {
      expect(escapeShellArg('simple')).toBe("'simple'");
      expect(escapeShellArg('arg with spaces')).toBe("'arg with spaces'");
      expect(escapeShellArg("arg'with'quotes")).toBe("'arg'\\''with'\\''quotes'");
    });
  });

  describe('createHookResult', () => {
    test('should create successful hook result', () => {
      const result = createHookResult(true, 'Success');
      expect(result.success).toBe(true);
      expect(result.message).toBe('Success');
      expect(result.blocked).toBe(false);
      expect(result.exit_code).toBe(0);
    });

    test('should create failed hook result', () => {
      const result = createHookResult(false, 'Failed');
      expect(result.success).toBe(false);
      expect(result.message).toBe('Failed');
      expect(result.blocked).toBe(false);
      expect(result.exit_code).toBe(1);
    });

    test('should create blocked hook result', () => {
      const result = createHookResult(false, 'Blocked', true);
      expect(result.success).toBe(false);
      expect(result.blocked).toBe(true);
      expect(result.exit_code).toBe(2);
    });
  });
});
