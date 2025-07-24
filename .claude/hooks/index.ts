/**
 * Claude Code Hook System - TypeScript Implementation
 * Main entry point for hook routing and execution
 */

import { parseArgs } from 'util';
import type { HookType, HookResult } from './types.ts';
import { Logger } from './utils.ts';
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
    subagent_stop: SubagentStopHook
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
        exit_code: 1
      };
    }

    Logger.info(`Executing ${hookType} hook`);
    
    try {
      return await HookClass.execute();
    } catch (error) {
      const message = `Hook execution failed: ${error instanceof Error ? error.message : 'Unknown error'}`;
      Logger.error(message, { hookType, error });
      return {
        success: false,
        message,
        blocked: false,
        exit_code: 1
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
        list: { type: 'boolean', short: 'l', default: false }
      },
      allowPositionals: true
    });

    if (args.help) {
      console.log(`
Claude Code Hook System - TypeScript Implementation

Usage: bun index.ts <hook-type> [options]

Available hooks:
${HookRouter.getAvailableHooks().map(hook => `  - ${hook}`).join('\n')}

Options:
  -h, --help    Show this help message
  -l, --list    List available hooks
  --chat        Copy transcript to logs (for stop/subagent_stop hooks)

Examples:
  bun index.ts notification
  bun index.ts stop --chat
  bun index.ts pre_tool_use
      `);
      process.exit(0);
    }

    if (args.list) {
      console.log('Available hooks:');
      HookRouter.getAvailableHooks().forEach(hook => {
        console.log(`  - ${hook}`);
      });
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

    const result = await HookRouter.route(hookType);
    
    if (result.message && result.exit_code !== 0) {
      console.error(result.message);
    }
    
    process.exit(result.exit_code);
  } catch (error) {
    Logger.error('Main execution failed', { 
      error: error instanceof Error ? error.message : 'Unknown error' 
    });
    console.error('Fatal error:', error);
    process.exit(1);
  }
}

if (import.meta.main) {
  await main();
}