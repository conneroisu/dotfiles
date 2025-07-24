/**
 * Stop Hook - Tiger Style Implementation
 * 
 * Handles session completion with bounded operations and simple control flow.
 * 
 * Tiger Style principles applied:
 * - Safety: Input validation, fixed limits, fail-fast behavior
 * - Performance: Bounded operations, efficient resource usage  
 * - Developer Experience: Clear naming, simple functions, explicit error handling
 */

import { existsSync, readFileSync, writeFileSync } from 'fs';
import type { StopHookInput, HookResult } from '../types.ts';
import { Logger, InputReader, createHookResult, handleError, executeShellCommand } from '../utils.ts';

// Tiger Style: Fixed limits prevent unbounded operations
const MAX_PROVIDER_ATTEMPTS = 3;
const MAX_COMPLETION_MESSAGE_LENGTH = 100;
const MAX_TRANSCRIPT_SIZE_BYTES = 10 * 1024 * 1024; // 10MB

/**
 * Session completion handler with Tiger Style design
 * Each method has single responsibility and clear boundaries
 */
export class StopHook {
  // Tiger Style: Explicit constants with descriptive names
  private static readonly DEFAULT_COMPLETION_MESSAGES = [
    "Task completed successfully!",
    "Work finished - ready for your next challenge!",
    "Session complete - all objectives achieved!",
    "Mission accomplished!",
    "Ready for the next adventure!",
    "Task execution complete!"
  ];

  private static readonly CHAT_LOG_FILENAME = 'logs/chat.json';
  private static readonly COMPLETION_PROMPT = "Generate a brief, encouraging completion message (max 10 words) for a coding session that just finished.";

  /**
   * Main execution flow for stop hook
   * Tiger Style: Simple control flow, centralized state management
   */
  static async execute(): Promise<HookResult> {
    try {
      const shouldCopyChat = this.shouldCopyTranscript();
      const hookInput = await InputReader.readStdinJson<StopHookInput>();
      
      // Tiger Style: Validate input immediately
      this.validateStopHookInput(hookInput);
      
      this.logSessionStart(hookInput, shouldCopyChat);
      Logger.appendToLog('stop.json', hookInput);

      // Tiger Style: Sequential operations with clear dependencies
      await this.handleTranscriptCopy(shouldCopyChat, hookInput.transcript_path);
      await this.executeLinting();
      
      const completionMessage = await this.generateCompletionMessage();
      await this.announceCompletion(completionMessage);

      this.logSessionComplete(hookInput, completionMessage);
      return createHookResult(true, 'Session completed successfully');
    } catch (error) {
      return handleError(error, 'stop hook');
    }
  }

  /**
   * Determines if transcript should be copied based on command line arguments
   * Tiger Style: Single responsibility, explicit logic
   */
  private static shouldCopyTranscript(): boolean {
    return process.argv.includes('--chat');
  }

  /**
   * Validates stop hook input with assertions
   * Tiger Style: Fail-fast validation, clear error messages
   */
  private static validateStopHookInput(input: StopHookInput): void {
    if (!input.session_id || typeof input.session_id !== 'string') {
      throw new Error('Stop hook input must include valid session_id');
    }
    if (typeof input.stop_hook_active !== 'boolean') {
      throw new Error('Stop hook input must include stop_hook_active boolean');
    }
  }

  /**
   * Logs session start information
   * Tiger Style: Single responsibility, structured data
   */
  private static logSessionStart(input: StopHookInput, shouldCopyChat: boolean): void {
    Logger.info('Processing stop hook', {
      session_id: input.session_id,
      stop_hook_active: input.stop_hook_active,
      has_transcript: !!input.transcript_path,
      copy_chat: shouldCopyChat
    });
  }

  /**
   * Logs session completion information
   * Tiger Style: Single responsibility, consistent logging
   */
  private static logSessionComplete(input: StopHookInput, completionMessage: string): void {
    Logger.info('Stop hook completed successfully', {
      session_id: input.session_id,
      completion_message: completionMessage
    });
  }

  /**
   * Handles transcript copying workflow
   * Tiger Style: Clear control flow, explicit conditions
   */
  private static async handleTranscriptCopy(shouldCopy: boolean, transcriptPath?: string): Promise<void> {
    if (!shouldCopy || !transcriptPath) {
      return;
    }
    
    await this.copyTranscriptToLogs(transcriptPath);
  }

