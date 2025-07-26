/**
 * Configuration Management for Claude Code Hook System
 *
 * Provides centralized configuration with environment variable support,
 * validation, and type-safe defaults.
 */

export interface SecurityConfig {
  blockDangerousCommands: boolean;
  allowedCommands: string[];
  maxInputSize: number;
  maxOutputSize: number;
  maxCommandLength: number;
  maxFilePathLength: number;
  enableEnvFileProtection: boolean;
  logSecurityViolations: boolean;
}

export interface TimeoutConfig {
  general: number; // General command timeout
  linting: number; // Extended timeout for linting operations
  aiCompletion: number; // Quick timeout for AI completion
  tts: number; // Immediate feedback timeout for TTS
}

export interface ExecutionConfig {
  timeouts: TimeoutConfig;
  enableShellMode: boolean;
  maxConcurrentHooks: number;
  enablePerformanceMonitoring: boolean;
}

export interface TTSConfig {
  provider: 'elevenlabs' | 'openai' | 'pyttsx3' | 'none';
  voice: string | undefined;
  speed: number | undefined;
  enabled: boolean;
  fallbackEnabled: boolean;
}

export interface LLMConfig {
  provider: 'openai' | 'anthropic' | 'none';
  openaiModel: string;
  anthropicModel: string;
  maxTokens: number;
  enabled: boolean;
}

export interface LoggingConfig {
  level: 'debug' | 'info' | 'warn' | 'error';
  directory: string;
  maxLogSize: number;
  maxEntriesPerLog: number;
  rotateLogs: boolean;
  structuredLogging: boolean;
}

export interface FeatureConfig {
  aiCompletion: boolean;
  ttsAnnouncements: boolean;
  transcriptCopying: boolean;
  lintingIntegration: boolean;
  securityValidation: boolean;
  performanceMonitoring: boolean;
}

export interface HookConfig {
  security: SecurityConfig;
  execution: ExecutionConfig;
  tts: TTSConfig;
  llm: LLMConfig;
  logging: LoggingConfig;
  features: FeatureConfig;
}

/**
 * Default configuration following Tiger Style principles:
 * - Safety: Conservative timeouts and security-first defaults
 * - Performance: Optimized timeouts for different operations
 * - Developer Experience: Reasonable defaults with flexibility
 */
const DEFAULT_CONFIG: HookConfig = {
  security: {
    blockDangerousCommands: true,
    allowedCommands: [],
    maxInputSize: 1048576, // 1MB - DoS protection
    maxOutputSize: 1048576, // 1MB - Memory protection
    maxCommandLength: 1000, // Reasonable command limit
    maxFilePathLength: 500, // Path traversal protection
    enableEnvFileProtection: true,
    logSecurityViolations: true,
  },

  execution: {
    timeouts: {
      general: 60000, // 60s - balanced for most operations
      linting: 120000, // 120s - extended for complex projects
      aiCompletion: 15000, // 15s - quick fallback to predefined messages
      tts: 10000, // 10s - immediate feedback requirement
    },
    enableShellMode: true,
    maxConcurrentHooks: 3,
    enablePerformanceMonitoring: true,
  },

  tts: {
    provider: 'elevenlabs',
    voice: undefined,
    speed: undefined,
    enabled: true,
    fallbackEnabled: true,
  },

  llm: {
    provider: 'openai',
    openaiModel: 'gpt-4o-mini',
    anthropicModel: 'claude-3-haiku-20240307',
    maxTokens: 100,
    enabled: true,
  },

  logging: {
    level: 'info',
    directory: 'logs',
    maxLogSize: 1048576, // 1MB per log file
    maxEntriesPerLog: 1000, // Reasonable history
    rotateLogs: true,
    structuredLogging: true,
  },

  features: {
    aiCompletion: true,
    ttsAnnouncements: true,
    transcriptCopying: true,
    lintingIntegration: true,
    securityValidation: true,
    performanceMonitoring: true,
  },
};

/**
 * Environment variable mappings for configuration override
 */
