/**
 * Pre-Tool Use Hook
 * Validates tool usage before execution with security checks
 * Blocks access to .env files and logs potentially dangerous commands
 */

import type { ToolUseHookInput, HookResult } from '../types.ts';
import { Logger, InputReader, SecurityValidator, createHookResult, handleError } from '../utils.ts';

export class PreToolUseHook {
  static async execute(): Promise<HookResult> {
    try {
      const input = await InputReader.readStdinJson<ToolUseHookInput>();

      Logger.info('Processing pre-tool-use hook', {
        tool_name: input.tool_name,
        has_tool_input: !!input.tool_input,
      });

      // Security validation for .env file access
      const envValidation = SecurityValidator.validateEnvFileAccess(
        input.tool_name,
        input.tool_input
      );
      if (!envValidation.allowed) {
        Logger.error('Security violation: .env file access blocked', {
          tool_name: input.tool_name,
          tool_input: input.tool_input,
          reason: envValidation.reason,
        });

        console.error(envValidation.reason);
        Logger.appendToLog('pre_tool_use.json', {
          ...input,
          blocked: true,
          reason: envValidation.reason,
        });

        return createHookResult(false, envValidation.reason, true);
      }

      // Security validation for dangerous commands
      const commandValidation = SecurityValidator.validateDangerousCommands(
        input.tool_name,
        input.tool_input
      );
      if (!commandValidation.allowed) {
        Logger.error('Security violation: dangerous command blocked', {
          tool_name: input.tool_name,
          tool_input: input.tool_input,
          reason: commandValidation.reason,
        });

        console.error(commandValidation.reason);
        Logger.appendToLog('pre_tool_use.json', {
          ...input,
          blocked: true,
          reason: commandValidation.reason,
        });

        return createHookResult(false, commandValidation.reason, true);
      }

      // Log approved tool usage
      Logger.appendToLog('pre_tool_use.json', {
        ...input,
        approved: true,
      });

      Logger.debug('Tool usage approved', {
        tool_name: input.tool_name,
      });

      return createHookResult(true, 'Tool usage validated successfully');
    } catch (error) {
      return handleError(error, 'pre-tool-use hook');
    }
  }
}

if (import.meta.main) {
  const result = await PreToolUseHook.execute();
  process.exit(result.exit_code);
}
