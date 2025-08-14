import { test, expect, describe } from 'bun:test';
import { NotificationHook } from '../../../hooks/notification.ts';
import type { NotificationHookInput } from '../../../types.ts';

describe('NotificationHook', () => {
  test('should process valid notification input', async () => {
    const mockInput: NotificationHookInput = {
      tool_name: 'TestTool',
      tool_input: { test: 'data' },
      timestamp: new Date().toISOString(),
    };

    // Mock stdin
    const originalStdin = process.stdin;
    const mockStdin = {
      [Symbol.asyncIterator]: async function* () {
        yield Buffer.from(JSON.stringify(mockInput));
      },
    } as any;

    Object.defineProperty(process, 'stdin', {
      value: mockStdin,
      configurable: true,
    });

    try {
      const result = await NotificationHook.execute();

      expect(result.success).toBe(true);
      expect(result.message).toBe('Notification logged successfully');
      expect(result.exit_code).toBe(0);
    } finally {
      // Restore original stdin
      Object.defineProperty(process, 'stdin', {
        value: originalStdin,
        configurable: true,
      });
    }
  });

  test('should handle invalid JSON input', async () => {
    // Mock stdin with invalid JSON
    const mockStdin = {
      [Symbol.asyncIterator]: async function* () {
        yield Buffer.from('invalid json');
      },
    } as any;

    Object.defineProperty(process, 'stdin', {
      value: mockStdin,
      configurable: true,
    });

    const result = await NotificationHook.execute();

    expect(result.success).toBe(false);
    expect(result.message).toContain('Invalid JSON input');
    expect(result.exit_code).toBe(1);
  });

  test('should handle empty input', async () => {
    // Mock stdin with empty input
    const mockStdin = {
      [Symbol.asyncIterator]: async function* () {
        yield Buffer.from('');
      },
    } as any;

    Object.defineProperty(process, 'stdin', {
      value: mockStdin,
      configurable: true,
    });

    const result = await NotificationHook.execute();

    expect(result.success).toBe(false);
    expect(result.message).toContain('No input received');
    expect(result.exit_code).toBe(1);
  });
});
