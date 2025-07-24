/**
 * Subagent Stop Hook
 * Handles subagent completion events with transcript processing and TTS announcements
 */

import { existsSync, readFileSync, writeFileSync } from 'fs';
import { parseArgs } from 'util';
import type { SubagentStopHookInput, HookResult } from '../types.ts';
import { Logger, InputReader, createHookResult, handleError, executeShellCommand } from '../utils.ts';

export class SubagentStopHook {
  private static readonly SUBAGENT_COMPLETION_MESSAGE = "Subagent Complete";

  static async execute(): Promise<HookResult> {
    try {
      const { values: args } = parseArgs({
        args: process.argv.slice(2),
        options: {
          chat: { type: 'boolean', default: false }
        }
      });

      const input = await InputReader.readStdinJson<SubagentStopHookInput>();
      
      Logger.info('Processing subagent stop hook', {
        session_id: input.session_id,
        subagent_id: input.subagent_id,
        has_transcript: !!input.transcript_path,
        copy_chat: args.chat
      });

      // Log subagent completion
      Logger.appendToLog('subagent_stop.json', input);

      // Handle transcript copying if requested
      if (args.chat && input.transcript_path) {
        await this.copyTranscriptToLogs(input.transcript_path);
      }

      // Announce subagent completion
      await this.announceSubagentCompletion();

      Logger.info('Subagent stop hook completed successfully', {
        session_id: input.session_id,
        subagent_id: input.subagent_id
      });

      return createHookResult(true, 'Subagent completed successfully');
    } catch (error) {
      return handleError(error, 'subagent-stop hook');
    }
  }

  private static async copyTranscriptToLogs(transcriptPath: string): Promise<void> {
    try {
      if (!existsSync(transcriptPath)) {
        Logger.warn('Subagent transcript file not found', { path: transcriptPath });
        return;
      }

      const transcriptContent = readFileSync(transcriptPath, 'utf-8');
      const chatLogPath = 'logs/chat.json';
      
      // Ensure logs directory exists
      Logger.ensureLogsDirectory();
      writeFileSync(chatLogPath, transcriptContent);
      Logger.info('Subagent transcript copied to logs', { 
        from: transcriptPath, 
        to: chatLogPath,
        size: transcriptContent.length 
      });
    } catch (error) {
      Logger.error('Failed to copy subagent transcript', { 
        error: error instanceof Error ? error.message : 'Unknown error',
        path: transcriptPath 
      });
    }
  }

  private static async announceSubagentCompletion(): Promise<void> {
    const message = this.SUBAGENT_COMPLETION_MESSAGE;
    
    // Priority: ElevenLabs > OpenAI TTS > pyttsx3
    const ttsProviders = [
      { name: 'elevenlabs', command: 'tts_elevenlabs' },
      { name: 'openai', command: 'tts_openai' },
      { name: 'pyttsx3', command: 'tts_pyttsx3' }
    ];

    for (const provider of ttsProviders) {
      try {
        Logger.debug(`Trying ${provider.name} for subagent TTS`);
        
        const result = await executeShellCommand(`echo "${message}" | ${provider.command}`);
        
        if (result.exitCode === 0) {
          Logger.info(`Subagent TTS announcement successful via ${provider.name}`, { message });
          return;
        }
      } catch (error) {
        Logger.debug(`${provider.name} subagent TTS failed`, { 
          error: error instanceof Error ? error.message : 'Unknown error' 
        });
      }
    }

    Logger.warn('All TTS providers failed for subagent announcement', { message });
    console.log(`🤖 ${message}`);
  }
}

if (import.meta.main) {
  const result = await SubagentStopHook.execute();
  process.exit(result.exit_code);
}