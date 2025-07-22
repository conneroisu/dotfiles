import { logger as sentryLogger } from "@sentry/tanstackstart-react";

// Browser-compatible logger interface
interface Logger {
  info: (message: string, meta?: unknown) => void;
  warn: (message: string, meta?: unknown) => void;
  error: (message: string, meta?: unknown) => void;
  debug: (message: string, meta?: unknown) => void;
}

// Create a logger that uses Sentry logger
const createSentryLogger = (): Logger => {
  return {
    info: (message: string, meta?: unknown) => sentryLogger.info(message, meta),
    warn: (message: string, meta?: unknown) => sentryLogger.warn(message, meta),
    error: (message: string, meta?: unknown) =>
      sentryLogger.error(message, meta),
    debug: (message: string, meta?: unknown) =>
      sentryLogger.debug(message, meta),
  };
};

// Create the logger using Sentry
const logger: Logger = createSentryLogger();

export default logger;
