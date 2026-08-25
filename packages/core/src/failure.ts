export abstract class Failure {
  constructor(
    public readonly message: string,
    public readonly code: string,
    public readonly details?: Record<string, any>,
  ) {}
}

export class ValidationFailure extends Failure {
  constructor(message: string, details?: Record<string, any>) {
    super(message, 'VALIDATION_ERROR', details);
  }
}

export class NetworkFailure extends Failure {
  constructor(message: string = 'Network connection failed') {
    super(message, 'NETWORK_ERROR');
  }
}

export class NotFoundFailure extends Failure {
  constructor(resource: string) {
    super(`${resource} not found`, 'NOT_FOUND_ERROR');
  }
}

export class UnauthorizedFailure extends Failure {
  constructor(message: string = 'Unauthorized access') {
    super(message, 'UNAUTHORIZED_ERROR');
  }
}

export class ServerFailure extends Failure {
  constructor(message: string = 'Internal server error', details?: Record<string, any>) {
    super(message, 'SERVER_ERROR', details);
  }
}
