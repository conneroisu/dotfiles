/**
 * Configuration management for Claude Code hooks
 * Provides environment-based configuration with sensible defaults
 */

export interface SecurityConfig {
  blockDangerousCommands: boolean;
  allowedCommands: string[];
  maxInputSize: number;
  enableEnvFileProtection: boolean;
  logSecurityViolations: boolean;
}

export interface ExecutionConfig {
  commandTimeout: number;
  maxOutputSize: number;
  enableShellMode: boolean;
}

export interface TTSConfig {
  provider: 'elevenlabs' | 'openai' | 'pyttsx3' | 'none';
  voice?: string;
  speed?: number;
  enabled: boolean;
}

export interface LLMConfig {
  provider: 'openai' | 'anthropic' | 'none';
  model?: string;
  maxTokens?: number;
  enabled: boolean;
}

export interface HookConfig {
  security: SecurityConfig;
  execution: ExecutionConfig;
  tts: TTSConfig;
  llm: LLMConfig;
  logLevel: 'debug' | 'info' | 'warn' | 'error';
  logsDirectory: string;
}

export class ConfigManager {
  private static instance: ConfigManager;
  private config: HookConfig;

  private constructor() {
    this.config = this.loadConfig();
  }

  static getInstance(): ConfigManager {
    if (!ConfigManager.instance) {
      ConfigManager.instance = new ConfigManager();
    }
    return ConfigManager.instance;
  }

  private loadConfig(): HookConfig {
    return {
      security: {
        blockDangerousCommands: process.env.CLAUDE_HOOKS_BLOCK_DANGEROUS !== 'false', // enabled by default
        allowedCommands: process.env.CLAUDE_HOOKS_ALLOWED_COMMANDS?.split(',') || [],
        maxInputSize: parseInt(process.env.CLAUDE_HOOKS_MAX_INPUT_SIZE || '1048576'), // 1MB default
        enableEnvFileProtection: process.env.CLAUDE_HOOKS_PROTECT_ENV !== 'false', // enabled by default
        logSecurityViolations: process.env.CLAUDE_HOOKS_LOG_SECURITY !== 'false' // enabled by default
      },
      execution: {
        commandTimeout: parseInt(process.env.CLAUDE_HOOKS_COMMAND_TIMEOUT || '30000'), // 30s default
        maxOutputSize: parseInt(process.env.CLAUDE_HOOKS_MAX_OUTPUT_SIZE || '1048576'), // 1MB default
        enableShellMode: process.env.CLAUDE_HOOKS_SHELL_MODE !== 'false' // enabled by default
      },
      tts: {
        provider: (process.env.CLAUDE_HOOKS_TTS_PROVIDER as TTSConfig['provider']) || 'elevenlabs',
        voice: process.env.CLAUDE_HOOKS_TTS_VOICE,
        speed: parseInt(process.env.CLAUDE_HOOKS_TTS_SPEED || '1'),
        enabled: process.env.CLAUDE_HOOKS_TTS_ENABLED !== 'false' // enabled by default
      },
      llm: {
        provider: (process.env.CLAUDE_HOOKS_LLM_PROVIDER as LLMConfig['provider']) || 'openai',
        model: process.env.CLAUDE_HOOKS_LLM_MODEL,
        maxTokens: parseInt(process.env.CLAUDE_HOOKS_LLM_MAX_TOKENS || '100'),
        enabled: process.env.CLAUDE_HOOKS_LLM_ENABLED !== 'false' // enabled by default
      },
      logLevel: (process.env.CLAUDE_HOOKS_LOG_LEVEL as HookConfig['logLevel']) || 'info',
      logsDirectory: process.env.CLAUDE_HOOKS_LOGS_DIR || 'logs'
    };
  }

  getConfig(): HookConfig {
    return this.config;
  }

  getSecurityConfig(): SecurityConfig {
    return this.config.security;
  }

  getExecutionConfig(): ExecutionConfig {
    return this.config.execution;
  }

  getTTSConfig(): TTSConfig {
    return this.config.tts;
  }

  getLLMConfig(): LLMConfig {
    return this.config.llm;
  }

  // Reload configuration (useful for testing)
  reload(): void {
    this.config = this.loadConfig();
  }
}