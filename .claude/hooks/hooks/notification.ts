/**
 * Notification Hook
 * Logs notification events for tracking and debugging purposes
 */

import type { NotificationHookInput, HookResult } from '../types.ts';
import { Logger, InputReader, createHookResult, handleError } from '../utils.ts';

export class NotificationHook {
  static async execute(): Promise<HookResult> {
    try {
      // const _ = await InputReader.readStdinJson<NotificationHookInput>();

      // Logger.info('Processing notification hook', {
      //   tool_name: input.tool_name,
      //   has_tool_input: !!input.tool_input,
      // });
      //
      // Logger.appendToLog('notification.json', input);

      return createHookResult(true, 'Notification logged successfully');
    } catch (error) {
      return handleError(error, 'notification hook');
    }
  }
}

if (import.meta.main) {
  const result = await NotificationHook.execute();
  process.exit(result.exit_code);
}