  /**
   * Copies transcript to logs with size validation
   * Tiger Style: Input validation, bounded operations, explicit error handling
   */
  private static async copyTranscriptToLogs(transcriptPath: string): Promise<void> {
    // Tiger Style: Assert function arguments
    if (!transcriptPath || typeof transcriptPath !== 'string') {
      throw new Error('Transcript path must be a non-empty string');
    }

    if (!existsSync(transcriptPath)) {
      Logger.warn('Transcript file not found', { path: transcriptPath });
      return;
    }

    try {
      const transcriptContent = this.readTranscriptWithSizeLimit(transcriptPath);
      
      Logger.ensureLogsDirectory();
      writeFileSync(this.CHAT_LOG_FILENAME, transcriptContent);
      
      Logger.info('Transcript copied to logs', { 
        from: transcriptPath, 
        to: this.CHAT_LOG_FILENAME,
        size_bytes: transcriptContent.length 
      });
    } catch (error) {
      Logger.error('Failed to copy transcript', { 
        error: error instanceof Error ? error.message : 'Unknown error',
        path: transcriptPath 
      });
      throw error;
    }
  }

  /**
   * Reads transcript file with size bounds
   * Tiger Style: Fixed limits prevent unbounded memory usage
   */
  private static readTranscriptWithSizeLimit(filePath: string): string {
    const fileStats = require('fs').statSync(filePath);
    
    if (fileStats.size > MAX_TRANSCRIPT_SIZE_BYTES) {
      throw new Error(`Transcript file exceeds maximum size of ${MAX_TRANSCRIPT_SIZE_BYTES} bytes`);
    }
    
    return readFileSync(filePath, 'utf-8');
  }

  /**
   * Executes linting with structured output
   * Tiger Style: Single responsibility, clear error handling
   */
  private static async executeLinting(): Promise<void> {
    Logger.info('Running linting checks');
    
    try {
      const lintingResult = await executeShellCommand('nix develop -c lint');
      this.displayLintingResults(lintingResult);
      this.logLintingCompletion(lintingResult);
    } catch (error) {
      this.handleLintingError(error);
    }
  }

  /**
   * Displays linting results to console
   * Tiger Style: Single responsibility, consistent formatting
   */
  private static displayLintingResults(result: { stdout: string; stderr: string; exitCode: number }): void {
    console.log('=== Linting Results ===');
    
    if (result.stdout.trim()) {
      console.log(result.stdout);
    }
    if (result.stderr.trim()) {
      console.error(result.stderr);
    }
    
    console.log('======================');
  }

  /**
   * Logs linting completion status
   * Tiger Style: Structured logging, clear data
   */
  private static logLintingCompletion(result: { stdout: string; stderr: string; exitCode: number }): void {
    Logger.info('Linting completed', {
      exit_code: result.exitCode,
      has_stdout: !!result.stdout.trim(),
      has_stderr: !!result.stderr.trim()
    });
  }

  /**
   * Handles linting errors with consistent reporting
   * Tiger Style: Explicit error handling, clear messages
   */
  private static handleLintingError(error: unknown): void {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    
    Logger.error('Linting failed', { error: errorMessage });
    console.error('Linting failed:', errorMessage);
  }

  /**
   * Generates completion message with AI fallback
   * Tiger Style: Simple control flow, explicit fallback
   */
  private static async generateCompletionMessage(): Promise<string> {
    try {
      const aiGeneratedMessage = await this.tryGenerateAICompletionMessage();
      if (aiGeneratedMessage) {
        return this.validateCompletionMessage(aiGeneratedMessage);
      }
    } catch (error) {
      Logger.warn('AI completion message generation failed', { 
        error: error instanceof Error ? error.message : 'Unknown error' 
      });
    }

    return this.selectRandomCompletionMessage();
  }

  /**
   * Validates completion message length and content
   * Tiger Style: Input validation, clear bounds
   */
  private static validateCompletionMessage(message: string): string {
    if (!message || typeof message !== 'string') {
      throw new Error('Completion message must be a non-empty string');
    }
    
    const trimmedMessage = message.trim();
    
    if (trimmedMessage.length > MAX_COMPLETION_MESSAGE_LENGTH) {
      Logger.warn(`Completion message truncated from ${trimmedMessage.length} to ${MAX_COMPLETION_MESSAGE_LENGTH} characters`);
      return trimmedMessage.substring(0, MAX_COMPLETION_MESSAGE_LENGTH);
    }
    
    return trimmedMessage;
  }

  /**
   * Selects random message from predefined options
   * Tiger Style: Bounded randomness, predictable behavior
   */
  private static selectRandomCompletionMessage(): string {
    const messageIndex = Math.floor(Math.random() * this.DEFAULT_COMPLETION_MESSAGES.length);
    return this.DEFAULT_COMPLETION_MESSAGES[messageIndex];
  }