const ENV_MAPPINGS = {
  // Security configuration
  CLAUDE_HOOKS_BLOCK_DANGEROUS: 'security.blockDangerousCommands',
  CLAUDE_HOOKS_MAX_INPUT_SIZE: 'security.maxInputSize',
  CLAUDE_HOOKS_MAX_OUTPUT_SIZE: 'security.maxOutputSize',
  CLAUDE_HOOKS_MAX_COMMAND_LENGTH: 'security.maxCommandLength',
  CLAUDE_HOOKS_PROTECT_ENV: 'security.enableEnvFileProtection',

  // Timeout configuration
  CLAUDE_HOOKS_TIMEOUT_GENERAL: 'execution.timeouts.general',
  CLAUDE_HOOKS_TIMEOUT_LINTING: 'execution.timeouts.linting',
  CLAUDE_HOOKS_TIMEOUT_AI: 'execution.timeouts.aiCompletion',
  CLAUDE_HOOKS_TIMEOUT_TTS: 'execution.timeouts.tts',

  // Execution configuration
  CLAUDE_HOOKS_SHELL_MODE: 'execution.enableShellMode',
  CLAUDE_HOOKS_MAX_CONCURRENT: 'execution.maxConcurrentHooks',

  // TTS configuration
  CLAUDE_HOOKS_TTS_PROVIDER: 'tts.provider',
  CLAUDE_HOOKS_TTS_VOICE: 'tts.voice',
  CLAUDE_HOOKS_TTS_SPEED: 'tts.speed',
  CLAUDE_HOOKS_TTS_ENABLED: 'tts.enabled',

  // LLM configuration
  CLAUDE_HOOKS_LLM_PROVIDER: 'llm.provider',
  CLAUDE_HOOKS_OPENAI_MODEL: 'llm.openaiModel',
  CLAUDE_HOOKS_ANTHROPIC_MODEL: 'llm.anthropicModel',
  CLAUDE_HOOKS_LLM_MAX_TOKENS: 'llm.maxTokens',
  CLAUDE_HOOKS_LLM_ENABLED: 'llm.enabled',

  // Logging configuration
  CLAUDE_HOOKS_LOG_LEVEL: 'logging.level',
  CLAUDE_HOOKS_LOGS_DIR: 'logging.directory',
  CLAUDE_HOOKS_MAX_LOG_SIZE: 'logging.maxLogSize',

  // Feature toggles
  CLAUDE_HOOKS_AI_COMPLETION: 'features.aiCompletion',
  CLAUDE_HOOKS_TTS_ANNOUNCEMENTS: 'features.ttsAnnouncements',
  CLAUDE_HOOKS_TRANSCRIPT_COPY: 'features.transcriptCopying',
  CLAUDE_HOOKS_LINTING: 'features.lintingIntegration',
} as const;

export class ConfigManager {
  private static instance: ConfigManager;
  private config: HookConfig;

  private constructor() {
    this.config = this.loadConfig();
    this.validateConfig();
  }

  static getInstance(): ConfigManager {
    if (!ConfigManager.instance) {
      ConfigManager.instance = new ConfigManager();
    }
    return ConfigManager.instance;
  }

  /**
   * Load configuration from defaults with environment variable overrides
   */
  private loadConfig(): HookConfig {
    // Start with deep copy of defaults
    const config = JSON.parse(JSON.stringify(DEFAULT_CONFIG)) as HookConfig;

    // Apply environment variable overrides
    Object.entries(ENV_MAPPINGS).forEach(([envVar, configPath]) => {
      const envValue = process.env[envVar];
      if (envValue !== undefined) {
        const convertedValue = this.convertEnvValue(envValue, configPath);
        this.setNestedValue(config, configPath, convertedValue);
      }
    });

    return config;
  }

  /**
   * Convert environment variable string to appropriate type
   */
  private convertEnvValue(value: string, configPath: string): unknown {
    // Boolean conversion
    if (value.toLowerCase() === 'true') return true;
    if (value.toLowerCase() === 'false') return false;

    // Number conversion for timeouts, sizes, and limits
    if (
      configPath.includes('timeout') ||
      configPath.includes('Size') ||
      configPath.includes('Length') ||
      configPath.includes('maxTokens') ||
      configPath.includes('maxConcurrent') ||
      configPath.includes('speed')
    ) {
      const numValue = parseInt(value, 10);
      if (!isNaN(numValue)) return numValue;
    }

    // Array conversion for allowed commands
    if (configPath.includes('allowedCommands')) {
      return value
        .split(',')
        .map((cmd) => cmd.trim())
        .filter((cmd) => cmd);
    }

    // String values (providers, models, directories, log levels)
    return value;
  }

