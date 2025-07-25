/**
 * TypeScript interfaces for Claude Code hook system
 * Provides type safety and clear contracts for all hook implementations
 */

export interface ToolInput {
  [key: string]: unknown;
}

export interface BaseHookInput {
  tool_name: string;
  tool_input: ToolInput;
  timestamp?: string;
}

export interface NotificationHookInput extends BaseHookInput {}

export interface ToolUseHookInput extends BaseHookInput {}

export interface UserPromptSubmitHookInput {
  prompt?: string;
  session_id?: string;
  timestamp?: string;
  [key: string]: unknown;
}

export interface StopHookInput {
  session_id: string;
  stop_hook_active: boolean;
  transcript_path?: string;
  timestamp?: string;
  [key: string]: unknown;
}

export interface SubagentStopHookInput {
  session_id: string;
  subagent_id?: string;
  transcript_path?: string;
  timestamp?: string;
  [key: string]: unknown;
}

export interface HookResult {
  success: boolean;
  message: string | undefined;
  blocked: boolean | undefined;
  exit_code: number;
}

export interface LogEntry {
  timestamp: string;
  data: unknown;
}

export interface SecurityValidationResult {
  allowed: boolean;
  reason?: string;
  patterns_matched?: string[];
}

export interface TTSConfig {
  provider: 'elevenlabs' | 'openai' | 'pyttsx3';
  voice?: string;
  speed?: number;
}

export interface LLMConfig {
  provider: 'openai' | 'anthropic';
  model?: string;
  max_tokens?: number;
}

export type HookType =
  | 'notification'
  | 'pre_tool_use'
  | 'post_tool_use'
  | 'user_prompt_submit'
  | 'stop'
  | 'subagent_stop';

export type LogLevel = 'info' | 'warn' | 'error' | 'debug';
