/**
 * Claude Code Hook System - TypeScript Implementation
 *
 * Main entry point for hook routing and execution with comprehensive
 * logging, security validation, and cross-platform support.
 *
 * Supports all Claude Code hook types with argument parsing and error handling.
 *
 * @example
 * ```bash
 * bun index.ts stop --chat
 * bun index.ts notification
 * bun index.ts pre_tool_use
 * ```
 */

import { parseArgs } from 'util';
import type { HookType, HookResult } from './types.ts';
import { Logger, PerformanceMonitor } from './utils.ts';
import { getConfig } from './config.ts';
import { NotificationHook } from './hooks/notification.ts';
import { PreToolUseHook } from './hooks/pre_tool_use.ts';
import { PostToolUseHook } from './hooks/post_tool_use.ts';
import { UserPromptSubmitHook } from './hooks/user_prompt_submit.ts';
import { StopHook } from './hooks/stop.ts';
import { SubagentStopHook } from './hooks/subagent_stop.ts';

export class HookRouter {
  private static readonly HOOK_MAP = {
    notification: NotificationHook,
    pre_tool_use: PreToolUseHook,
    post_tool_use: PostToolUseHook,
    user_prompt_submit: UserPromptSubmitHook,
    stop: StopHook,
    subagent_stop: SubagentStopHook,
  } as const;

  static async route(hookType: HookType): Promise<HookResult> {
    const HookClass = this.HOOK_MAP[hookType];

    if (!HookClass) {
      const message = `Unknown hook type: ${hookType}`;
      Logger.error(message);
      return {
        success: false,
        message,
        blocked: false,
        exit_code: 1,
      };
    }

    const startTime = PerformanceMonitor.startTiming(hookType);
    Logger.info(`Executing ${hookType} hook`);

    try {
      const result = await HookClass.execute();
      const metrics = PerformanceMonitor.endTiming(
        hookType,
        startTime,
        result.success,
        result.message
      );

      Logger.info(`Hook ${hookType} completed`, {
        success: result.success,
        blocked: result.blocked,
        duration_ms: metrics.duration,
        memory_mb: Math.round(metrics.memoryUsage.heapUsed / 1024 / 1024),
      });

      return result;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      const metrics = PerformanceMonitor.endTiming(hookType, startTime, false, errorMessage);
      const message = `Hook execution failed: ${errorMessage}`;

      Logger.error(message, {
        hookType,
        error: errorMessage,
        duration_ms: metrics.duration,
        memory_mb: Math.round(metrics.memoryUsage.heapUsed / 1024 / 1024),
      });

      return {
        success: false,
        message,
        blocked: false,
        exit_code: 1,
      };
    }
  }

  static getAvailableHooks(): HookType[] {
    return Object.keys(this.HOOK_MAP) as HookType[];
  }
}

async function main(): Promise<void> {
  try {
    const { values: args, positionals } = parseArgs({
      args: process.argv.slice(2),
      options: {
        help: { type: 'boolean', short: 'h', default: false },
        list: { type: 'boolean', short: 'l', default: false },
        stats: { type: 'boolean', default: false },
        config: { type: 'boolean', default: false },
        chat: { type: 'boolean', default: false },
      },
      allowPositionals: true,
      strict: false,
    });

    if (args.help) {
      const config = getConfig();
      console.log(`
Claude Code Hook System - TypeScript Implementation

Usage: bun index.ts <hook-type> [options]

Available hooks:
${HookRouter.getAvailableHooks()
  .map((hook) => `  ${hook.padEnd(18)} - Hook for ${hook.replace('_', ' ')} events`)
  .join('\n')}

Options:
  -h, --help    Show this help message
  -l, --list    List available hooks
  --stats       Show performance statistics
  --config      Show current configuration
  --chat        Copy transcript to logs (for stop/subagent_stop hooks)

Configuration:
  TTS Provider: ${config.tts.provider}
  LLM Provider: ${config.llm.provider}
  Log Level: ${config.logging.level}
  Performance Monitoring: ${config.execution.enablePerformanceMonitoring ? 'enabled' : 'disabled'}

Examples:
  bun index.ts notification    # Handle user input waiting notifications
  bun index.ts stop --chat     # Session completion with transcript copying
  bun index.ts pre_tool_use    # Pre-tool execution security validation
  bun index.ts subagent_stop   # Subagent completion processing
  bun index.ts --stats         # Show performance statistics
      `);
      process.exit(0);
    }

    if (args.list) {
      console.log('Available hooks:');
      HookRouter.getAvailableHooks().forEach((hook) => {
        console.log(`  - ${hook}`);
      });
      process.exit(0);
    }

    if (args.stats) {
      console.log('\n📊 Performance Statistics');
      console.log('========================');
      const overallStats = PerformanceMonitor.getAverageMetrics();
      console.log(JSON.stringify(overallStats, null, 2));

      console.log('\n📈 Per-Hook Statistics');
      console.log('======================');
      HookRouter.getAvailableHooks().forEach((hookType) => {
        const hookStats = PerformanceMonitor.getAverageMetrics(hookType);
        if (hookStats.totalExecutions) {
          console.log(`\n${hookType}:`);
          console.log(JSON.stringify(hookStats, null, 2));
        }
      });
      process.exit(0);
    }

    if (args.config) {
      const configManager = getConfig();
      console.log('\n⚙️  Current Configuration');
      console.log('=========================');
      console.log(JSON.stringify(configManager, null, 2));
      process.exit(0);
    }

    const hookType = positionals[0] as HookType;

    if (!hookType) {
      console.error('Error: Hook type is required. Use --help for usage information.');
      process.exit(1);
    }

    if (!HookRouter.getAvailableHooks().includes(hookType)) {
      console.error(`Error: Unknown hook type '${hookType}'. Use --list to see available hooks.`);
      process.exit(1);
    }

    Logger.info('Starting hook execution', { hookType, args });
    const result = await HookRouter.route(hookType);

    if (result.blocked) {
      console.error(`🚫 Hook blocked: ${result.message}`);
    } else if (!result.success && result.message) {
      console.error(`❌ Hook failed: ${result.message}`);
    } else if (result.success) {
      Logger.debug('Hook execution successful', { hookType });
    }

    process.exit(result.exit_code);
  } catch (error) {
    Logger.error('Main execution failed', {
      error: error instanceof Error ? error.message : 'Unknown error',
    });
    console.error('Fatal error:', error);
    process.exit(1);
  }
}

if (import.meta.main) {
  await main();
}
