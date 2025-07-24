/**
 * Subagent Stop Hook - Tiger Style Implementation
 * 
 * Handles subagent completion with bounded operations and simple control flow.
 * 
 * Tiger Style principles applied:
 * - Safety: Input validation, bounded operations, explicit error handling
 * - Performance: Efficient resource usage, fixed limits
 * - Developer Experience: Clear interface, predictable behavior
 */

import { existsSync, readFileSync, writeFileSync } from 'fs';
import type { SubagentStopHookInput, HookResult } from '../types.ts';
import { Logger, InputReader, createHookResult, handleError, executeShellCommand } from '../utils.ts';

// Tiger Style: Fixed limits for bounded operations
const MAX_TTS_PROVIDER_ATTEMPTS = 3;
const MAX_SUBAGENT_TRANSCRIPT_SIZE_BYTES = 5 * 1024 * 1024; // 5MB

/**
 * Subagent completion handler with Tiger Style design
 */
export class SubagentStopHook {
  private static readonly SUBAGENT_COMPLETION_MESSAGE = "Subagent Complete";
  private static readonly SUBAGENT_CHAT_LOG_FILENAME = 'logs/chat.json';

  /**
   * Main execution flow for subagent stop hook
   * Tiger Style: Simple control flow, input validation, clear steps
   */
  static async execute(): Promise<HookResult> {
    try {
      const shouldCopyChat = process.argv.includes('--chat');
      const hookInput = await InputReader.readStdinJson<SubagentStopHookInput>();
      
      // Tiger Style: Validate input immediately
      if (!hookInput.session_id || typeof hookInput.session_id !== 'string') {
        throw new Error('Subagent stop input must include valid session_id');
      }
      
      Logger.info('Processing subagent stop hook', {
        session_id: hookInput.session_id,
        subagent_id: hookInput.subagent_id,
        has_transcript: !!hookInput.transcript_path,
        copy_chat: shouldCopyChat
      });

      // Log subagent completion
      Logger.appendToLog('subagent_stop.json', hookInput);

      // Handle transcript copying if requested
      if (shouldCopyChat && hookInput.transcript_path) {
        await this.copyTranscriptToLogs(hookInput.transcript_path);
      }

      // Announce subagent completion
      await this.announceSubagentCompletion();

      Logger.info('Subagent stop hook completed successfully', {
        session_id: hookInput.session_id,
        subagent_id: hookInput.subagent_id
      });

      return createHookResult(true, 'Subagent completed successfully');
    } catch (error) {
      return handleError(error, 'subagent-stop hook');
    }
  }

  /**
   * Copies subagent transcript with size validation
   * Tiger Style: Input validation, bounded operations, explicit error handling
   */
  private static async copyTranscriptToLogs(transcriptPath: string): Promise<void> {
    // Tiger Style: Assert function arguments
    if (!transcriptPath || typeof transcriptPath !== 'string') {
      throw new Error('Subagent transcript path must be a non-empty string');
    }

    if (!existsSync(transcriptPath)) {
      Logger.warn('Subagent transcript file not found', { path: transcriptPath });
      return;
    }

    try {
      // Tiger Style: Check file size before reading to prevent memory exhaustion
      const fileStats = require('fs').statSync(transcriptPath);
      if (fileStats.size > MAX_SUBAGENT_TRANSCRIPT_SIZE_BYTES) {
        throw new Error(`Subagent transcript exceeds maximum size of ${MAX_SUBAGENT_TRANSCRIPT_SIZE_BYTES} bytes`);
      }
      
      const transcriptContent = readFileSync(transcriptPath, 'utf-8');
      
      Logger.ensureLogsDirectory();
      writeFileSync(this.SUBAGENT_CHAT_LOG_FILENAME, transcriptContent);
      
      Logger.info('Subagent transcript copied to logs', { 
        from: transcriptPath, 
        to: this.SUBAGENT_CHAT_LOG_FILENAME,
        size_bytes: transcriptContent.length 
      });
    } catch (error) {
      Logger.error('Failed to copy subagent transcript', { 
        error: error instanceof Error ? error.message : 'Unknown error',
        path: transcriptPath 
      });
      throw error;
    }
  }

  /**
   * Announces subagent completion with bounded TTS attempts
   * Tiger Style: Fixed limits, simple control flow, clear fallback
   */
  private static async announceSubagentCompletion(): Promise<void> {
    const ttsProviders = [
      { name: 'elevenlabs', command: 'tts_elevenlabs' },
      { name: 'openai', command: 'tts_openai' },
      { name: 'pyttsx3', command: 'tts_pyttsx3' }
    ];

    // Tiger Style: Fixed upper bound prevents unbounded attempts
    const providersToTry = ttsProviders.slice(0, MAX_TTS_PROVIDER_ATTEMPTS);

    for (const provider of providersToTry) {
      try {
        Logger.debug(`Attempting subagent TTS via ${provider.name}`);
        
        const ttsCommand = `echo "${this.SUBAGENT_COMPLETION_MESSAGE}" | ${provider.command}`;
        const ttsResult = await executeShellCommand(ttsCommand);
        
        if (ttsResult.exitCode === 0) {
          Logger.info(`Subagent TTS announcement successful via ${provider.name}`);
          return;
        }
      } catch (error) {
        Logger.debug(`${provider.name} TTS failed`, { 
          error: error instanceof Error ? error.message : 'Unknown error' 
        });
      }
    }

    // Tiger Style: Explicit fallback behavior
    Logger.warn('All TTS providers failed for subagent announcement', { 
      message: this.SUBAGENT_COMPLETION_MESSAGE 
    });
    console.log(`🤖 ${this.SUBAGENT_COMPLETION_MESSAGE}`);
  }
}

if (import.meta.main) {
  const result = await SubagentStopHook.execute();
  process.exit(result.exit_code);
}