  /**
   * Set nested object value by dot notation path
   */
  private setNestedValue(obj: Record<string, unknown>, path: string, value: unknown): void {
    const keys = path.split('.');
    const lastKey = keys.pop();

    if (!lastKey) return;

    const target = keys.reduce((current, key) => {
      if (!(key in current) || typeof current[key] !== 'object') {
        current[key] = {};
      }
      return current[key] as Record<string, unknown>;
    }, obj);

    target[lastKey] = value;
  }

  /**
   * Validate configuration values
   */
  private validateConfig(): void {
    const errors: string[] = [];

    // Validate timeouts are positive
    Object.entries(this.config.execution.timeouts).forEach(([key, value]) => {
      if (typeof value !== 'number' || value <= 0) {
        errors.push(`Invalid timeout value for ${key}: ${value}`);
      }
    });

    // Validate security limits
    if (this.config.security.maxInputSize <= 0) {
      errors.push('maxInputSize must be positive');
    }

    // Validate log level
    const validLogLevels = ['debug', 'info', 'warn', 'error'];
    if (!validLogLevels.includes(this.config.logging.level)) {
      errors.push(`Invalid log level: ${this.config.logging.level}`);
    }

    // Validate TTS provider
    const validTtsProviders = ['elevenlabs', 'openai', 'pyttsx3', 'none'];
    if (!validTtsProviders.includes(this.config.tts.provider)) {
      errors.push(`Invalid TTS provider: ${this.config.tts.provider}`);
    }

    // Validate LLM provider
    const validLlmProviders = ['openai', 'anthropic', 'none'];
    if (!validLlmProviders.includes(this.config.llm.provider)) {
      errors.push(`Invalid LLM provider: ${this.config.llm.provider}`);
    }

    if (errors.length > 0) {
      throw new Error(`Configuration validation failed:\n${errors.join('\n')}`);
    }
  }

  // Public getters
  getConfig(): Readonly<HookConfig> {
    return Object.freeze({ ...this.config });
  }

  getSecurityConfig(): Readonly<SecurityConfig> {
    return Object.freeze({ ...this.config.security });
  }

  getExecutionConfig(): Readonly<ExecutionConfig> {
    return Object.freeze({ ...this.config.execution });
  }

  getTTSConfig(): Readonly<TTSConfig> {
    return Object.freeze({ ...this.config.tts });
  }

  getLLMConfig(): Readonly<LLMConfig> {
    return Object.freeze({ ...this.config.llm });
  }

  getLoggingConfig(): Readonly<LoggingConfig> {
    return Object.freeze({ ...this.config.logging });
  }

  getFeatureConfig(): Readonly<FeatureConfig> {
    return Object.freeze({ ...this.config.features });
  }

  /**
   * Get specific configuration value with type safety
   */
  get<T>(path: string): T {
    return this.getNestedValue(this.config, path) as T;
  }

  /**
   * Get nested object value by dot notation path
   */
  private getNestedValue(obj: unknown, path: string): unknown {
    return path.split('.').reduce((current, key) => {
      return current && typeof current === 'object' && key in current
        ? (current as Record<string, unknown>)[key]
        : undefined;
    }, obj);
  }

  /**
   * Reload configuration (useful for testing)
   */
  reload(): void {
    this.config = this.loadConfig();
    this.validateConfig();
  }

  /**
   * Get configuration summary for debugging
   */
  getSummary(): Record<string, unknown> {
    return {
      'Security Features': {
        'Dangerous Command Blocking': this.config.security.blockDangerousCommands,
        'Env File Protection': this.config.security.enableEnvFileProtection,
        'Max Input Size': `${this.config.security.maxInputSize / 1024 / 1024}MB`,
      },
      Timeouts: {
        General: `${this.config.execution.timeouts.general / 1000}s`,
        Linting: `${this.config.execution.timeouts.linting / 1000}s`,
        'AI Completion': `${this.config.execution.timeouts.aiCompletion / 1000}s`,
        TTS: `${this.config.execution.timeouts.tts / 1000}s`,
      },
      Providers: {
        TTS: this.config.tts.provider,
        LLM: this.config.llm.provider,
      },
      Features: this.config.features,
    };
  }
}

/**
 * Convenience functions for global configuration access
 */
export function getConfig(): Readonly<HookConfig> {
  return ConfigManager.getInstance().getConfig();
}

export function getConfigValue<T>(path: string): T {
  return ConfigManager.getInstance().get<T>(path);
}
