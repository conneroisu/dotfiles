/**
 * Stop Hook
 * Comprehensive session completion handler with transcript processing,
 * linting execution, TTS announcements, and AI-powered completion messages
 */

import { existsSync, readFileSync } from 'fs';
import { parseArgs } from 'util';
import type { StopHookInput, HookResult } from '../types.ts';
import {
  Logger,
  InputReader,
  createHookResult,
  handleError,
  executeShellCommand,
} from '../utils.ts';

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
      });

      const input = await InputReader.readStdinJson<StopHookInput>();

      Logger.info('Processing stop hook', {
        session_id: input.session_id,
        stop_hook_active: input.stop_hook_active,
        has_transcript: !!input.transcript_path,
        copy_chat: args.chat,
      });

      // Log session completion
      Logger.appendToLog('stop.json', input);

      // Handle transcript copying if requested
      if (args.chat && input.transcript_path) {
        await this.copyTranscriptToLogs(input.transcript_path);
      }

      // Run linting and tests in parallel
      const [lintingSuccess, testsSuccess] = await Promise.all([
        this.runLinting(),
        this.runTests(),
      ]);

      if (!lintingSuccess || !testsSuccess) {
        const errorMessage = 'Stop hook failed: Linting or tests did not pass.';
        Logger.error(errorMessage, {
          linting_success: lintingSuccess,
          tests_success: testsSuccess,
        });
        return createHookResult(false, errorMessage, true);
      }

      Logger.info('Stop hook completed successfully', {
        session_id: input.session_id,
      });

      return createHookResult(true, 'Session completed successfully');
    } catch (error) {
      return handleError(error, 'stop hook');
    }
  }

  private static async copyTranscriptToLogs(transcriptPath: string): Promise<void> {
    try {
      if (!existsSync(transcriptPath)) {
        Logger.warn('Transcript file not found', { path: transcriptPath });
        return;
      }

      const transcriptContent = readFileSync(transcriptPath, 'utf-8');
      const chatLogPath = 'logs/chat.json';

      // Ensure logs directory exists
      Logger.ensureLogsDirectory();

      // Append to existing logs instead of overwriting
      Logger.appendToLog('chat.json', {
        timestamp: new Date().toISOString(),
        session_id: 'unknown',
        transcript_content: transcriptContent,
        source_path: transcriptPath,
      });
      Logger.info('Transcript copied to logs', {
        from: transcriptPath,
        to: chatLogPath,
        size: transcriptContent.length,
      });
    } catch (error) {
      Logger.error('Failed to copy transcript', {
        error: error instanceof Error ? error.message : 'Unknown error',
        path: transcriptPath,
      });
    }
  }

  private static async runTests(): Promise<boolean> {
    try {
      Logger.info('Running tests');

      // Use longer timeout for tests operations
      const result = await executeShellCommand('nix develop -c test', { timeout: 120000 });

      Logger.info('=== Tests Results ===');
      if (result.stdout.trim()) {
        Logger.info('Tests stdout', { output: result.stdout });
      }
      if (result.stderr.trim()) {
        Logger.error('Tests stderr', { output: result.stderr });
      }
      Logger.info('======================');

      const testsSuccess = result.exitCode === 0;
      Logger.info('Tests completed', {
        success: testsSuccess,
        exit_code: result.exitCode,
        stdout_lines: result.stdout.split('\n').length,
        stderr_lines: result.stderr.split('\n').length,
      });

      if (!testsSuccess) {
        Logger.warn('Tests completed with issues', { exit_code: result.exitCode });
      }
      return testsSuccess;
    } catch (error) {
      Logger.error('Tests failed', {
        error: error instanceof Error ? error.message : 'Unknown error',
      });
      Logger.error('❌ Tests failed', {
        error: error instanceof Error ? error.message : String(error),
      });
      return false;
    }
  }

  private static async runLinting(): Promise<boolean> {
    try {
      Logger.info('Running linting checks');

      // Use longer timeout for linting operations
      const result = await executeShellCommand('nix develop -c lint', { timeout: 120000 });

      Logger.info('=== Linting Results ===');
      if (result.stdout.trim()) {
        Logger.info('Linting stdout', { output: result.stdout });
      }
      if (result.stderr.trim()) {
        Logger.error('Linting stderr', { output: result.stderr });
      }
      Logger.info('======================');

      const lintingSuccess = result.exitCode === 0;
      Logger.info('Linting completed', {
        success: lintingSuccess,
        exit_code: result.exitCode,
        stdout_lines: result.stdout.split('\n').length,
        stderr_lines: result.stderr.split('\n').length,
      });

      if (!lintingSuccess) {
        Logger.warn('Linting completed with issues', { exit_code: result.exitCode });
      }
      return lintingSuccess;
    } catch (error) {
      Logger.error('Linting failed', {
        error: error instanceof Error ? error.message : 'Unknown error',
      });
      Logger.error('❌ Linting failed', {
        error: error instanceof Error ? error.message : String(error),
      });
      return false;
    }
  }



}

if (import.meta.main) {
  const result = await StopHook.execute();
  process.exit(result.exit_code);
}
