import { test, expect, describe } from 'bun:test';
import { HookRouter } from '../../index.ts';
import type { HookType } from '../../types.ts';

describe('HookRouter Integration', () => {
  test('should return available hooks', () => {
    const hooks = HookRouter.getAvailableHooks();
    const expectedHooks: HookType[] = [
      'notification',
      'pre_tool_use',
      'post_tool_use',
      'user_prompt_submit',
      'stop',
      'subagent_stop'
    ];
    
    expect(hooks).toEqual(expect.arrayContaining(expectedHooks));
    expect(hooks.length).toBe(expectedHooks.length);
  });

  test('should handle unknown hook type', async () => {
    const result = await HookRouter.route('unknown_hook' as HookType);
    
    expect(result.success).toBe(false);
    expect(result.message).toContain('Unknown hook type');
    expect(result.exit_code).toBe(1);
  });

  test('should route to correct hook class', () => {
    // Test that the hook map contains expected entries
    const hooks = HookRouter.getAvailableHooks();
    
    expect(hooks).toContain('notification');
    expect(hooks).toContain('pre_tool_use');
    expect(hooks).toContain('post_tool_use');
    expect(hooks).toContain('user_prompt_submit');
    expect(hooks).toContain('stop');
    expect(hooks).toContain('subagent_stop');
  });
});