  /**
   * Attempts to generate AI completion message with bounded retries
   * Tiger Style: Fixed limits, simple iteration, explicit providers
   */
  private static async tryGenerateAICompletionMessage(): Promise<string | null> {
    const aiProviders = this.getAIProviderList();
    
    // Tiger Style: Fixed upper bound prevents unbounded attempts
    const providersToTry = aiProviders.slice(0, MAX_PROVIDER_ATTEMPTS);
    
    for (const provider of providersToTry) {
      const generatedMessage = await this.tryProviderForCompletion(provider);
      if (generatedMessage) {
        return generatedMessage;
      }
    }
    
    return null;
  }

  /**
   * Gets ordered list of AI providers with explicit priority
   * Tiger Style: Explicit configuration, clear priorities
   */
  private static getAIProviderList(): Array<{ name: string; command: string }> {
    return [
      { name: 'openai', command: 'llm -m gpt-4o-mini' },
      { name: 'anthropic', command: 'llm -m claude-3-haiku-20240307' }
    ];
  }

  /**
   * Tries single provider for completion message
   * Tiger Style: Single responsibility, explicit error handling
   */
  private static async tryProviderForCompletion(provider: { name: string; command: string }): Promise<string | null> {
    try {
      Logger.debug(`Attempting completion message via ${provider.name}`);
      
      const commandToExecute = `echo "${this.COMPLETION_PROMPT}" | ${provider.command}`;
      const commandResult = await executeShellCommand(commandToExecute);
      
      if (this.isValidProviderResult(commandResult)) {
        const completionMessage = commandResult.stdout.trim();
        Logger.info(`Generated completion message via ${provider.name}`, { message: completionMessage });
        return completionMessage;
      }
    } catch (error) {
      Logger.debug(`${provider.name} completion failed`, { 
        error: error instanceof Error ? error.message : 'Unknown error' 
      });
    }
    
    return null;
  }

  /**
   * Validates provider command result
   * Tiger Style: Explicit validation, clear criteria
   */
  private static isValidProviderResult(result: { exitCode: number; stdout: string }): boolean {
    return result.exitCode === 0 && !!result.stdout.trim();
  }

  /**
   * Announces completion using TTS with bounded provider attempts
   * Tiger Style: Fixed limits, simple control flow, clear fallback
   */
  private static async announceCompletion(message: string): Promise<void> {
    // Tiger Style: Assert function arguments
    if (!message || typeof message !== 'string') {
      throw new Error('Completion message must be a non-empty string');
    }

    const ttsProviderList = this.getTTSProviderList();
    const providersToTry = ttsProviderList.slice(0, MAX_PROVIDER_ATTEMPTS);
    
    const ttsSucceeded = await this.tryTTSProviders(providersToTry, message);
    
    if (!ttsSucceeded) {
      this.displayFallbackMessage(message);
    }
  }

  /**
   * Gets ordered list of TTS providers
   * Tiger Style: Explicit configuration, clear priorities
   */
  private static getTTSProviderList(): Array<{ name: string; command: string }> {
    return [
      { name: 'elevenlabs', command: 'tts_elevenlabs' },
      { name: 'openai', command: 'tts_openai' },
      { name: 'pyttsx3', command: 'tts_pyttsx3' }
    ];
  }

  /**
   * Tries TTS providers in order until one succeeds
   * Tiger Style: Bounded iteration, early return on success
   */
  private static async tryTTSProviders(providers: Array<{ name: string; command: string }>, message: string): Promise<boolean> {
    for (const provider of providers) {
      const ttsSucceeded = await this.tryTTSProvider(provider, message);
      if (ttsSucceeded) {
        return true;
      }
    }
    
    return false;
  }

  /**
   * Tries single TTS provider
   * Tiger Style: Single responsibility, explicit success criteria
   */
  private static async tryTTSProvider(provider: { name: string; command: string }, message: string): Promise<boolean> {
    try {
      Logger.debug(`Attempting TTS via ${provider.name}`);
      
      const ttsCommand = `echo "${message}" | ${provider.command}`;
      const ttsResult = await executeShellCommand(ttsCommand);
      
      if (ttsResult.exitCode === 0) {
        Logger.info(`TTS announcement successful via ${provider.name}`, { message });
        return true;
      }
    } catch (error) {
      Logger.debug(`${provider.name} TTS failed`, { 
        error: error instanceof Error ? error.message : 'Unknown error' 
      });
    }
    
    return false;
  }

  /**
   * Displays fallback message when TTS fails
   * Tiger Style: Explicit fallback behavior, consistent formatting
   */
  private static displayFallbackMessage(message: string): void {
    Logger.warn('All TTS providers failed, using console fallback', { message });
    console.log(`🎉 ${message}`);
  }
}

if (import.meta.main) {
  const result = await StopHook.execute();
  process.exit(result.exit_code);
}