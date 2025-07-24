/**
 * Stop Hook
 * Comprehensive session completion handler with transcript processing,
 * linting execution, TTS announcements, and AI-powered completion messages
 */

import { existsSync, readFileSync, writeFileSync } from 'fs';
import { parseArgs } from 'util';
import type { StopHookInput, HookResult } from '../types.ts';
import { Logger, InputReader, createHookResult, handleError, executeShellCommand } from '../utils.ts';

export class StopHook {
  private static readonly COMPLETION_MESSAGES = [
    "Task completed successfully!",
    "Work finished - ready for your next challenge!",
    "Session complete - all objectives achieved!",
    "Mission accomplished!",
    "Ready for the next adventure!",
    "Task execution complete!"
  ];

  static async execute(): Promise<HookResult> {
    try {
      const { values: args } = parseArgs({
        args: process.argv.slice(2),
        options: {
          chat: { type: 'boolean', default: false }
        }
      });

      const input = await InputReader.readStdinJson<StopHookInput>();
      
      Logger.info('Processing stop hook', {
        session_id: input.session_id,
        stop_hook_active: input.stop_hook_active,
        has_transcript: !!input.transcript_path,
        copy_chat: args.chat
      });

      // Log session completion
      Logger.appendToLog('stop.json', input);

      // Handle transcript copying if requested
      if (args.chat && input.transcript_path) {
        await this.copyTranscriptToLogs(input.transcript_path);
      }

      // Run linting
      await this.runLinting();

      // Generate and announce completion
      const completionMessage = await this.generateCompletionMessage();
      await this.announceCompletion(completionMessage);

      Logger.info('Stop hook completed successfully', {
        session_id: input.session_id,
        completion_message: completionMessage
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
      writeFileSync(chatLogPath, transcriptContent);
      Logger.info('Transcript copied to logs', { 
        from: transcriptPath, 
        to: chatLogPath,
        size: transcriptContent.length 
      });
    } catch (error) {
      Logger.error('Failed to copy transcript', { 
        error: error instanceof Error ? error.message : 'Unknown error',
        path: transcriptPath 
      });
    }
  }

  private static async runLinting(): Promise<void> {
    try {
      Logger.info('Running linting checks');
      
      const result = await executeShellCommand('nix develop -c lint');
      
      console.log('=== Linting Results ===');
      if (result.stdout) {
        console.log(result.stdout);
      }
      if (result.stderr) {
        console.error(result.stderr);
      }
      console.log('======================');

      Logger.info('Linting completed', {
        exit_code: result.exitCode,
        has_stdout: !!result.stdout,
        has_stderr: !!result.stderr
      });
    } catch (error) {
      Logger.error('Linting failed', { 
        error: error instanceof Error ? error.message : 'Unknown error' 
      });
      console.error('Linting failed:', error);
    }
  }

  private static async generateCompletionMessage(): Promise<string> {
    try {
      // Try to generate AI completion message
      const aiMessage = await this.generateAICompletionMessage();
      if (aiMessage) {
        return aiMessage;
      }
    } catch (error) {
      Logger.warn('AI completion message generation failed', { 
        error: error instanceof Error ? error.message : 'Unknown error' 
      });
    }

    // Fallback to random message
    return this.COMPLETION_MESSAGES[Math.floor(Math.random() * this.COMPLETION_MESSAGES.length)];
  }

  private static async generateAICompletionMessage(): Promise<string | null> {
    // Priority: OpenAI > Anthropic > fallback
    const providers = [
      { name: 'openai', command: 'llm -m gpt-4o-mini' },
      { name: 'anthropic', command: 'llm -m claude-3-haiku-20240307' }
    ];

    const prompt = "Generate a brief, encouraging completion message (max 10 words) for a coding session that just finished.";

    for (const provider of providers) {
      try {
        Logger.debug(`Trying ${provider.name} for completion message`);
        
        const result = await executeShellCommand(`echo "${prompt}" | ${provider.command}`);
        
        if (result.exitCode === 0 && result.stdout.trim()) {
          const message = result.stdout.trim();
          Logger.info(`Generated completion message via ${provider.name}`, { message });
          return message;
        }
      } catch (error) {
        Logger.debug(`${provider.name} completion failed`, { 
          error: error instanceof Error ? error.message : 'Unknown error' 
        });
      }
    }

    return null;
  }

  private static async announceCompletion(message: string): Promise<void> {
    // Priority: ElevenLabs > OpenAI TTS > pyttsx3
    const ttsProviders = [
      { name: 'elevenlabs', command: 'tts_elevenlabs' },
      { name: 'openai', command: 'tts_openai' },
      { name: 'pyttsx3', command: 'tts_pyttsx3' }
    ];

    for (const provider of ttsProviders) {
      try {
        Logger.debug(`Trying ${provider.name} for TTS`);
        
        const result = await executeShellCommand(`echo "${message}" | ${provider.command}`);
        
        if (result.exitCode === 0) {
          Logger.info(`TTS announcement successful via ${provider.name}`, { message });
          return;
        }
      } catch (error) {
        Logger.debug(`${provider.name} TTS failed`, { 
          error: error instanceof Error ? error.message : 'Unknown error' 
        });
      }
    }

    Logger.warn('All TTS providers failed, completion message not announced', { message });
    console.log(`🎉 ${message}`);
  }
}

if (import.meta.main) {
  const result = await StopHook.execute();
  process.exit(result.exit_code);
}