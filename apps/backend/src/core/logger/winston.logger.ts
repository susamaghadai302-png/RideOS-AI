import * as winston from 'winston';

export const winstonLogger = winston.createLogger({
  level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json(),
  ),
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.printf(({ timestamp, level, message, context }) => {
          return `[RideOS ${timestamp}] [${level}] ${context ? `[${context}] ` : ''}${message}`;
        }),
      ),
    }),
  ],
});
