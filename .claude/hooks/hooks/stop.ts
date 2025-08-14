/**
 * Stop Hook
 * Comprehensive session completion handler with transcript processing,
 * linting execution, TTS announcements, and AI-powered completion messages
 */

import { parseArgs } from 'node:util';
import type { HookResult, StopHookInput } from '../types.ts';
import {
  createHookResult,
  handleError,
  executeShellCommand,
  InputReader,
  Logger,
} from '../utils.ts';

interface StopHookArgs {
  chat: boolean;
}

export class StopHook {

  static async execute(): Promise<HookResult> {
    try {
      const { values: args } = parseArgs({
        args: process.argv.slice(2),
        options: {
          chat: { type: 'boolean', default: false },
        },
        allowPositionals: true,
        strict: false,
      }) as { values: StopHookArgs };

      const input = await InputReader.readStdinJson<StopHookInput>();

      // Log parsed arguments and input for debugging
      Logger.info('Stop hook initiated', {
        chatMode: args.chat,
        sessionId: input.session_id,
        stopHookActive: input.stop_hook_active,
        transcriptPath: input.transcript_path,
        timestamp: input.timestamp,
      });

      // Run linting and tests in parallel
      const [lintingSuccess, testsSuccess] = await Promise.all([
        this.runLinting(),
        this.runTests(),
      ]);

      if (!lintingSuccess) {
        const errorMessage = 'Stop hook failed: Linting did not pass.';

        return createHookResult(false, errorMessage, true);
      }

      if (!testsSuccess) {
        const errorMessage = 'Stop hook failed: Tests did not pass.';

        return createHookResult(false, errorMessage, true);
      }

      // run nix fmt 
      const result = await executeShellCommand('nix fmt');
      if (result.exitCode !== 0) {
        const errorMessage = 'Stop hook failed: nix fmt did not pass.';
        return createHookResult(false, errorMessage, true);
      }

      const successMessage = `Session ${input.session_id} completed successfully${args.chat ? ' (chat mode)' : ''}`;
      Logger.info('Stop hook completed successfully', {
        sessionId: input.session_id,
        chatMode: args.chat,
        lintingPassed: true,
        testsPassed: true,
        formattingPassed: true,
      });

      return createHookResult(true, successMessage);
    } catch (error) {
      return handleError(error, 'stop hook');
    }
  }

  private static async runTests(): Promise<boolean> {
    try {
      const result = await executeShellCommand('bun test', { timeout: 120000 });

      return result.exitCode === 0;
    } catch (error) {
      const file = Bun.file('tests-error.txt');
      await file.write(error instanceof Error ? error.message : String(error));

      return false;
    }
  }

  private static async runLinting(): Promise<boolean> {
    try {
      // Use longer timeout for linting operations
      const result = await executeShellCommand(
        'nix develop -c lint',
        { timeout: 120000 }
      );

      return result.exitCode === 0;
    } catch (error) {
      const file = Bun.file('linting-error.txt');
      await file.write(error instanceof Error ? error.message : String(error));

      return false;
    }
  }
}

if (import.meta.main) {
  const result = await StopHook.execute();
  process.exit(result.exit_code);
}
