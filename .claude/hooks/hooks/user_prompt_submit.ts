/**
 * User Prompt Submit Hook
 * Logs user prompt submission events for tracking and analysis
 */

import type { UserPromptSubmitHookInput, HookResult } from '../types.ts';
import { Logger, InputReader, createHookResult, handleError } from '../utils.ts';

export class UserPromptSubmitHook {
  static async execute(): Promise<HookResult> {
    try {
      const input = await InputReader.readStdinJson<UserPromptSubmitHookInput>();
      
      Logger.info('Processing user prompt submit hook', {
        session_id: input.session_id,
        has_prompt: !!input.prompt,
        prompt_length: input.prompt?.length || 0
      });

      Logger.appendToLog('user_prompt_submit.json', input);
      
      Logger.debug('User prompt submission logged', {
        session_id: input.session_id,
        timestamp: new Date().toISOString()
      });
      
      return createHookResult(true, 'User prompt submission logged successfully');
    } catch (error) {
      return handleError(error, 'user-prompt-submit hook');
    }
  }
}

if (import.meta.main) {
  const result = await UserPromptSubmitHook.execute();
  process.exit(result.exit_code);
}